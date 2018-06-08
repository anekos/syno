
# Synology DSM

# Usage

## audio-station

```
audio-station.rb <COMMAND>
```

Commands

- pause
- stop
- play [<INDEX>]
- next
- prev
- repeat [all|one|two],
- shuffle [true|false],
- status
- pins
- playlists
- playlist [<OFFSET>]
- update_playlist <PLAYLIST_NAME>
- update_playlist_with_directory <DIRECTORY_ID>


## status-watcher (for Audio Station)

```
status-watcher.rb <UPDATE_COMMAND> '%artist% - %title% - %album%'
```

# Config

Place `.env` file in the same directory as this project.
Or set environment variables.

```
SYNO_USERNAME=XXXXXX
SYNO_PASSWORD=YYYYYYYYYYY
SYNO_HOST=192.168.1.123
SYNO_PORT=5000
```
