import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';

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
