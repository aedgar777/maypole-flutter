
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables - try .env first (CI/CD), then .env.local (local dev)
  try {
    await dotenv.load(fileName: ".env");
    print('Loaded .env file (CI/CD environment)');
  } catch (e) {
    try {
      await dotenv.load(fileName: ".env.local");
      print('Loaded .env.local file (local development)');
    } catch (e) {
      print('Warning: No .env or .env.local file found. Using default values.');
    }
  }

  // Debug: Print environment information
  const String dartDefineEnv = String.fromEnvironment(
      'ENVIRONMENT', defaultValue: '');
  final dotenvEnv = dotenv.env['ENVIRONMENT'] ?? 'dev';
  final environment = dartDefineEnv.isNotEmpty ? dartDefineEnv : dotenvEnv;

  print('🔧 Environment Debug Info:');
  print('  • Dart Define ENVIRONMENT: "$dartDefineEnv"');
  print('  • .env ENVIRONMENT: "$dotenvEnv"');
  print('  • Final Environment: "$environment"');
  print('  • Firebase Project: ${DefaultFirebaseOptions.currentPlatform
      .projectId}');

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    // If Firebase is already initialized, continue silently
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized, continuing...');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
    title: 'Flutter Demo',
    theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    routerConfig: router, 
    );
  }
}



