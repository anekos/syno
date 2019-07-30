#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

# Libs {{{
require 'yaml'
require 'readline'
require 'optparse'
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
    if Array === name
      @name = name.first
      @help = help || name.join('|')
    else
      @name = name
      @help = help || name
    end
    @meta = meta
    @main = block
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
  def run(syno, args, options = nil)
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
  def run(syno, args, options = nil)
    @main.call(self, syno, args, options)
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
AliasCommand.new([:update_playlist, :set] , 1, help: '(playlist_set|set) <playlist_name>')
AliasCommand.new([:clear_playlist, :clear] , 0)

AliasCommand.new([:playlist, :pl], 0..1) do
  |data|
  songs = data['songs']
  current = data['current']
  next if songs.size == 0
  digits = Math.log(songs.size, 10).to_i + 1
  songs.each_with_index do |song, i|
    a = song['additional']
    mark = i == current ? '→' : ''
    parts = ["%#{digits}s %2.d %s" % [mark, i + 1, song['title']]]
    if a
      if tag = a['song_tag']
        parts << tag['artist'] || tag('album_artist') || Blank
        parts << tag['album'] || Blank
      end
      if rating = a.dig('song_rating', 'rating') and 0 < rating
        parts << ' ★' * rating.to_i
      else
        parts << '-'
      end
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

AliasCommand.new([:search, :find], 1) do
  |data|
  puts('Albums:')

  data['albums'].each_with_index do
    |album, i|
    puts('  %d - %s ／ %s' % [i + 1, album['album_artist'], album['name']])
  end

  puts('Artists:')

  data['artists'].each_with_index do
    |artist, i|
    puts('  %d - %s' % [i + 1, artist['name']])
  end

  puts('Songs:')

  data['songs'].each_with_index do
    |song, i|
    tag = song.dig('additional', 'song_tag')
    args = [
      i + 1,
      song['title'],
      tag['artist'],
      tag['album'],
      song['id'].sub(/\D+_/, '').to_i
    ]
    puts('  %d - %s ／ %s ／ %s (%d)' % args)
  end
end

AliasCommand.new([:playlist_add, :add], 1..2, help: 'playlist_add|add <ID_OR_ARTIST> [<ALBUM>]')

StandardCommand.new([:call], 0..10000) do
  |this, syno, args|
  name = args.shift
  puts syno.audio_station.__send__(name, args).to_json
end

StandardCommand.new([:playlist_add_from_search_result, :sr], 1..10000) do
  |this, syno, lines|
  lines.map do
    |line|
    line = line.dup
    next unless line.sub!(/\A\s+\d+ - /, '')

    a, b, c = line.split(/ *／ */)
    if c
      if m = c.match(%r[\((\d+)\)])
        syno.audio_station.playlist_add(m[1])
      end
    elsif b
      syno.audio_station.playlist_add(a, b)
    elsif a
      syno.audio_station.playlist_add(a)
    end
  end
end

AliasCommand.new([:playlist_add_album, :album, :al], 1)
AliasCommand.new([:playlist_add_artist, :artist, :ar], 1)
AliasCommand.new([:playlist_add_song, :song, :so], 1)

StandardCommand.new(:play, 0..1, help: 'play [<TRACK_NUMBER>]') do
  |this, syno, (index)|
  index = index.to_i - 1 if index
  this.check_result(syno.audio_station.play(index))
end

StandardCommand.new(:help, 0) do
  |this, syno, _args|
  Command.help
end

StandardCommand.new([:toggle], 0) do
  |this, syno, _args|
  current = syno.audio_station.status

  case current.dig('data', 'state')
  when 'playing'
    syno.audio_station.pause
  when 'pause', 'none'
    syno.audio_station.play
  end
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

# Options {{{
class Options < Struct.new(:format)
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

    OptionParser.new do |opt|
      opt.banner = "Usage: #{$0} [options]"
      opt.on('-f', '--format', 'Format') {|v| @format = v }
      opt.parse!(ARGV)
    end

    app.request(ARGV.dup)
  end
end
# }}}
