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
Write-Host "STEP 3: Next Steps"
Write-Host "=================="
Write-Host ""
Write-Host "1. Review changes:"
Write-Host "   git diff manifest.json"
Write-Host ""
Write-Host "2. Commit changes:"
Write-Host "   git add manifest.json"
Write-Host "   git commit -m 'Update manifest for version $Version'"
Write-Host "   git push origin main"
Write-Host ""
Write-Host "3. Create GitHub release:"
Write-Host "   git tag $ReleaseTag"
Write-Host "   git push origin $ReleaseTag"
Write-Host ""
Write-Host "4. Upload ZIP to release:"
Write-Host "   $ZipPath"
Write-Host ""
Write-Host "Done!"
Write-Host ""
