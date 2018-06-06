


class AudioStation
  def initialize (session)
    @session = session
  end

  def playlist
    API.new(name: 'AudioStation', cgi: 'playlist', api: 'SYNO.AudioStation.Playlist', version: 3, method: 'list').get()
  end

  def info
    API.new(name: 'AudioStation', cgi: 'info', api: 'SYNO.AudioStation.Info', version: 2, method: 'getInfo').get()
  end

  def status
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player_status',
      api: 'SYNO.AudioStation.RemotePlayerStatus',
      version: 1,
      method: 'getstatus'
    ).get(
      :id => '__SYNO_USB_PLAYER__',
      :additional => 'song_tag,song_audio,subplayer_volume',
      :SynoToken => @session.token
    )
  end

  def pause
    control(action: 'pause')
  end

  def stop
    control(action: 'stop')
  end

  def play(value = nil)
    control(action: 'play', value: value)
  end

  def next
    control(action: 'next')
  end

  def prev
    control(action: 'prev')
  end

  def repeat(value) # all / one / none
    control(action: 'set_repeat', value: value)
  end

  def shuffle(value) # true / false
    control(action: 'set_shuffle', value: value)
  end

  def control(action:, value: nil)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'control',
      token: @session.token
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :action => action,
      :value => value,
    )
  end
end
