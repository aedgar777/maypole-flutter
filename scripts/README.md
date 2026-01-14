# Scripts Directory

Helper scripts for building, testing, and deploying the Maypole app.

## Deployment Scripts

**All deployment scripts have been moved to the `deployment/` subdirectory.**

See [deployment/README.md](deployment/README.md) for comprehensive deployment documentation including:
- Development environment deployments (dev → internal testing)
- Beta environment deployments (prod config → beta testing)
- Production environment deployments
- Individual platform deployments (Android, iOS, Web)
- Full deployment pipeline with tests

Quick links to deployment scripts:
```bash
# Development
./scripts/deployment/dev-deploy-all.sh       # Deploy all dev builds with tests
./scripts/deployment/dev-deploy-android.sh   # Android only
./scripts/deployment/dev-deploy-ios.sh       # iOS only
./scripts/deployment/dev-deploy-web.sh       # Web only

# Beta
./scripts/deployment/beta-deploy-android.sh  # Play Store Open Testing
./scripts/deployment/beta-deploy-ios.sh      # TestFlight Beta
./scripts/deployment/beta-deploy-web.sh      # Web beta channel

# Production
./scripts/deployment/prod-deploy-firebase.sh # Firebase tools
./scripts/deployment/prod-deploy-web.sh      # Web production
```

## Build Scripts

Individual build scripts for each platform and configuration remain in this directory:

### Available Build Scripts
- `build-android-dev-debug.sh` / `build-android-dev-release.sh`
- `build-android-prod-debug.sh` / `build-android-prod-release.sh`
- `build-ios-dev-debug.sh` / `build-ios-dev-release.sh`
- `build-ios-prod-debug.sh` / `build-ios-prod-release.sh`
- `build-ios-ipa-dev.sh` / `build-ios-ipa-prod.sh`
- `build-web-dev.sh` / `build-web-prod.sh`
- `build-macos-*` (macOS builds)
- And more...

## Utility Scripts

- **Version Management**: `bump-version.sh`, `get-version.sh`, `validate-version.sh`
- **Environment Setup**: `setup.sh`, `setup-env.sh`, `switch-to-dev.sh`, `switch-to-prod.sh`
- **Testing**: `test-build-configs.sh`, `verify-build-configs.sh`
- **iOS Specific**: `local-ios-build.sh`, `test-ios-build.sh`
- **Android Toolchain**: `fix-android-toolchain.sh` - Fixes Android SDK issues

## Using Scripts from Android Studio

### Terminal
1. Open Terminal tab (Alt+F12 or View → Tool Windows → Terminal)
2. Run any script:
   ```bash
   ./scripts/deployment/dev-deploy-all.sh
   ```

### External Tools
1. Go to **File → Settings → Tools → External Tools**
2. Click **+** to add new tool
3. Configure:
   - **Name**: Deploy Dev (All)
   - **Program**: `$ProjectFileDir$/scripts/deployment/dev-deploy-all.sh`
   - **Working directory**: `$ProjectFileDir$`
4. Access via **Tools → External Tools → Deploy Dev (All)**

## Prerequisites

### For All Scripts
1. **Environment variables**: Ensure `.env` is properly configured in project root
2. **Flutter SDK**: Properly installed and in PATH

### For Deployment Scripts
1. **Firebase CLI installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Logged in to Firebase**:
   ```bash
   firebase login
   ```

3. **Fastlane installed** (for Android/iOS deployments):
   ```bash
   # Android
   cd android && bundle install
   
   # iOS
   cd ios && bundle install
   ```

4. **Service Account Keys**: Configure environment variables for Play Store and App Store Connect

See [deployment/README.md](deployment/README.md) for complete deployment prerequisites.

## Troubleshooting

**"command not found: firebase"**
- Install Firebase CLI: `npm install -g firebase-tools`

**"Permission denied"**
- Make scripts executable: `chmod +x scripts/**/*.sh`

**"No project active"** (Firebase)
- Project configured in `.firebaserc`
- Or use: `firebase use --add`

**"Release app bundle failed to strip debug symbols from native libraries"** (Android)
- This occurs when Android cmdline-tools are missing
- Run the fix script: `./scripts/fix-android-toolchain.sh`
- This will install cmdline-tools and accept Android SDK licenses
- Requires Android Studio to be installed (uses bundled JDK)
- After running, verify with: `flutter doctor`

**Android toolchain issues**
- Run: `./scripts/fix-android-toolchain.sh`
- This script will:
  - Install missing Android cmdline-tools
  - Configure Java environment (uses Android Studio's JDK)
  - Accept all Android SDK licenses
  - Fix native library symbol stripping issues

**Build failures**
- Ensure all dependencies are installed: `flutter pub get`
- Check environment variables in `.env`
- For platform-specific issues, see platform documentation
