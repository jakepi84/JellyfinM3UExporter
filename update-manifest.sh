#!/bin/bash
# Update manifest.json with new plugin version
# This script should be run after building the plugin

set -e

VERSION="$1"
ZIP_FILE="$2"

if [ -z "$VERSION" ] || [ -z "$ZIP_FILE" ]; then
    echo "Usage: $0 <version> <zip_file>"
    exit 1
fi

# Validate version format (should be X.Y.Z.W)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Expected X.Y.Z.W (e.g., 1.0.1.0)"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: ZIP file not found: $ZIP_FILE"
    exit 1
fi

echo "Updating manifest.json for version $VERSION..."

# Calculate checksum (Jellyfin uses MD5 for plugin checksums)
CHECKSUM=$(md5sum "$ZIP_FILE" | awk '{print $1}')
echo "Checksum (MD5): $CHECKSUM"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Timestamp: $TIMESTAMP"

# Extract changelog from build.yaml
CHANGELOG=$(yq eval '.changelog' build.yaml)
if [ -z "$CHANGELOG" ] || [ "$CHANGELOG" = "null" ]; then
    echo "Warning: Could not extract changelog from build.yaml"
    CHANGELOG="Release version $VERSION"
fi

# Extract targetAbi from build.yaml
TARGET_ABI=$(yq eval '.targetAbi' build.yaml)
if [ -z "$TARGET_ABI" ] || [ "$TARGET_ABI" = "null" ]; then
    echo "Error: Could not extract targetAbi from build.yaml"
    exit 1
fi

# Get repository URL from git remote
REPO_URL=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')

# Extract tag version (X.Y.Z format)
TAG="v$(echo $VERSION | cut -d. -f1-3)"

# Construct sourceUrl
SOURCE_URL="${REPO_URL}/releases/download/${TAG}/jellyfin-m3u-exporter_${VERSION}.zip"

# Create new version entry
NEW_VERSION=$(jq -n \
  --arg version "$VERSION" \
  --arg changelog "$CHANGELOG" \
  --arg targetAbi "$TARGET_ABI" \
  --arg sourceUrl "$SOURCE_URL" \
  --arg checksum "$CHECKSUM" \
  --arg timestamp "$TIMESTAMP" \
  '{
    version: $version,
    changelog: $changelog,
    targetAbi: $targetAbi,
    sourceUrl: $sourceUrl,
    checksum: $checksum,
    timestamp: $timestamp
  }')

# Update manifest.json
# First, validate manifest.json exists and has at least one package
if [ ! -f "manifest.json" ]; then
    echo "Error: manifest.json not found"
    exit 1
fi

PACKAGE_COUNT=$(jq '. | length' manifest.json)
if [ "$PACKAGE_COUNT" -eq 0 ]; then
    echo "Error: manifest.json is empty"
    exit 1
fi

# Remove any existing entry with the same version from the first package
jq --arg version "$VERSION" \
  '.[0].versions = [.[0].versions[] | select(.version != $version)]' \
  manifest.json > manifest.tmp.json

# Then add the new version at the beginning of the first package
jq --argjson newVersion "$NEW_VERSION" \
  '.[0].versions = [$newVersion] + .[0].versions' \
  manifest.tmp.json > manifest.json

rm manifest.tmp.json

echo "✓ manifest.json updated successfully!"
echo "Version $VERSION added with:"
echo "  - TargetAbi: $TARGET_ABI"
echo "  - SourceUrl: $SOURCE_URL"
echo "  - Checksum: $CHECKSUM"
echo "  - Timestamp: $TIMESTAMP"
