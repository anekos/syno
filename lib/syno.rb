load './lib/config.rb'
load './lib/api.rb'
load './lib/audio_station.rb'


class Session < Struct.new(:token)
end

class Syno
  attr_reader :audio_station

  def initialize(&block)
    result = API.new(
      cgi: 'auth',
      api: 'SYNO.API.Auth',
      method: 'login'
    ).get(
      :account => Config.account,
      :passwd => Config.password,
      :session => 'AudioStation',
      :format => 'cookie',
      :enable_syno_token => 'yes',
    )

    session = Session.new(result.dig('data', 'synotoken'))

    @audio_station = AudioStation.new(session)

    begin
      block.call(self)
    ensure
      logout
    end
  end

  def logout
    API.new(
      cgi: 'auth',
      api: 'SYNO.API.Auth',
      method: 'logout'
    ).get(
      :account => Config.account,
      :session => 'AudioStation'
    )
  end
end
