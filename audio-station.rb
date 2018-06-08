#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'yaml'
require 'readline'

load './lib/syno.rb'

CommandArgs = {
  :pause => 0,
  :stop => 0,
  :play => 0..1,
  :next => 0,
  :prev => 0,
  :repeat => %w[all one two],
  :shuffle => %w[true false],
  :status => 0,
  :pins => 0,
  :playlists => 0,
  :playlist => 0..1,
  :update_playlist => 1,
  :update_playlist_with_directory => 1,
}


class App
  def initialize(syno)
    @syno = syno
  end

  def request(args)
    command = args.shift.to_sym

    selected = CommandArgs[command]

    valid =
      case selected
      when Range
        selected.include?(args.size)
      when Integer
        args.size == selected
      when Array
        selected.include?(args.first)
      else
        true
      end

    raise 'Invalid arguments' unless valid

    result = @syno.audio_station.__send__(command, *args)

    if result['success']
      data = result['data']
      puts(data.to_yaml) if data and !data.empty?
      # puts(JSON.pretty_generate(result['data']))
    else
      raise 'API Failed'
    end
  end
end




Syno.new do
  |syno|
  app = App.new(syno)
  if ARGV.empty?
    while line = Readline.readline('> ', true)
      line.chomp!
      args = line.split(/\s+/)
      begin
        app.request(args) unless args.empty?
      rescue => e
        STDERR.puts(e)
      end
    end
  else
    app.request(ARGV.dup)
  end
end
