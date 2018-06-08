#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'find'
require 'pathname'
require 'pp'
require 'shellwords'

load './lib/syno.rb'


command_line = ARGV.dup


Syno.new do
  |syno|

  previous = nil

  loop do
    status = syno.audio_station.status

    song = status.dig('data', 'song')

    current =
      if song and additional = song.dig('additional', 'song_tag')
        {
          :album =>  additional.dig('album'),
          :artist => additional.dig('artist') || additional.dig('album_artist'),
          :title => song.dig('title'),
        }
      else
        {
          :album => '-', :artist => '-', :title => '-'
        }
      end

    unless current == previous
      cmd = command_line.map do
        |it|
        it.gsub(/%(:?artist|album|title)%/) {|it| current[it[1...-1].to_sym] } .shellescape
      end.join(' ')

      system(cmd)
      previous = current
    end

    sleep 1.5
  end
end
