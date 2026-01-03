# JellyfinM3UExporter

A Jellyfin plugin that exports user music playlists to M3U files.

## Features

- Export music playlists from selected users as M3U files
- Configure export directory within the Jellyfin music library
- Scheduled task for automated exports
- M3U files use relative paths for portability
- Safety limits: Maximum 1000 playlists and 40,000 tracks per playlist
- Creates a ".ignore" file in the export folder so Jellyfin will not pick these lists up and duplicate

## Why did you make this?

I did not, mostly used Copilot to write this so the code is going to be 99% AI, take this project with a big grain of salt. I wanted to fix one specific problem. I maintain Playlists in Jellyfin as my source of truth for my music library. I also use the amazing [Bettermix](https://github.com/StergiosBinopoulos/jellyfin-plugin-bettermix) Plugin to generate daily playlists for me. The missing piece was being able to play these playlists from my Sonos App, since Sonos has no integration with Jellyfin.

This allows me to schedule an export of my playlists after the Bettermix plugin runs, then I have my Sonos scheduled to scan my music library after all of this. Now I can have a "Daily Mix" in Sonos completly local and selfhosted from my library on my NAS.

## Installation

### From Plugin Repository (Recommended)

Add this repository as a plugin source in Jellyfin:

1. Open Jellyfin and navigate to **Dashboard** → **Plugins** → **Repositories**
2. Click the **+** button to add a new repository
3. Enter the following details:
   - **Repository Name**: `JellyfinM3UExporter` (or any name you prefer)
   - **Repository URL**: `https://github.com/jakepi84/JellyfinM3UExporter/raw/main/manifest.json`
4. Click **Save**
5. Go to **Dashboard** → **Plugins** → **Catalog**
6. Find **M3U Exporter** in the list and click **Install**
7. Restart Jellyfin when prompted

### Manual Installation

1. Download the latest `.zip` file from the [Releases](../../releases) page
2. Extract the contents to your Jellyfin plugins directory:
   - Linux: `/var/lib/jellyfin/plugins/M3U Exporter/`
   - Windows: `%ProgramData%\Jellyfin\Server\plugins\M3U Exporter\`
3. Restart Jellyfin

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

1. **Important**: Ensure you are on the `main` branch and have the latest changes:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Create and push a new tag with a version number (e.g., `v1.0.0`):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. The GitHub Actions workflow will automatically:
   - Build the plugin
   - Create/update a `manifest.json` file compatible with Jellyfin plugin repositories
   - Package the plugin as a zip file
   - Commit the updated `manifest.json` back to the main branch
   - Create a GitHub release with the artifacts, checksums, and manifest

4. The release artifacts and repository can then be used to:
   - Install the plugin manually in Jellyfin by extracting the zip to the plugins directory
   - Add this repository as a plugin source in Jellyfin using the repository URL: `https://github.com/jakepi84/JellyfinM3UExporter/raw/main/manifest.json`
   - The `manifest.json` in this repository tracks all released versions of the plugin

### Troubleshooting Release Builds

If a tag is pushed but the release workflow doesn't trigger:

1. **Check if the tag points to the correct commit**: The workflow file must exist at the commit the tag points to. You can verify this with:
   ```bash
   git show <tag-name>:.github/workflows/publish.yaml
   ```
   If this command fails, the tag is pointing to a commit without the workflow.

2. **Option A: Move the tag to the correct commit**: If the tag is on an old commit:
   ```bash
   # Delete the old tag locally and remotely
   git tag -d v1.0.0
   git push origin :refs/tags/v1.0.0
   
   # Checkout the branch with the workflow (usually main)
   git checkout main
   git pull origin main
   
   # Create a new tag on the current commit
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Option B: Manually trigger the workflow**: If you don't want to move the tag:
   - Go to the [Actions tab](../../actions/workflows/publish.yaml)
   - Click "Run workflow"
   - Enter the tag name (e.g., `v1.0.0`)
   - Click "Run workflow"
   
   This will build and release from the specified tag even if the workflow file didn't exist when the tag was originally created.

4. **Verify the workflow runs**: Check the [Actions tab](../../actions) in GitHub to see if the workflow was triggered.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
