# Build Release Script
# This script builds the plugin and creates a release ZIP file

param(
    [string]$Version,
    [string]$ReleaseTag
)

# If not provided, extract from Directory.Build.props
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "Extracting version from Directory.Build.props..."
    [xml]$props = Get-Content "Directory.Build.props"
    $Version = $props.Project.PropertyGroup.Version
    Write-Host "Found version: $Version"
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    # Convert 1.0.1.0 to v1.0.1
    $parts = $Version.Split('.')
    $ReleaseTag = "v$($parts[0]).$($parts[1]).$($parts[2])"
    Write-Host "Using release tag: $ReleaseTag"
}

# Clean previous builds
if (Test-Path "artifacts") {
    Remove-Item -Recurse -Force "artifacts"
}
New-Item -ItemType Directory -Path "artifacts/jellyfin-m3u-exporter" | Out-Null

Write-Host "`n--- Building Release ---"
Write-Host "Version: $Version"
Write-Host "Tag: $ReleaseTag"

# Restore dependencies
Write-Host "`nRestoring dependencies..."
dotnet restore

# Build the project
Write-Host "Building project..."
dotnet build --configuration Release --no-restore -p:TreatWarningsAsErrors=false
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# Copy the DLL
Write-Host "Packaging plugin..."
Copy-Item "Jellyfin.Plugin.M3UExporter/bin/Release/net9.0/Jellyfin.Plugin.M3UExporter.dll" "artifacts/jellyfin-m3u-exporter/"

# Create ZIP file
$ZipName = "jellyfin-m3u-exporter_$Version.zip"
$ZipPath = Join-Path (Get-Location) "artifacts" $ZipName

Write-Host "Creating ZIP: $ZipName"
Compress-Archive -Path "artifacts/jellyfin-m3u-exporter" -DestinationPath $ZipPath -Force

if (Test-Path $ZipPath) {
    $size = (Get-Item $ZipPath).Length / 1KB
    Write-Host "✓ ZIP created successfully: $ZipName ($([Math]::Round($size, 2)) KB)"
    Write-Host "`nBuild successful!"
    Write-Host "Location: $ZipPath"
    Write-Host "`nNext step: Run update-manifest.ps1 to update manifest.json"
} else {
    Write-Error "Failed to create ZIP file!"
    exit 1
}
