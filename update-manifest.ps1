# Update Manifest Script
# This script updates manifest.json with a new version entry

param(
    [string]$Version,
    [string]$ZipPath,
    [string]$ReleaseTag,
    [string]$RepositoryUrl = "https://github.com/jakepi84/JellyfinM3UExporter"
)

# Validate inputs
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Error "Version is required. Usage: .\update-manifest.ps1 -Version 1.0.1.0 -ZipPath ./artifacts/jellyfin-m3u-exporter_1.0.1.0.zip"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ZipPath) -or -not (Test-Path $ZipPath)) {
    Write-Error "ZIP file not found: $ZipPath"
    exit 1
}

# If not provided, derive release tag from version
if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    $parts = $Version.Split('.')
    $ReleaseTag = "v$($parts[0]).$($parts[1]).$($parts[2])"
}

Write-Host "Updating manifest.json"
Write-Host "Version: $Version"
Write-Host "Tag: $ReleaseTag"
Write-Host "ZIP: $ZipPath"

# Read manifest.json
if (-not (Test-Path "manifest.json")) {
    Write-Error "manifest.json not found!"
    exit 1
}

$manifest = Get-Content "manifest.json" -Raw | ConvertFrom-Json

# Calculate MD5 checksum
$md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
$hash = $md5.ComputeHash([System.IO.File]::ReadAllBytes((Resolve-Path $ZipPath)))
$checksum = [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()

Write-Host "Checksum: $checksum"

# Get values from build.yaml
$buildYaml = Get-Content "build.yaml" -Raw
$targetAbi = if ($buildYaml -match 'targetAbi:\s*"?([^"\n]+)"?') { $matches[1] } else { "10.11.5.0" }
$changelog = if ($buildYaml -match 'changelog:\s*>?\s*(.+?)(?=^[a-z]|$)') { $matches[1].Trim() } else { "Release version $Version" }

Write-Host "TargetAbi: $targetAbi"
Write-Host "Changelog: $changelog"

# Construct source URL
$zipFileName = Split-Path $ZipPath -Leaf
$sourceUrl = "$RepositoryUrl/releases/download/$ReleaseTag/$zipFileName"
Write-Host "SourceUrl: $sourceUrl"

# Get current timestamp
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Create new version entry
$newVersion = @{
    version = $Version
    changelog = $changelog
    targetAbi = $targetAbi
    sourceUrl = $sourceUrl
    checksum = $checksum
    timestamp = $timestamp
}

# Update manifest: remove any existing version with same number, add new one at the beginning
$manifest[0].versions = @($newVersion) + ($manifest[0].versions | Where-Object { $_.version -ne $Version })

# Save manifest.json with proper formatting
$json = $manifest | ConvertTo-Json -Depth 10
# Pretty print with 2-space indentation
$json = $json -replace '(?m)^', '  ' -replace '^\s{2}\[', '[' -replace '^\s{2}\]', ']'
$json = $json -replace '(?m)^  ', ''  # Fix the first level
Set-Content "manifest.json" $json -Encoding UTF8

Write-Host "`n✓ manifest.json updated successfully!"
Write-Host "New version entry:"
Write-Host "  - Version: $($newVersion.version)"
Write-Host "  - TargetAbi: $($newVersion.targetAbi)"
Write-Host "  - SourceUrl: $($newVersion.sourceUrl)"
Write-Host "  - Checksum: $($newVersion.checksum)"
Write-Host "`nDon't forget to commit and push manifest.json to main!"
