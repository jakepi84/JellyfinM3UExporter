# Fix for Release Build Not Triggering

## Problem
You created and pushed tag `v1.0.0` but the GitHub Actions workflow didn't trigger a release build.

## Root Cause
The tag `v1.0.0` was created pointing to commit `e87cd6d` ("Initial working build"), which was created **before** the GitHub Actions workflow file was added in commit `2643f2a`. 

GitHub Actions only triggers workflows when:
1. The workflow file exists on the default branch (main) ✅
2. The workflow file exists at the commit that the tag points to ❌

## Solution
You need to move the tag to point to a commit that includes the workflow file.

### Step-by-Step Fix

1. **Delete the old tag locally and remotely:**
   ```bash
   git tag -d v1.0.0
   git push origin :refs/tags/v1.0.0
   ```

2. **Make sure you're on the main branch with latest changes:**
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Create the tag again on the current commit:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **Verify the workflow triggered:**
   - Go to https://github.com/jakepi84/JellyfinM3UExporter/actions
   - You should see a new workflow run for "Publish Plugin" triggered by the tag push
   - Wait for the build to complete (usually 2-5 minutes)
   - Check https://github.com/jakepi84/JellyfinM3UExporter/releases for the new release

### Verification
After pushing the new tag, you can verify it points to the correct commit with the workflow:
```bash
git show v1.0.0:.github/workflows/publish.yaml
```
This command should display the workflow file contents. If it shows an error, the tag is still on the wrong commit.

## Prevention
In the future, always create tags from the `main` branch (or whichever branch contains your GitHub Actions workflows). The workflow file must exist at the tagged commit for the workflow to trigger.

```bash
# Best practice for creating release tags
git checkout main
git pull origin main
git tag v1.0.1
git push origin v1.0.1
```
