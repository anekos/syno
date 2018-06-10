#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

require 'yaml'
require 'readline'

load './lib/syno.rb'


Blank = '▫'


class Command
  @@table = {}

  def self.matched(name)
    @@table[name]
  end

  def initialize (name, meta, &block)
    if Array === name
      name.each {|it| @@table[it] = self }
      name = name.first
    else
      @@table[name] = self
    end
    @name = name
    @meta = meta
    @after = block
  end

  def run(syno, args)
    validate(args)

    result = syno.audio_station.__send__(@name, *args)

    if result['success']
      data = result['data']
      if @after
        @after.call(data)
      else
        puts(data.to_yaml) if data and !data.empty?
      end
    else
      raise 'API Failed'
    end
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



Command.new(:next, 0)
Command.new(:pause, 0)
Command.new(:pins, 0)
Command.new(:play, 0..1)
Command.new([:playlist, :pl], 0..1) do
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
Command.new([:playlists, :pls], 0) do
  |data|
  data['playlists'].each do
    |playlist|
      next if playlist['id'] === 'playlist_personal_normal/__SYNO_AUDIO_SHARED_SONGS__'
    puts playlist['name']
  end
end
Command.new(:prev , 0)
Command.new(:repeat , %w[all one two])
Command.new(:shuffle , %w[true false])
Command.new(:status , 0)
Command.new(:stop , 0)
Command.new(:toggle , 0)
Command.new(:update_playlist , 1)



class App
  def initialize(syno)
    @syno = syno
  end

  def request(args)
    command_name = args.shift.to_sym

    if command = Command.matched(command_name)
      command.run(@syno, args)
    else
      raise 'Invalid command'
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
