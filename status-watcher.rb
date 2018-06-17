#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'find'
require 'pathname'
require 'pp'
require 'shellwords'

load './lib/syno.rb'


command_line = ARGV.dup


class Integer
  def to_time
    '%d:%.2d' % [self / 60, self % 60]
  end
end



Syno.new do
  |syno|

  previous = nil

  loop do
    data = syno.audio_station.status['data']

    song = data.dig('song')

    current = {
      :state => data.dig('state'),
      :total => data.dig('playlist_total'),
      :index => data.dig('index'),
      :current => data.dig('index').to_i + 1,
      :position => data.dig('position').to_time,
    }

    if song and additional = song.dig('additional')
      current.merge!({
        :album =>  additional.dig('album'),
        :artist => additional.dig('artist') || additional.dig('song_tag', 'album_artist'),
        :title => song.dig('title'),
        :duration => additional.dig('song_audio', 'duration').to_time,
      })
    end

    unless current == previous
      cmd = command_line.map do
        |it|
        it.gsub(/%(:?artist|album|title|current|index|total|position|duration)%/) {|it| current[it[1...-1].to_sym] } .shellescape
      end.join(' ')

      system(cmd)
      previous = current
    end

    sleep 1.5
  end
end
