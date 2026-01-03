param(
    [string]$Version,
    [string]$ReleaseTag
)

Write-Host ""
Write-Host "M3U Exporter Release Builder"
Write-Host "============================"
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
        Write-Host "Latest tag: $latestTag"
    } else {
        Write-Error "Could not get latest git tag. Ensure git is configured and tags exist."
        exit 1
    }
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    $ReleaseTag = "v$($Version.Substring(0, $Version.LastIndexOf('.')))"
}

Write-Host "STEP 1: Building Release"
Write-Host "========================"
Write-Host ""
& ".\build-release.ps1" -Version $Version -ReleaseTag $ReleaseTag
if ($LASTEXITCODE -ne 0) {
    exit 1
}

Write-Host ""
Write-Host "STEP 2: Updating Manifest"
Write-Host "========================="
Write-Host ""
$ZipPath = "artifacts/jellyfin-m3u-exporter_$Version.zip"
& ".\update-manifest.ps1" -Version $Version -ZipPath $ZipPath -ReleaseTag $ReleaseTag
if ($LASTEXITCODE -ne 0) {
    exit 1
}

Write-Host ""
Write-Host "STEP 3: Committing and Uploading Release"
Write-Host "========================================="
Write-Host ""

# Check if manifest.json has changes
$status = git status --porcelain manifest.json
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to manifest.json"
} else {
    Write-Host "Committing manifest.json..."
    git add manifest.json
    git commit -m "Update manifest for version $Version"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to commit manifest.json"
        exit 1
    }
    
    Write-Host "Pushing to main..."
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push to main"
        exit 1
    }
    Write-Host "Manifest committed and pushed!"
}

Write-Host ""
Write-Host "Checking if tag exists: $ReleaseTag..."
$tagExists = git rev-parse --verify $ReleaseTag 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Tag $ReleaseTag already exists (skipping tag creation)"
} else {
    Write-Host "Creating and pushing git tag: $ReleaseTag..."
    git tag -a $ReleaseTag -m "Release $ReleaseTag"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create tag"
        exit 1
    }
    
    git push origin $ReleaseTag
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push tag"
        exit 1
    }
    Write-Host "Tag created and pushed!"
}

Write-Host ""
Write-Host "Uploading ZIP to GitHub release..."

$zipName = Split-Path $ZipPath -Leaf
$zipFile = Resolve-Path $ZipPath

# Get GitHub token
$ghToken = $env:GITHUB_TOKEN
if ([string]::IsNullOrWhiteSpace($ghToken)) {
    Write-Error "GITHUB_TOKEN environment variable not set. Please set it before running this script."
    Write-Host ""
    Write-Host "You can set it with:"
    Write-Host "  `$env:GITHUB_TOKEN = 'your_token_here'"
    exit 1
}

# Upload using GitHub API
$uploadUrl = "https://uploads.github.com/repos/jakepi84/JellyfinM3UExporter/releases/assets"
$releaseUrl = "https://api.github.com/repos/jakepi84/JellyfinM3UExporter/releases/tags/$ReleaseTag"

Write-Host "Getting release ID..."
$releaseResponse = Invoke-RestMethod -Uri $releaseUrl -Headers @{ Authorization = "Bearer $ghToken" }
$releaseId = $releaseResponse.id

if ([string]::IsNullOrWhiteSpace($releaseId)) {
    Write-Error "Could not find release for tag $ReleaseTag"
    exit 1
}

Write-Host "Uploading $zipName to release $releaseId..."
$uploadUri = "https://uploads.github.com/repos/jakepi84/JellyfinM3UExporter/releases/$releaseId/assets?name=$zipName"

$fileBytes = [System.IO.File]::ReadAllBytes($zipFile)
$response = Invoke-RestMethod -Uri $uploadUri `
    -Method POST `
    -Headers @{ 
        Authorization = "Bearer $ghToken"
        "Content-Type" = "application/octet-stream"
    } `
    -Body $fileBytes

if ($response.state -eq "uploaded") {
    Write-Host "Upload successful!"
} else {
    Write-Host "Upload response: $($response | ConvertTo-Json)"
}

Write-Host ""
Write-Host "SUCCESS!"
Write-Host "========"
Write-Host ""
Write-Host "Release $ReleaseTag complete!"
Write-Host "ZIP uploaded: $zipName"
Write-Host "View release: https://github.com/jakepi84/JellyfinM3UExporter/releases/tag/$ReleaseTag"
Write-Host ""
