using System;
using MediaBrowser.Model.Plugins;

namespace Jellyfin.Plugin.M3UExporter.Configuration;

/// <summary>
/// Plugin configuration for M3U Exporter.
/// </summary>
public class PluginConfiguration : BasePluginConfiguration
{
    /// <summary>
    /// Initializes a new instance of the <see cref="PluginConfiguration"/> class.
    /// </summary>
    public PluginConfiguration()
    {
        SelectedUserIds = Array.Empty<string>();
        ExportDirectory = string.Empty;
    }

    /// <summary>
    /// Gets or sets the selected user IDs to export playlists for.
    /// </summary>
    public string[] SelectedUserIds { get; set; }

    /// <summary>
    /// Gets or sets the export directory path (relative to music library).
    /// </summary>
    public string ExportDirectory { get; set; }
}
