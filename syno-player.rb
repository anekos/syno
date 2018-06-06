#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'find'
require 'pathname'
require 'pp'
require 'shellwords'

load './lib/syno.rb'



Syno.new do
  |syno|
  p syno.audio_station.play
end
