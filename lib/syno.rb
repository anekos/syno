require 'yaml'

load './lib/config.rb'
load './lib/path.rb'
load './lib/api.rb'
load './lib/audio_station.rb'



class Syno
  attr_reader :audio_station

  def initialize(&block)
    API.login
    @audio_station = AudioStation.new

    begin
      block.call(self)
    ensure
      # logout
    end
  end
end
