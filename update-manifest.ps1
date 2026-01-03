param(
    [string]$Version,
    [string]$ZipPath,
    [string]$ReleaseTag,
    [string]$RepositoryUrl = "https://github.com/jakepi84/JellyfinM3UExporter"
)

if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Error "Version is required"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ZipPath) -or -not (Test-Path $ZipPath)) {
    Write-Error "ZIP file not found: $ZipPath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    $parts = $Version.Split('.')
    $ReleaseTag = "v$($parts[0]).$($parts[1]).$($parts[2])"
}

Write-Host "Updating manifest.json"
Write-Host "====================="
Write-Host ""
Write-Host "Version: $Version"
Write-Host "Tag: $ReleaseTag"
Write-Host "ZIP: $ZipPath"
Write-Host ""

if (-not (Test-Path "manifest.json")) {
    Write-Error "manifest.json not found!"
    exit 1
}

$manifest = Get-Content "manifest.json" -Raw | ConvertFrom-Json

$md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
$hash = $md5.ComputeHash([System.IO.File]::ReadAllBytes((Resolve-Path $ZipPath)))
$checksum = [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()

Write-Host "Checksum: $checksum"

$buildYaml = Get-Content "build.yaml" -Raw
$targetAbi = if ($buildYaml -match 'targetAbi:\s*"?([^"\n]+)"?') { $matches[1] } else { "10.11.5.0" }
$changelog = if ($buildYaml -match 'changelog:\s*>?\s*(.+?)(?=^[a-z]|$)') { $matches[1].Trim() } else { "Release version $Version" }

Write-Host "TargetAbi: $targetAbi"
Write-Host "Changelog: $changelog"

$zipFileName = Split-Path $ZipPath -Leaf
$sourceUrl = "$RepositoryUrl/releases/download/$ReleaseTag/$zipFileName"
Write-Host "SourceUrl: $sourceUrl"
Write-Host ""

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$newVersion = @{
    version = $Version
    changelog = $changelog
    targetAbi = $targetAbi
    sourceUrl = $sourceUrl
    checksum = $checksum
    timestamp = $timestamp
}

$manifest[0].versions = @($newVersion) + ($manifest[0].versions | Where-Object { $_.version -ne $Version })

$json = $manifest | ConvertTo-Json -Depth 10
$json = $json -replace '(?m)^', '  ' -replace '^\s{2}\[', '[' -replace '^\s{2}\]', ']'
$json = $json -replace '(?m)^  ', ''
Set-Content "manifest.json" $json -Encoding UTF8

Write-Host "Updated manifest.json"
Write-Host ""
Write-Host "New entry added:"
Write-Host "  Version: $($newVersion.version)"
Write-Host "  TargetAbi: $($newVersion.targetAbi)"
Write-Host "  Checksum: $($newVersion.checksum)"

