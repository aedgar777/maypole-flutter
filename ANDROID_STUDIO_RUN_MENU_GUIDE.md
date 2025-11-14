# Android Studio Run/Debug Menu Guide

This guide shows you how to use the run/debug dropdown menu in Android Studio's top bar to quickly
switch between build configurations.

## 🚀 Quick Answer

**Yes! You can use the run/debug dropdown in the top bar, just like in Xcode.**

After restarting Android Studio, you'll see new configurations in the dropdown:

- **Android Dev Debug**
- **Android Dev Release**
- **Android Prod Debug**
- **Android Prod Release**

Just select one and click play! No need to manually change Build Variants.

## 📍 Where to Find It

The run/debug configuration dropdown is in the **top toolbar**, between the device selector and the
play button:

```
[Device Selector ▼] [Run Configuration ▼] [▶️ Play] [🐛 Debug]
```

## 🎯 Available Run Configurations

After restarting Android Studio, you'll see these configurations in the dropdown:

### Android-Specific (New!)

- **Android Dev Debug** - Development with debugging
- **Android Dev Release** - Development release build
- **Android Prod Debug** - Production with debugging
- **Android Prod Release** - Production release build

### Flutter Generic (Existing)

- **Flutter Development** - Generic dev configuration
- **Flutter Production** - Generic prod configuration
- **main.dart** - Default Flutter entry point

## ✨ How to Use

### Quick Start (Recommended)

1. **Click the dropdown** next to the play button
2. **Select your configuration**:
    - `Android Dev Debug` for daily development
    - `Android Prod Release` for production testing
3. **Click the play button** ▶️ or press `Shift+F10`

That's it! The correct build variant, flavor, and environment will be used automatically.

### Step-by-Step Example

**To run in dev-debug mode:**

1. Click dropdown → Select "Android Dev Debug"
2. Select your device/emulator
3. Click play ▶️
4. The app builds with:
    - Build variant: `devDebug`
    - Flavor: `dev`
    - Environment: `dev`
    - App ID: `app.maypole.maypole.dev.debug`

**To run in prod-release mode:**

1. Click dropdown → Select "Android Prod Release"
2. Select your device/emulator
3. Click play ▶️
4. The app builds with:
    - Build variant: `prodRelease`
    - Flavor: `prod`
    - Environment: `production`
    - App ID: `app.maypole.maypole`

## 📊 Configuration Comparison

| Run Configuration | Build Variant | Flavor | Mode | Environment | Use For |
|-------------------|---------------|--------|------|-------------|---------|
| **Android Dev Debug** | devDebug | dev | debug | dev | Daily development |
| **Android Dev Release** | devRelease | dev | release | dev | Performance testing |
| **Android Prod Debug** | prodDebug | prod | debug | production | Production debugging |
| **Android Prod Release** | prodRelease | prod | release | production | Final testing |
| Flutter Development | devDebug | dev | debug | dev | Generic dev (legacy) |
| Flutter Production | prodDebug | prod | debug | production | Generic prod (legacy) |

## 🔄 Switching Configurations

### Method 1: Dropdown Menu (Fastest)

1. Click the configuration dropdown
2. Select new configuration
3. Click play

**No need to change Build Variants manually!**

### Method 2: Edit Configurations

1. Click dropdown → "Edit Configurations..."
2. Select configuration from left sidebar
3. Modify settings if needed
4. Click OK

## 🆚 Run Configuration vs Build Variants

### When to Use Run Configurations (Top Bar)

✅ **Quick switching** between dev/prod
✅ **One-click** build and run
✅ **Remembers** your last selection
✅ **Passes environment** variables automatically

**Best for:** Daily development workflow

### When to Use Build Variants Panel

✅ **Building APKs** without running
✅ **Fine-grained control** over build types
✅ **Seeing all variants** at once
✅ **Understanding** build system

**Best for:** Building release APKs, troubleshooting

## 🎨 Visual Guide

```
╔════════════════════════════════════════════════════════════╗
║ Android Studio Top Bar                                     ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  📱 Pixel 5 API 31  ▼  │  Android Dev Debug  ▼  │  ▶️  🐛  ║
║  [Device Selector]     │  [Run Configuration]  │  [Run]   ║
║                        │                       │          ║
║                        │  ┌──────────────────────────────┐║
║                        └─▶│ Android Dev Debug         │║
║                           │ Android Dev Release       │║
║                           │ Android Prod Debug        │║
║                           │ Android Prod Release      │║
║                           │ ─────────────────────────  │║
║                           │ Flutter Development       │║
║                           │ Flutter Production        │║
║                           │ ─────────────────────────  │║
║                           │ main.dart                 │║
║                           │ Edit Configurations...    │║
║                           └──────────────────────────────┘║
╚════════════════════════════════════════════════════════════╝
```

## 💡 Pro Tips

### Keyboard Shortcuts

- **Run**: `Shift + F10` (uses current configuration)
- **Debug**: `Shift + F9`
- **Switch Config**: `Alt + Shift + F10` → Arrow keys → Enter
- **Edit Config**: `Alt + Shift + F10` → `0` (zero)

### Creating Custom Configurations

1. Click dropdown → "Edit Configurations..."
2. Click `+` (Add New Configuration)
3. Select "Flutter"
4. Configure:
    - **Name**: Your custom name
    - **Dart entrypoint**: `lib/main.dart`
    - **Build flavor**: `dev` or `prod`
    - **Additional arguments**: `--dart-define=ENVIRONMENT=dev` (or production)
5. Click OK

### Configuration Settings Explained

```xml
<configuration name="Android Dev Debug" type="FlutterRunConfigurationType">
  <option name="buildFlavor" value="dev" />           <!-- Sets flavor -->
  <option name="additionalArgs" 
          value="--dart-define=ENVIRONMENT=dev" />    <!-- Passes env var -->
  <option name="filePath" 
          value="$PROJECT_DIR$/lib/main.dart" />      <!-- Entry point -->
</configuration>
```

## 🔍 Verifying Your Configuration

After selecting a configuration and running, check the console output:

```
Launching lib/main.dart on Pixel 5 API 31 in debug mode...
Running Gradle task 'assembleDevDebug'...
✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk

🔧 Environment Debug Info:
  • Dart Define ENVIRONMENT: "dev"
  • Final Environment: "dev"
  • Firebase Project: maypole-flutter-dev
```

Look for:

- ✅ Correct Gradle task (e.g., `assembleDevDebug`)
- ✅ Correct APK name (e.g., `app-dev-debug.apk`)
- ✅ Environment matches your selection

## ⚠️ Troubleshooting

### Configuration Not Showing in Dropdown

**Solution 1: Restart Android Studio**

```bash
File → Invalidate Caches → Invalidate and Restart
```

**Solution 2: Check Configuration Files**

```bash
ls -la .idea/runConfigurations/
# Should show: Android_Dev_Debug.xml, etc.
```

**Solution 3: Manually Add**

1. Click dropdown → "Edit Configurations..."
2. Click `+` → Flutter
3. Follow "Creating Custom Configurations" above

### Wrong Build Variant Used

The run configuration sets the flavor, but the Build Variants panel can override it:

**Fix:**

1. Open Build Variants panel
2. Ensure variant matches your configuration:
    - Android Dev Debug → Select `devDebug`
    - Android Prod Release → Select `prodRelease`
3. Or just rely on the run configuration (it should set it automatically)

### Environment Not Switching

**Check console output** for environment debug info.

**If wrong:**

1. Edit the run configuration
2. Verify `--dart-define=ENVIRONMENT=dev` (or `production`)
3. Ensure `buildFlavor` matches (dev/prod)

### Can't Run Release Build

**Error**: "Release builds require signing configuration"

**Solution**: Use debug mode for testing, or configure signing:

1. Create signing key
2. Add to `android/app/build.gradle.kts`
3. Or use debug variant instead

## 📚 Related Documentation

- **[QUICK_START_BUILD_CONFIGS.md](./QUICK_START_BUILD_CONFIGS.md)** - Quick overview
- **[ANDROID_BUILD_CONFIGURATIONS.md](./ANDROID_BUILD_CONFIGURATIONS.md)** - Complete Android guide
- **[BUILD_CONFIGURATIONS_SUMMARY.md](./BUILD_CONFIGURATIONS_SUMMARY.md)** - Cross-platform
  comparison

## 🎯 Quick Reference

| Want to... | Do this... |
|------------|-----------|
| **Daily development** | Select "Android Dev Debug" → Play |
| **Test performance** | Select "Android Dev Release" → Play |
| **Debug production** | Select "Android Prod Debug" → Play |
| **Final testing** | Select "Android Prod Release" → Play |
| **Create custom config** | Dropdown → Edit Configurations → + |
| **See build variant** | View → Tool Windows → Build Variants |
| **Keyboard shortcut** | `Alt + Shift + F10` → Arrow keys |

---

**Remember**: The run configuration dropdown is your friend! It's the fastest way to switch between
environments in Android Studio. Just click, select, and play! 🚀

