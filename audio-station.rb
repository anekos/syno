#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

# Libs {{{
require 'yaml'
require 'readline'
load './lib/syno.rb'
# }}}

# Commmand class {{{
class Command
  attr_reader :help

  @@aliases = {}
  @@commands = []

  def self.matched(name)
    @@aliases[name]
  end

  def self.help
    puts('Commands:')
    @@commands.each do |command|
      puts('  ' + command.help.to_s)
    end
  end

  def initialize (name, meta, help: nil, &block)
    register(name)
    @name = name
    @meta = meta
    @main = block
    @help = help || (Array === name ? name.join('|') : name)
  end

  def check_result(result)
    raise 'API Failed' unless result['success']
    result['data']
  end

  def register(name)
    if Array === name
      name.each {|it| @@aliases[it] = self }
      name = name.first
    else
      @@aliases[name] = self
    end
    @@commands << self
  end

  private def validate(args)
    case @meta
    when Range
      @meta.include?(args.size)
    when Integer
      args.size == @meta
    when Array
      @meta.include?(args.first)
    else
      true
    end or raise 'Invalid arguments'
  end
end

class AliasCommand < Command
  def run(syno, args)
    validate(args)

    result = syno.audio_station.__send__(@name, *args)
    data = check_result(result)
    if @main
      @main.call(data)
    else
      puts(data.to_yaml) if data and !data.empty?
    end
  end
end

class StandardCommand < AliasCommand
  def run(syno, args)
    @main.call(self, syno, *args)
  end
end
# }}}

# Commands {{{
Blank = '▫'

AliasCommand.new(:next, 0)
AliasCommand.new(:pause, 0)
AliasCommand.new(:pins, 0)
AliasCommand.new(:prev , 0)
AliasCommand.new(:repeat , %w[all one none], help: 'repeat [all|one|none]')
AliasCommand.new(:shuffle , %w[true false], help: 'shuffle [true|false]')
AliasCommand.new(:status , 0)
AliasCommand.new(:stop , 0)
AliasCommand.new(:toggle , 0)
AliasCommand.new(:update_playlist , 1)

AliasCommand.new([:playlist, :pl], 0..1) do
  |data|
  songs = data['songs']
  current = data['current']
  digits = Math.log(songs.size, 10).to_i + 1
  songs.each_with_index do |song, i|
    a = song['additional']
    mark = i == current ? '→' : ''
    parts = ["%#{digits}s %2.d %s" % [mark, i + 1, song['title']]]
    if a and tag = a['song_tag']
      parts << tag['artist'] || tag('album_artist') || Blank
      parts << tag['album'] || Blank
    end
    if a and rating = a.dig('song_rating', 'rating')
      parts << ' ★' * rating.to_i
    end
    puts(parts.join(' ／ '))
  end
  # puts(data.to_yaml)
end

AliasCommand.new([:playlists, :pls], 0) do
  |data|
  data['playlists'].each do
    |playlist|
      next if playlist['id'] === 'playlist_personal_normal/__SYNO_AUDIO_SHARED_SONGS__'
    puts playlist['name']
  end
end

StandardCommand.new(:play, 0..1, help: 'play [<TRACK_NUMBER>]') do
  |this, syno, index|
  index = index.to_i - 1 if index
  this.check_result(syno.audio_station.play(index))
end

StandardCommand.new(:help, 0) do
  |this, syno, args|
  Command.help
end
# }}}

# App {{{
class App
  def initialize(syno)
    @syno = syno
  end

  def request(args)
    command_name = args.shift.to_sym

    if command = Command.matched(command_name)
      command.run(@syno, args)
    else
      STDERR.puts("Invalid command\n\n")
      Command.help
      exit 1
    end
  end
end
# }}}

# Main {{{
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
# }}}
