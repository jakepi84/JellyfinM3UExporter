# How to Fix the v1.0.1 Tag and Manifest

## Problem Summary
The v1.0.1 tag was created before updating `Directory.Build.props` to version `1.0.1.0`. This caused the publish workflow to build version `1.0.0.0` and incorrectly update the manifest.json with version `1.0.0.0` instead of `1.0.1.0`.

## Current State
- **Tag v1.0.1 exists** pointing to a commit with `Directory.Build.props` version `1.0.0.0`
- **manifest.json** shows version `1.0.0.0` with sourceUrl pointing to v1.0.1 release
- **This PR** updates `Directory.Build.props` to version `1.0.1.0`

## Solution
After this PR is merged, you need to move the v1.0.1 tag to the new commit that has the correct version.

### Step-by-Step Instructions

1. **Merge this PR to main branch**

2. **Delete the incorrect v1.0.1 tag:**
   ```bash
   # Delete locally
   git tag -d v1.0.1
   
   # Delete on GitHub
   git push origin :refs/tags/v1.0.1
   ```

3. **Delete the v1.0.1 release on GitHub:**
   - Go to https://github.com/jakepi84/JellyfinM3UExporter/releases
   - Click on the v1.0.1 release
   - Click "Delete" button
   - Confirm deletion

4. **Checkout the main branch with the updated version:**
   ```bash
   git checkout main
   git pull origin main
   ```

5. **Verify the version is correct:**
   ```bash
   grep -A2 '<Version>' Directory.Build.props
   # Should show: <Version>1.0.1.0</Version>
   ```

6. **Create the v1.0.1 tag again:**
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

7. **The workflow will run automatically** and will:
   - Build the plugin with version `1.0.1.0`
   - Update manifest.json with the correct version
   - Create a new v1.0.1 release with the correct artifacts

8. **Verify the fix:**
   - Check https://github.com/jakepi84/JellyfinM3UExporter/actions for the workflow run
   - After completion, verify manifest.json shows version `1.0.1.0`
   - Check the release has the correct zip file: `m3u-exporter_1.0.1.0.zip`

## Alternative: Manual Workflow Trigger
If you don't want to delete the release, you can manually trigger the workflow after merging this PR:

1. Merge this PR to main
2. Go to https://github.com/jakepi84/JellyfinM3UExporter/actions/workflows/publish.yaml
3. Click "Run workflow"
4. Enter tag: `v1.0.1`
5. The workflow will checkout v1.0.1, but since it still has the old version, this won't fix the problem

**Note:** The manual trigger won't work correctly because the tag still points to the old version. You must move the tag as described above.

## Prevention for Future Releases
Always update `Directory.Build.props` BEFORE creating the tag. See the updated RELEASE_FIX_GUIDE.md for the complete process.
