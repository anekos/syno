#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

load './lib/syno.rb'



Syno.new do
  |syno|
  p syno.audio_station.play
end
