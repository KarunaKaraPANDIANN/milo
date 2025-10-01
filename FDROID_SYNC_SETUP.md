# F-Droid Auto-Sync Pipeline Setup

This workflow automatically syncs changes from your app repository to the F-Droid metadata repository.

## What It Does

When you push changes to `main` branch that affect:
- `fastlane/**` (metadata, screenshots, changelogs)
- `pubspec.yaml` (version updates)
- `.github/workflows/release.yml`

The workflow will:
1. Extract version info from `pubspec.yaml`
2. Update the F-Droid metadata file
3. Commit and push to your F-Droid fork

## Setup Instructions

### Step 1: Create a Personal Access Token (PAT)

1. Go to **GitLab** (not GitHub): https://gitlab.com/-/profile/personal_access_tokens
2. Click **"Add new token"**
3. Fill in:
   - **Token name:** `fdroid-sync-from-github`
   - **Expiration date:** Set to 1 year or no expiration
   - **Scopes:** Check these boxes:
     - ✅ `api` (full API access)
     - ✅ `write_repository` (push to repository)
4. Click **"Create personal access token"**
5. **Copy the token** (you won't see it again!)

### Step 2: Add Token to GitHub Secrets

1. Go to your GitHub repository: https://github.com/KarunaKaraPANDIANN/milo/settings/secrets/actions
2. Click **"New repository secret"**
3. Fill in:
   - **Name:** `FDROID_SYNC_TOKEN`
   - **Secret:** Paste the GitLab token you copied
4. Click **"Add secret"**

### Step 3: Test the Workflow

```bash
cd /home/karan/Documents/projects/flutter/milo

# Add the new workflow
git add .github/workflows/sync-fdroid.yml FDROID_SYNC_SETUP.md
git commit -m "Add F-Droid auto-sync workflow"
git push origin main
```

The workflow will run automatically on the next push that changes fastlane metadata or version.

## Manual Trigger (Optional)

If you want to trigger the sync manually, update the workflow to add:

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:  # Add this line
```

Then you can trigger it from: https://github.com/KarunaKaraPANDIANN/milo/actions

## How to Use

### When Releasing a New Version:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.1.0+2
   ```

2. **Add changelog:**
   ```bash
   echo "Bug fixes and improvements" > fastlane/metadata/android/en-US/changelogs/2.txt
   ```

3. **Commit and push:**
   ```bash
   git add pubspec.yaml fastlane/
   git commit -m "Release v1.1.0"
   git push origin main
   ```

4. **Tag the release:**
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

The workflows will:
- ✅ Build and release APKs (release.yml)
- ✅ Sync metadata to F-Droid repo (sync-fdroid.yml)

### When Updating Screenshots/Metadata:

1. **Update files in `fastlane/metadata/`**
2. **Commit and push:**
   ```bash
   git add fastlane/
   git commit -m "Update screenshots"
   git push origin main
   ```

The sync workflow will automatically update the F-Droid repository.

## Troubleshooting

### Workflow Fails with "Authentication Failed"

- Check that `FDROID_SYNC_TOKEN` secret is set correctly
- Verify the GitLab token hasn't expired
- Ensure the token has `api` and `write_repository` scopes

### Workflow Doesn't Trigger

- Check that you modified files in the `paths:` list
- View workflow runs: https://github.com/KarunaKaraPANDIANN/milo/actions

### Manual Sync

If the workflow fails, you can always sync manually:

```bash
# In your app repo
cd /home/karan/Documents/projects/flutter/milo
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')

# In F-Droid repo
cd /home/karan/Documents/projects/flutter/milo-of-croton
# Update metadata manually
git add metadata/io.github.karunakarapandiann.milo.yml
git commit -m "Update to version $VERSION"
git push origin io.github.karunakarapandiann.milo
```

## Benefits

✅ **Automatic version updates** - No manual editing of F-Droid metadata
✅ **Consistent metadata** - Screenshots and descriptions stay in sync
✅ **Less work** - One push updates both repositories
✅ **Audit trail** - All changes tracked in git history

## Files Involved

- **Trigger:** `.github/workflows/sync-fdroid.yml`
- **Source:** `pubspec.yaml`, `fastlane/metadata/`
- **Target:** `milo-of-croton/metadata/io.github.karunakarapandiann.milo.yml`
