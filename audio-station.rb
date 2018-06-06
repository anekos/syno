#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

load './lib/syno.rb'

command = ARGV.shift.to_sym

selected = {
  :pause => 0,
  :stop => 0,
  :play => 0..1,
  :next => 0,
  :prev => 0,
  :repeat => %w[all one two],
  :shuffle => %w[true false],
}[command]


valid =
  case selected
  when Range
    selected.include?(ARGV.size)
  when Integer
    ARGV.size == selected
  when Array
    selected.include?(ARGV.first)
  else
    true
  end

unless valid
  STDERR.puts('Invalid arguments')
  exit 1
end

Syno.new do
  |syno|
  syno.audio_station.__send__(command, *ARGV)
end
