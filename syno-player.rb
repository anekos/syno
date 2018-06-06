#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'find'
require 'pathname'
require 'pp'
require 'shellwords'

load './lib/syno.rb'



Syno.new do
  |syno|
  # pp syno.audio_station.playlist
  # pp syno.audio_station.info

  status = syno.audio_station.status

  song = status.dig('data', 'song')
  additional = song.dig('additional', 'song_tag')

  pp additional.dig('album')
  pp additional.dig('album_artist')
  pp song.dig('title')
end
