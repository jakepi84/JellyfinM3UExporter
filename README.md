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

## Releasing

To create a new release of the plugin:

1. Create and push a new tag with a version number (e.g., `v1.0.0`):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The GitHub Actions workflow will automatically:
   - Build the plugin
   - Create a manifest.json file compatible with Jellyfin
   - Package the plugin as a zip file
   - Create a GitHub release with the artifacts and checksums

3. The release artifacts can then be used to:
   - Install the plugin manually in Jellyfin by extracting the zip to the plugins directory
   - Add to a Jellyfin plugin repository by using the generated manifest.json

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
