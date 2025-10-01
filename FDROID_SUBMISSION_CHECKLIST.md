# F-Droid Submission Checklist for Milo

## ✅ Required Steps (MUST DO)

### 1. App Compliance
- [ ] **Verify app complies with [F-Droid Inclusion Policy](https://f-droid.org/docs/Inclusion_Policy)**
  - No proprietary dependencies
  - No tracking/analytics
  - No non-free network services
  - Open source license (MIT ✓)

### 2. Author Notification
- [ ] **Notify original app author** (if you're not the author)
  - Since you appear to be the author (KarunaKaraPANDIANN), mark this as done
  - If not, create an issue in your repo confirming you approve F-Droid inclusion

### 3. Reference Related Issues
- [ ] **Link any related fdroiddata issues**
  - Replace `Closes rfp#<RFP issue number>` with actual issue number
  - Replace `Closes fdroiddata#<fdroiddata issue number>` with actual issue number
  - Or remove these lines if no issues exist

### 4. Build Verification
- [ ] **Test build with `fdroid build`**
  ```bash
  cd /home/karan/Documents/projects/flutter/milo-of-croton
  fdroid build io.github.karunakarapandiann.milo
  ```
- [ ] **Ensure all CI/CD pipelines pass**

## 🔥 Strongly Recommended (HIGHLY ENCOURAGED)

### 5. Fastlane Metadata
- [x] **Add Fastlane metadata structure** ✓ (Already exists)
  - Location: `milo/fastlane/metadata/android/en-US/`
  - [x] title.txt ✓
  - [x] short_description.txt ✓
  - [x] full_description.txt ✓
  - [x] changelogs/1.txt ✓ (Just created)
  - [ ] **Add screenshots** to `fastlane/metadata/android/en-US/images/phoneScreenshots/`
    - Recommended: 3-5 screenshots showing key features
    - Size: 1080x1920 or similar phone aspect ratio

### 6. Release Tagging
- [ ] **Create and push v1.0 tag**
  ```bash
  cd /home/karan/Documents/projects/flutter/milo
  git tag -a v1.0 -m "Release version 1.0"
  git push origin v1.0
  ```
- [x] **GitHub Actions workflow exists** ✓ (Just created at `.github/workflows/release.yml`)

## 💡 Suggested (OPTIONAL BUT BENEFICIAL)

### 7. Git Submodules
- [ ] Consider using git submodules instead of srclibs for external dependencies

### 8. Reproducible Builds
- [ ] **Enable Reproducible Builds** for enhanced security
  - This allows F-Droid to use your signature
  - Users can switch between F-Droid and other channels
  - Requires proper signing configuration

### 9. Multiple APKs
- [ ] **Build multiple APKs for different architectures**
  - Already configured in metadata (arm64-v8a, armeabi-v7a, x86_64)
  - Reduces APK size for users

## 📋 Pre-Submission Actions

### Before Creating Merge Request:

1. **Push all changes to your GitHub repo:**
   ```bash
   cd /home/karan/Documents/projects/flutter/milo
   git add .github/workflows/release.yml
   git add fastlane/metadata/android/en-US/changelogs/1.txt
   git commit -m "Add F-Droid release workflow and changelog"
   git push origin main
   ```

2. **Create and push the v1.0 tag:**
   ```bash
   git tag -a v1.0 -m "Release version 1.0"
   git push origin v1.0
   ```

3. **Wait for GitHub Actions to build and create release**
   - Check: https://github.com/KarunaKaraPANDIANN/milo/actions
   - Verify release created: https://github.com/KarunaKaraPANDIANN/milo/releases

4. **Test F-Droid build locally:**
   ```bash
   cd /home/karan/Documents/projects/flutter/milo-of-croton
   fdroid build io.github.karunakarapandiann.milo
   ```

5. **Create Merge Request in fdroiddata repo:**
   - Go to: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/new
   - Use the **App inclusion template**
   - Fill in the checklist based on this document
   - Reference any related issues

## 🐛 Known Issues to Fix

### Critical:
1. **Version Code Mismatch:**
   - Your `pubspec.yaml` shows `version: 1.0.0+1`
   - F-Droid metadata was showing `versionCode: 11` (FIXED to 1)
   - Make sure these match!

2. **Missing GitHub Release:**
   - You need to create the v1.0 release with APK files
   - The metadata references: `https://github.com/KarunaKaraPANDIANN/milo/releases/download/v1.0/app-arm64-v8a-release.apk`

### Recommended:
1. **Add Screenshots:**
   - Create directory: `milo/fastlane/metadata/android/en-US/images/phoneScreenshots/`
   - Add 3-5 PNG screenshots showing app features

2. **Add Feature Graphic (Optional):**
   - Create: `milo/fastlane/metadata/android/en-US/images/featureGraphic.png`
   - Size: 1024x500 pixels

## 📝 Summary of Changes Made

### Files Created:
1. ✅ `.github/workflows/release.yml` - GitHub Actions workflow for releases
2. ✅ `fastlane/metadata/android/en-US/changelogs/1.txt` - Changelog for v1.0

### Files Modified:
1. ✅ `milo-of-croton/metadata/io.github.karunakarapandiann.milo.yml`
   - Fixed versionCode from 11 to 1
   - Simplified Flutter version detection
   - Added binary URL for reproducible builds
   - Removed complex VercodeOperation

## 🚀 Next Steps

1. Review and test all changes
2. Add screenshots to Fastlane metadata
3. Push changes to GitHub
4. Create v1.0 tag and release
5. Test F-Droid build locally
6. Create merge request in fdroiddata repository

## 📚 Resources

- [F-Droid Inclusion Policy](https://f-droid.org/docs/Inclusion_Policy)
- [F-Droid Build Metadata Reference](https://f-droid.org/docs/Build_Metadata_Reference)
- [Fastlane Metadata Structure](https://gitlab.com/snippets/1895688)
- [Reproducible Builds](https://f-droid.org/docs/Reproducible_Builds)
