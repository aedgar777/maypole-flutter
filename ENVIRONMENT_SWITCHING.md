# Environment Switching Guide

This project supports multiple Firebase environments (Development and Production) with easy
switching through Android Studio's GUI.

## 🎯 Android Studio GUI Method (Recommended)

### 1. Build Variants (Bottom Left Panel)

1. Open your project in Android Studio
2. Look for the **"Build Variants"** panel in the bottom-left corner
3. If not visible, go to `View` → `Tool Windows` → `Build Variants`
4. In the Build Variants panel, you'll see:
    - **devDebug** - Development environment, debug build
    - **devRelease** - Development environment, release build
    - **prodDebug** - Production environment, debug build
    - **prodRelease** - Production environment, release build

### 2. Run Configurations (Top Toolbar)

1. In the top toolbar, click the dropdown next to the "Run" button
2. You'll see these pre-configured options:
    - **Flutter Development** - Runs dev environment
    - **Flutter Production** - Runs prod environment
3. Select your desired environment and click Run

### 3. Manual Configuration

If the run configurations don't appear automatically:

1. Go to `Run` → `Edit Configurations...`
2. Click the `+` button → `Flutter`
3. Set the following for Development:
    - **Name**: `Flutter Development`
    - **Dart entrypoint**: `lib/main.dart`
    - **Additional run args**: `--dart-define=ENVIRONMENT=dev --flavor=dev`
4. Repeat for Production with:
    - **Name**: `Flutter Production`
    - **Additional run args**: `--dart-define=ENVIRONMENT=production --flavor=prod`

## 🔧 Command Line Method

### Development Environment

```bash
flutter run --dart-define=ENVIRONMENT=dev --flavor=dev
```

### Production Environment

```bash
flutter run --dart-define=ENVIRONMENT=production --flavor=prod
```

## 🔍 Environment Detection

The app automatically detects which environment it's running in:

1. **Dart Define** (highest priority): `--dart-define=ENVIRONMENT=xxx`
2. **Environment File** (fallback): `.env` or `.env.local` file
3. **Default**: Development environment

## 📱 What Changes Between Environments

| Aspect | Development | Production |
|--------|-------------|------------|
| **Firebase Project** | `maypole-flutter-dev` | `maypole-flutter-ce6c3` |
| **App ID** | `app.maypole.maypole.dev` | `app.maypole.maypole` |
| **App Name** | "Maypole Dev" | "Maypole" |
| **User Data** | Separate dev users | Production users |
| **Firestore** | Dev database | Production database |

## 🚀 Benefits

✅ **No manual file switching** - Android Studio handles it automatically  
✅ **Separate app installations** - Dev and prod can run side-by-side  
✅ **Visual confirmation** - App name shows "Maypole Dev" vs "Maypole"  
✅ **Safe testing** - Dev environment is completely isolated  
✅ **Easy deployment** - Production builds use prod Firebase automatically

## 🐛 Debugging

The app prints environment info on startup:

```
🔧 Environment Debug Info:
  • Dart Define ENVIRONMENT: "dev"
  • .env ENVIRONMENT: "dev"  
  • Final Environment: "dev"
  • Firebase Project: maypole-flutter-dev
✅ Firebase initialized successfully
```

## 🗂️ Project Structure

```
android/app/src/
├── dev/
│   └── google-services.json    # Dev Firebase config
├── prod/  
│   └── google-services.json    # Prod Firebase config
└── main/                       # Shared Android code

.idea/runConfigurations/
├── Flutter_Development.xml     # AS run config for dev
└── Flutter_Production.xml      # AS run config for prod
```

That's it! The Android Studio GUI method handles everything automatically. No more manual file
switching or command-line scripts needed.