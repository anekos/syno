


class AudioStation
  def control(action:, value: nil)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'control',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :action => action,
      :value => value,
    )
  end

  def info
    API.new(name: 'AudioStation', cgi: 'info', api: 'SYNO.AudioStation.Info', version: 2, method: 'getInfo').get()
  end

  def next
    control(action: 'next')
  end

  def pause
    control(action: 'pause')
  end

  def pins
    API.new(
      cgi: 'entry',
      api: 'SYNO.AudioStation.Pin',
      version: 1,
      method: 'list',
      token: true,
    ).post(
      :offset => 0,
      :limit => -1,
    )
  end

  def play(value = nil)
    control(action: 'play', value: value)
  end

  def playlist(offset = nil)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'getplaylist',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :offset => offset,
      :limit => 8192,
      :additional => 'song_tag,song_audio,song_rating',
    )
  end

  def playlist_add(id_or_artist, album = nil)
    containers = []
    params = {
      :id => '__SYNO_USB_PLAYER__',
      :containers_json => containers,
      :offset => -1,
      :limit => 0,
      :keep_shuffle_order => false,
      :library => 'all',
      :play => false,
    }

    if /\A\d+\z/ === id_or_artist
      params[:songs] = "music_#{id_or_artist}"
    else
      container = {
        :type => 'artist',
        :sort_by => 'name',
        :sort_direction => 'ASC',
        :artist => id_or_artist,
      }
      if album
        container[:album] = album
      end

      containers << container
    end

    params[:containers_json] = params[:containers_json].to_json

    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true,
    ).post(params)
  end

  def playlist_add_song(value)
    value = "music_#{value}" if Integer === value or /\A\d+\z/ === value

    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :containers_json => [].to_json,
      :offset => -1,
      :limit => 0,
      :keep_shuffle_order => false,
      :library => 'all',
      :play => false,
      :songs => value # music_....
    )
  end

  def playlist_add_album(album)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :containers_json => [
        {
          :type => 'artist',
          :sort_by => 'name',
          :sort_direction => 'ASC',
          :album => album,
        }
      ].to_json,
      :offset => -1,
      :limit => 0,
      :keep_shuffle_order => false,
      :library => 'all',
      :play => false,
    )
  end

  def playlist_add_artist(value)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :containers_json => [
        {
          :type => 'artist',
          :sort_by => 'name',
          :sort_direction => 'ASC',
          :artist => value,
        }
      ].to_json,
      :offset => -1,
      :limit => 0,
      :keep_shuffle_order => false,
      :library => 'all',
      :play => false,
    )
  end

  def playlists
    API.new(
      name: 'AudioStation',
      cgi: 'playlist',
      api: 'SYNO.AudioStation.Playlist',
      version: 3,
      method: 'list',
      token: true
    ).post(
      :library => 'all',
      :limit => 100000,
    )
  end

  def prev
    control(action: 'prev')
  end

  def repeat(value) # all / one / none
    control(action: 'set_repeat', value: value)
  end

  def search(value)
    API.new(
      name: 'AudioStation',
      cgi: 'search',
      api: 'SYNO.AudioStation.Search',
      version: 1,
      method: 'list',
      token: true,
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :additional => 'song_tag,song_audio,song_rating',
      :limit => 20,
      :library => 'all',
      :keyword => value,
      :sort_by => 'title',
      :sort_direction => 'ASC',
    )
  end

  def shuffle(value) # true / false
    control(action: 'set_shuffle', value: value)
  end

  def status
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player_status',
      api: 'SYNO.AudioStation.RemotePlayerStatus',
      version: 1,
      method: 'getstatus',
      token: true,
    ).get(
      :id => '__SYNO_USB_PLAYER__',
      :additional => 'song_tag,song_audio,subplayer_volume,song_rating',
    )
  end

  def stop
    control(action: 'stop')
  end

  def clear_playlist(limit = nil)
    limit = self.playlist.dig('data', 'songs').size unless limit
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :offset => 0,
      :songs => '',
      :limit => limit,
      :updated_index => -1,
    )
  end

  def update_playlist(name)
    self.clear_playlist()
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true
    ).post(
      :id => '__SYNO_USB_PLAYER__',
      :keep_shuffle_order => false,
      :containers_json => [{:type => 'playlist', :id => 'playlist_personal_normal/' + name}].to_json,
      :library => 'shared',
      :offset => 0,
      :play => true,
      :limit => 8192,
    )
  end

  def update_playlist_with_directory(id)
    API.new(
      name: 'AudioStation',
      cgi: 'remote_player',
      api: 'SYNO.AudioStation.RemotePlayer',
      version: 3,
      method: 'updateplaylist',
      token: true
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
end
