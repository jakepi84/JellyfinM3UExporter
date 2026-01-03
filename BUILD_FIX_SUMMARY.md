# Build Failure Fix Summary

## Problem

Builds were failing with the following error when triggered by tag pushes:

```
! [rejected]        HEAD -> main (non-fast-forward)
error: failed to push some refs to 'https://github.com/jakepi84/JellyfinM3UExporter'
hint: Updates were rejected because a pushed branch tip is behind its remote
hint: counterpart.
```

## Root Cause

The workflow had a step that tried to commit and push manifest.json updates back to the main branch after building a release from a tag. When a tag is pushed:

1. GitHub Actions checks out the tag, which creates a **detached HEAD** state
2. The workflow updates manifest.json
3. It tries to commit the changes
4. It attempts to push using `git push origin HEAD:main`

This fails because:
- In detached HEAD state, HEAD doesn't point to a branch
- The push tries to update main from a commit that isn't on any branch
- Git rejects this as a non-fast-forward push

## Solution

**Removed the problematic "Commit updated manifest" step** (lines 77-86 in build.yml) that was trying to push from detached HEAD state.

Instead of trying to commit manifest changes back to main during tag builds:
1. The manifest.json is still generated during the build
2. It's now included as a release asset alongside the plugin ZIP file
3. Users can access the updated manifest from the release page

## Changes Made

### Before
```yaml
- name: Update manifest.json
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    ./update-manifest.sh "$VERSION" "artifacts/plugin.zip"

- name: Commit updated manifest
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    git add manifest.json
    if ! git diff --staged --quiet; then
      git commit -m "Update manifest.json for version $VERSION [skip ci]"
      git push origin HEAD:main  # ❌ FAILED in detached HEAD
    fi
```

### After
```yaml
- name: Update manifest.json for release
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    ./update-manifest.sh "$VERSION" "artifacts/plugin.zip"

- name: Create Release
  if: startsWith(github.ref, 'refs/tags/v')
  uses: softprops/action-gh-release@v1
  with:
    files: |
      artifacts/plugin.zip
      manifest.json  # ✅ Include as release asset
```

## Benefits

1. **Fixes the build failure** - No more non-fast-forward errors
2. **Simpler workflow** - Removed unnecessary git operations
3. **Better separation of concerns** - Tag builds focus on creating releases, not updating branches
4. **Manifest still available** - Users can get the updated manifest from the release assets

## Testing

To verify the fix works:
1. Push a new tag (e.g., `v1.0.3`)
2. The workflow should complete successfully
3. Check the release page for the manifest.json asset

## Alternative Approaches Considered

1. **Fetch and merge main before pushing** - Too complex and could introduce merge conflicts
2. **Switch back to main branch** - Defeats the purpose of building from a tag
3. **Use a separate workflow** - Unnecessary complexity for this use case

The chosen solution is the simplest and most appropriate for the use case.
