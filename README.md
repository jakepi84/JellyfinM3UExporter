# JellyfinM3UExporter

A Jellyfin plugin that exports user music playlists to M3U files.

## Features

- Export music playlists from selected users as M3U files
- Configure export directory within the Jellyfin music library
- Scheduled task for automated exports
- M3U files use relative paths for portability
- Safety limits: Maximum 1000 playlists and 40,000 tracks per playlist
- Creates a ".ignore" file in the export folder so Jellyfin will not pick these lists up and duplicate

## Configuration

1. Install the plugin in Jellyfin
2. Go to the plugin configuration page in the Jellyfin dashboard
3. Select which users' playlists you want to export
4. Specify the export directory within your music library (e.g., "Playlists")
5. Configure the scheduled task execution time in Jellyfin's Scheduled Tasks

## Requirements

- Jellyfin 10.11.5 or later
- .NET 9.0

## Building

```bash
dotnet build Jellyfin.Plugin.M3UExporter.sln
```

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
