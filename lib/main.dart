import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/app_router.dart';

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

  // Debug: Print environment information
  const String dartDefineEnv = String.fromEnvironment(
      'ENVIRONMENT', defaultValue: '');
  final dotenvEnv = dotenvLoaded ? (dotenv.env['ENVIRONMENT'] ?? 'dev') : 'dev';
  final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;

  debugPrint('🔧 Environment Debug Info:');
  debugPrint('  • Dart Define ENVIRONMENT: "$dartDefineEnv"');
  debugPrint('  • .env ENVIRONMENT: "$dotenvEnv"');
  debugPrint('  • Final Environment: "$environment"');
  debugPrint('  • Firebase Project: ${DefaultFirebaseOptions.currentPlatform
      .projectId}');

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
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

  // Use emulators if defined by --dart-define=USE_EMULATOR=true
  const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');
  if (useEmulator) {
    try {
      debugPrint('⚠️ Using Firebase Emulators');
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      debugPrint('Error using Firebase emulators: $e');
    }
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}
