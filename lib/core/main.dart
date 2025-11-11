import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';
import 'app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables - try .env first (CI/CD), then .env.local (local dev)
  bool dotenvLoaded = false;
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Loaded .env file (CI/CD environment)');
    dotenvLoaded = true;
  } catch (e) {
    try {
      await dotenv.load(fileName: ".env.local");
      debugPrint('Loaded .env.local file (local development)');
      dotenvLoaded = true;
    } catch (e) {
      debugPrint(
          'Warning: No .env or .env.local file found. Using default values.');
    }
  }

  // Initialize the router
  final router = createRouter();

  // Debug: Print environment information
  const String dartDefineEnv = String.fromEnvironment(
      'ENVIRONMENT', defaultValue: '');
  final dotenvEnv = dotenvLoaded ? (dotenv.env['ENVIRONMENT'] ?? 'dev') : 'dev';
  final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;

  final isProd = environment == 'prod' || environment == 'production';
  final envPrefix = isProd ? "FIREBASE_PROD" : "FIREBASE_DEV";

  // Create Firebase options from environment variables
  final FirebaseOptions firebaseOptions;

  if (kIsWeb) {
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['${envPrefix}_WEB_API_KEY']!,
      appId: dotenv.env['${envPrefix}_WEB_APP_ID']!,
      messagingSenderId: dotenv.env['${envPrefix}_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['${envPrefix}_PROJECT_ID']!,
      authDomain: dotenv.env['${envPrefix}_AUTH_DOMAIN']!,
      storageBucket: dotenv.env['${envPrefix}_STORAGE_BUCKET']!,
    );
  } else if (Platform.isIOS) {
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['${envPrefix}_IOS_API_KEY']!,
      appId: dotenv.env['${envPrefix}_IOS_APP_ID']!,
      messagingSenderId: dotenv.env['${envPrefix}_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['${envPrefix}_PROJECT_ID']!,
      authDomain: dotenv.env['${envPrefix}_AUTH_DOMAIN']!,
      storageBucket: dotenv.env['${envPrefix}_STORAGE_BUCKET']!,
      iosBundleId: dotenv.env['IOS_BUNDLE_ID']!,
    );
  } else if (Platform.isAndroid) {
    firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['${envPrefix}_ANDROID_API_KEY']!,
      appId: dotenv.env['${envPrefix}_ANDROID_APP_ID']!,
      messagingSenderId: dotenv.env['${envPrefix}_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['${envPrefix}_PROJECT_ID']!,
      authDomain: dotenv.env['${envPrefix}_AUTH_DOMAIN']!,
      storageBucket: dotenv.env['${envPrefix}_STORAGE_BUCKET']!,
    );
  } else {
    // You can add support for other platforms here if needed
    throw UnsupportedError('Unsupported platform for Firebase initialization');
  }

  debugPrint('🔧 Environment Debug Info:');
  debugPrint('  • Dart Define ENVIRONMENT: "$dartDefineEnv"');
  debugPrint('  • .env ENVIRONMENT: "$dotenvEnv"');
  debugPrint('  • Final Environment: "$environment"');
  debugPrint('  • Firebase Project: ${firebaseOptions.projectId}');

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    // If Firebase is already initialized, continue silently
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized, continuing...');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

  runApp(ProviderScope(child: MyApp(router: router)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  String _getAppTitle() {
    const String dartDefineEnv = String.fromEnvironment(
        'ENVIRONMENT', defaultValue: '');
    String dotenvEnv = 'dev';

    try {
      dotenvEnv = dotenv.env['ENVIRONMENT'] ?? 'dev';
    } catch (e) {
      dotenvEnv = 'dev';
    }

    final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;

    switch (environment) {
      case 'production':
      case 'prod':
        return 'Maypole';
      case 'dev':
      case 'development':
      default:
        return 'Maypole (Dev)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: _getAppTitle(),
      theme: darkTheme,
      routerConfig: router,
    );
  }
}
