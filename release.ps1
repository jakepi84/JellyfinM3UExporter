# Release Script
# Builds the plugin and updates manifest.json for a new release

param(
    [string]$Version,
    [string]$ReleaseTag
)

Write-Host "╔════════════════════════════════════════╗"
Write-Host "║     M3U Exporter Release Builder       ║"
Write-Host "╚════════════════════════════════════════╝`n"

# If not provided, extract from Directory.Build.props
if ([string]::IsNullOrWhiteSpace($Version)) {
    [xml]$props = Get-Content "Directory.Build.props"
    $Version = $props.Project.PropertyGroup.Version
}

if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    $parts = $Version.Split('.')
    $ReleaseTag = "v$($parts[0]).$($parts[1]).$($parts[2])"
}

# Step 1: Build
Write-Host "STEP 1: Building Release"
Write-Host "═════════════════════════════════════════`n"
& ".\build-release.ps1" -Version $Version -ReleaseTag $ReleaseTag
if ($LASTEXITCODE -ne 0) {
    exit 1
}

# Step 2: Update manifest
Write-Host "`n`nSTEP 2: Updating Manifest"
Write-Host "═════════════════════════════════════════`n"
$ZipPath = "artifacts/jellyfin-m3u-exporter_$Version.zip"
& ".\update-manifest.ps1" -Version $Version -ZipPath $ZipPath -ReleaseTag $ReleaseTag
if ($LASTEXITCODE -ne 0) {
    exit 1
}

# Step 3: Next steps
Write-Host "`n`nSTEP 3: Next Steps"
Write-Host "═════════════════════════════════════════"
Write-Host "`n1. Review the changes to manifest.json:"
Write-Host "   git diff manifest.json"
Write-Host "`n2. If satisfied, commit and push:"
Write-Host "   git add manifest.json"
Write-Host "   git commit -m `"Update manifest.json for version $Version`""
Write-Host "   git push origin main"
Write-Host "`n3. Create a GitHub release:"
Write-Host "   git tag $ReleaseTag"
Write-Host "   git push origin $ReleaseTag"
Write-Host "`n4. Upload the ZIP to the GitHub release:"
Write-Host "   Location: $ZipPath"
Write-Host "`nRelease process complete!`n"
