param(
    [string]$Version,
    [string]$ReleaseTag
)

Write-Host "Building Release"
Write-Host "================"
Write-Host ""

if ([string]::IsNullOrWhiteSpace($Version)) {
    # Get latest git tag
    $latestTag = git describe --tags --abbrev=0 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($latestTag)) {
        # Convert v1.0.1 to 1.0.1.0
        $tagVersion = $latestTag -replace '^v', ''
        if ($tagVersion -match '^\d+\.\d+\.\d+$') {
            $Version = "$tagVersion.0"
        } else {
            $Version = $tagVersion
        }
        Write-Host "Found latest tag: $latestTag"
    } else {
        Write-Error "Could not get latest git tag. Ensure git is configured and tags exist."
        exit 1
    }
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    $ReleaseTag = "v$($Version.Substring(0, $Version.LastIndexOf('.')))"
}

if (Test-Path "artifacts") {
    Remove-Item -Recurse -Force "artifacts"
}
New-Item -ItemType Directory -Path "artifacts/jellyfin-m3u-exporter" | Out-Null

Write-Host "Version: $Version"
Write-Host "Tag: $ReleaseTag"
Write-Host ""
Write-Host "Restoring dependencies..."
dotnet restore

Write-Host "Building project..."
dotnet build --configuration Release --no-restore -p:TreatWarningsAsErrors=false
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

Write-Host "Packaging plugin..."
Copy-Item "Jellyfin.Plugin.M3UExporter/bin/Release/net9.0/Jellyfin.Plugin.M3UExporter.dll" "artifacts/jellyfin-m3u-exporter/"

$ZipName = "jellyfin-m3u-exporter_$Version.zip"
$ZipPath = Join-Path -Path "artifacts" -ChildPath $ZipName

Write-Host "Creating ZIP: $ZipName"
Compress-Archive -Path "artifacts/jellyfin-m3u-exporter" -DestinationPath $ZipPath -Force

if (Test-Path $ZipPath) {
    $size = (Get-Item $ZipPath).Length / 1KB
    Write-Host "ZIP created: $ZipName ($([Math]::Round($size, 2)) KB)"
    Write-Host ""
    Write-Host "Build successful!"
    Write-Host "Location: $ZipPath"
} else {
    Write-Error "Failed to create ZIP file!"
    exit 1
}
