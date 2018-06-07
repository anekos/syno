


class AudioStation
  def initialize (session)
    @session = session
  end

  def update_playlist(name)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: @session.token
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :keep_shuffle_order => false,
      :containers_json => [{:type => 'playlist', :id => 'playlist_personal_normal/' + name}].to_json,
      :library => 'shared',
      :offset => 0,
      :play => true,
      :limit => 165,
    )
  end

  def update_playlist_with_directory(id)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: @session.token
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :keep_shuffle_order => false,
      :containers_json => [{:type => 'folder', :id => 'dir_' + id, :recursive => true, :sort_by => 'disc', :sort_direction => 'ASC'}].to_json,
      :library => 'shared',
      :play => true,
      :limit => 10000, :offset => 0, # Replace
      # :limit => 0, :offset => -1, # Add
    )
  end

  def playlists
    API.new(
      name: 'AudioStation',
      cgi: 'playlist',
      api: 'SYNO.AudioStation.Playlist',
      version: 3,
      method: 'list',
      token: @session.token
    ).post(
      :library => 'all',
      :limit => 100000,
    )
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
      :additional => 'song_tag,song_audio,subplayer_volume,song_rating',
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

  def playlist(offset = nil)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'getplaylist',
      token: @session.token
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :offset => offset,
      :limit => 8192,
      :additional => 'song_tag,song_audio,song_rating',
    )
  end

  def pins
    API.new(
      cgi: 'entry',
      api: 'SYNO.AudioStation.Pin',
      version: 1,
      method: 'list',
      token: @session.token
    ).post(
      :offset => 0,
      :limit => -1,
    )
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
