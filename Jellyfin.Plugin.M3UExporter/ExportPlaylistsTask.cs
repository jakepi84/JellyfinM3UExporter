using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Jellyfin.Data.Entities;
using MediaBrowser.Controller.Entities;
using MediaBrowser.Controller.Library;
using MediaBrowser.Controller.Playlists;
using MediaBrowser.Model.Tasks;
using Microsoft.Extensions.Logging;

namespace Jellyfin.Plugin.M3UExporter;

/// <summary>
/// Scheduled task to export playlists to M3U files.
/// </summary>
public class ExportPlaylistsTask : IScheduledTask
{
    private const int MaxPlaylists = 1000;
    private const int MaxTracksPerPlaylist = 40000;

    private readonly ILibraryManager _libraryManager;
    private readonly IUserManager _userManager;
    private readonly ILogger<ExportPlaylistsTask> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="ExportPlaylistsTask"/> class.
    /// </summary>
    /// <param name="libraryManager">Instance of the <see cref="ILibraryManager"/> interface.</param>
    /// <param name="userManager">Instance of the <see cref="IUserManager"/> interface.</param>
    /// <param name="logger">Instance of the <see cref="ILogger{ExportPlaylistsTask}"/> interface.</param>
    public ExportPlaylistsTask(
        ILibraryManager libraryManager,
        IUserManager userManager,
        ILogger<ExportPlaylistsTask> logger)
    {
        _libraryManager = libraryManager;
        _userManager = userManager;
        _logger = logger;
    }

    /// <inheritdoc />
    public string Name => "Export Music Playlists to M3U";

    /// <inheritdoc />
    public string Key => "M3UExporterTask";

    /// <inheritdoc />
    public string Description => "Exports user music playlists to M3U files";

    /// <inheritdoc />
    public string Category => "Library";

    /// <inheritdoc />
    public async Task ExecuteAsync(IProgress<double> progress, CancellationToken cancellationToken)
    {
        var config = Plugin.Instance?.Configuration;
        if (config == null)
        {
            _logger.LogError("Plugin configuration not available");
            return;
        }

        if (config.SelectedUserIds == null || config.SelectedUserIds.Length == 0)
        {
            _logger.LogInformation("No users selected for playlist export");
            return;
        }

        if (string.IsNullOrWhiteSpace(config.ExportDirectory))
        {
            _logger.LogError("Export directory not configured");
            return;
        }

        _logger.LogInformation("Starting M3U export for {Count} user(s)", config.SelectedUserIds.Length);

        var processedCount = 0;
        var totalUsers = config.SelectedUserIds.Length;

        foreach (var userId in config.SelectedUserIds)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                break;
            }

            try
            {
                var user = _userManager.GetUserById(Guid.Parse(userId));
                if (user == null)
                {
                    _logger.LogWarning("User with ID {UserId} not found", userId);
                    continue;
                }

                _logger.LogInformation("Processing playlists for user: {UserName}", user.Username);
                await ExportUserPlaylistsAsync(user, config.ExportDirectory, cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting playlists for user {UserId}", userId);
            }

            processedCount++;
            progress.Report((double)processedCount / totalUsers * 100);
        }

        _logger.LogInformation("M3U export completed");
    }

    /// <inheritdoc />
    public IEnumerable<TaskTriggerInfo> GetDefaultTriggers()
    {
        // Run weekly on Sunday at 2 AM by default
        return new[]
        {
            new TaskTriggerInfo
            {
                Type = TaskTriggerInfo.TriggerWeekly,
                DayOfWeek = DayOfWeek.Sunday,
                TimeOfDayTicks = TimeSpan.FromHours(2).Ticks
            }
        };
    }

    private async Task ExportUserPlaylistsAsync(User user, string exportDirectory, CancellationToken cancellationToken)
    {
        // Get all playlists for the user
        var playlists = _libraryManager.GetItemList(new MediaBrowser.Controller.Entities.InternalItemsQuery(user)
        {
            IncludeItemTypes = new[] { Jellyfin.Data.Enums.BaseItemKind.Playlist },
            Recursive = true
        }).OfType<Playlist>().ToList();

        if (playlists.Count == 0)
        {
            _logger.LogInformation("No playlists found for user {UserName}", user.Username);
            return;
        }

        if (playlists.Count > MaxPlaylists)
        {
            _logger.LogWarning("User {UserName} has {Count} playlists, but only {MaxPlaylists} will be exported", user.Username, playlists.Count, MaxPlaylists);
            playlists = playlists.Take(MaxPlaylists).ToList();
        }

        _logger.LogInformation("Found {Count} playlist(s) for user {UserName}", playlists.Count, user.Username);

        // Find the music library root
        var musicLibraries = _libraryManager.GetVirtualFolders()
            .Where(vf => vf.CollectionType != null && string.Equals(vf.CollectionType.ToString(), "music", StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (musicLibraries.Count == 0)
        {
            _logger.LogError("No music library found");
            return;
        }

        // Use the first music library
        var musicLibraryPath = musicLibraries[0].Locations.FirstOrDefault();
        if (string.IsNullOrEmpty(musicLibraryPath))
        {
            _logger.LogError("Music library path is empty");
            return;
        }

        // Create export directory
        var exportPath = Path.Combine(musicLibraryPath, exportDirectory);
        Directory.CreateDirectory(exportPath);

        _logger.LogInformation("Exporting playlists to: {ExportPath}", exportPath);

        // Export each playlist
        foreach (var playlist in playlists)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                break;
            }

            try
            {
                await ExportPlaylistAsync(playlist, user, exportPath, musicLibraryPath, cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error exporting playlist {PlaylistName}", playlist.Name);
            }
        }
    }

    private async Task ExportPlaylistAsync(Playlist playlist, User user, string exportPath, string musicLibraryPath, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Exporting playlist: {PlaylistName}", playlist.Name);

        // Get playlist items
        var items = playlist.GetChildren(user, true).Where(i => i is MediaBrowser.Controller.Entities.Audio.Audio).ToList();

        if (items.Count == 0)
        {
            _logger.LogInformation("Playlist {PlaylistName} has no audio items", playlist.Name);
            return;
        }

        if (items.Count > MaxTracksPerPlaylist)
        {
            _logger.LogWarning("Playlist {PlaylistName} has {Count} tracks, but only {MaxTracks} will be exported", playlist.Name, items.Count, MaxTracksPerPlaylist);
            items = items.Take(MaxTracksPerPlaylist).ToList();
        }

        // Create M3U file
        var sanitizedPlaylistName = SanitizeFileName(playlist.Name);
        var m3uFilePath = Path.Combine(exportPath, $"{sanitizedPlaylistName}.m3u");

        var sb = new StringBuilder();
        sb.AppendLine("#EXTM3U");

        foreach (var item in items)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                break;
            }

            var itemPath = item.Path;
            if (string.IsNullOrEmpty(itemPath))
            {
                _logger.LogWarning("Item {ItemName} has no path", item.Name);
                continue;
            }

            // Convert to relative path from the export directory
            var relativePath = GetRelativePath(exportPath, itemPath);

            // Add extended info if available
            if (item is MediaBrowser.Controller.Entities.Audio.Audio audioItem)
            {
                var artist = audioItem.Artists?.FirstOrDefault() ?? "Unknown Artist";
                var duration = audioItem.RunTimeTicks.HasValue ? (int)(audioItem.RunTimeTicks.Value / TimeSpan.TicksPerSecond) : -1;
                sb.AppendLine(System.Globalization.CultureInfo.InvariantCulture, $"#EXTINF:{duration},{artist} - {audioItem.Name}");
            }
            else
            {
                sb.AppendLine(System.Globalization.CultureInfo.InvariantCulture, $"#EXTINF:-1,{item.Name}");
            }

            sb.AppendLine(relativePath);
        }

        // Write the M3U file
        await File.WriteAllTextAsync(m3uFilePath, sb.ToString(), Encoding.UTF8, cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Exported playlist {PlaylistName} with {Count} track(s) to {FilePath}", playlist.Name, items.Count, m3uFilePath);
    }

    private static string SanitizeFileName(string fileName)
    {
        var invalidChars = Path.GetInvalidFileNameChars();
        var sanitized = string.Join("_", fileName.Split(invalidChars, StringSplitOptions.RemoveEmptyEntries)).TrimEnd('.');
        return string.IsNullOrWhiteSpace(sanitized) ? "Untitled" : sanitized;
    }

    private static string GetRelativePath(string fromPath, string toPath)
    {
        // Normalize paths
        fromPath = Path.GetFullPath(fromPath);
        toPath = Path.GetFullPath(toPath);

        var fromUri = new Uri(fromPath.EndsWith(Path.DirectorySeparatorChar.ToString(), StringComparison.Ordinal) ? fromPath : fromPath + Path.DirectorySeparatorChar);
        var toUri = new Uri(toPath);

        var relativeUri = fromUri.MakeRelativeUri(toUri);
        var relativePath = Uri.UnescapeDataString(relativeUri.ToString());

        // Convert forward slashes to platform-specific directory separator
        return relativePath.Replace('/', Path.DirectorySeparatorChar);
    }
}
