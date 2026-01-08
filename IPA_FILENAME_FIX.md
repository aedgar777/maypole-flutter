# IPA Filename Fix - Deployment Pipeline

## Issue
The Fastlane deployment was failing because it was looking for `Runner.ipa` but Xcode's `xcodebuild -exportArchive` creates an IPA file named after the **app display name** (`maypole.ipa`), not the scheme name.

## Root Cause
When using `xcodebuild -exportArchive`, the output IPA filename is determined by:
1. The app's **CFBundleDisplayName** or **CFBundleName** in `Info.plist`
2. NOT by the Xcode scheme name or project name

In our case: The app is named "Maypole" → outputs `maypole.ipa`

## What Was Fixed

### ✅ Fastfile Changes

**File: `ios/fastlane/Fastfile`**

1. **`deploy_dev` lane** (Line 116)
   - Changed: `ipa: "#{output_directory}/Runner.ipa"`
   - To: `ipa: "#{output_directory}/maypole.ipa"`

2. **`upload_ipa_only` lane** (Line 174)
   - Changed: `ipa: "../build/ios/ipa/Runner.ipa"`
   - To: `ipa: "../build/ios/ipa/maypole.ipa"`

3. **`deploy_beta` and `deploy_prod` lanes**
   - ✅ No changes needed
   - These use `build_app` which auto-detects the IPA filename

### ✅ GitHub Workflows

**All workflows are correctly configured:**

- **`.github/workflows/develop.yml`**
  - Uses: `bundle exec fastlane ios deploy_dev`
  - Status: ✅ Fixed (uses corrected Fastfile)

- **`.github/workflows/beta.yml`**
  - Uses: `bundle exec fastlane deploy_beta`
  - Status: ✅ No issue (auto-detection)

- **`.github/workflows/production.yml`**
  - Uses: `bundle exec fastlane deploy_prod`
  - Status: ✅ No issue (auto-detection)

## Testing

### Local Testing ✅
- Built and signed IPA locally
- Successfully uploaded to TestFlight
- Upload confirmed with Delivery UUID: `1008f4c2-52c8-4879-968a-70aa5f28e185`

### Expected CI/CD Behavior
All three workflows should now successfully:
1. Build Flutter app
2. Create signed archive
3. Export IPA as `maypole.ipa`
4. Upload to TestFlight

## Technical Details

### Why `build_app` Works Automatically
The `build_app` Fastlane action:
- Calls `gym` internally
- Automatically detects the exported IPA filename
- No manual path specification needed

### Why Manual Export Needs Explicit Path
The `deploy_dev` lane uses manual `xcodebuild` commands for more control:
- Allows custom signing parameters
- Provides verbose output for debugging
- Requires explicit IPA path in `upload_to_testflight`

## Verification Steps

To verify the fix works in CI/CD:

```bash
# Push to develop branch
git push origin develop

# Check GitHub Actions
# https://github.com/aedgar777/maypole-flutter/actions

# Look for successful TestFlight upload in logs
```

## Related Files
- `ios/fastlane/Fastfile` - Fastlane lane definitions
- `.github/workflows/develop.yml` - Development deployment
- `.github/workflows/beta.yml` - Beta deployment  
- `.github/workflows/production.yml` - Production deployment
- `LOCAL_IOS_BUILD_GUIDE.md` - Local build documentation

---

**Status**: ✅ Fixed and tested  
**Date**: January 8, 2026  
**Impact**: All deployments (dev, beta, prod) should now succeed
