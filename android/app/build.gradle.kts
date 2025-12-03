plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.maypole.maypole"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "app.maypole.maypole"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define build types first
    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            // Removed applicationIdSuffix = ".debug" to avoid double suffixes
            versionNameSuffix = "-debug"
        }
        release {
            isDebuggable = false
            isMinifyEnabled = true
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Define product flavors
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            // Set applicationId directly to match Firebase config
            applicationId = "app.maypole.dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"] = "Maypole Dev"
        }
        create("prod") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "Maypole"
        }
    }

    // This generates the following build variants:
    // - devDebug (dev-debug)
    // - devRelease (dev-release)
    // - prodDebug (prod-debug)
    // - prodRelease (prod-release)
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}
