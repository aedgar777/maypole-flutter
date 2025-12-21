import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/firebase_options.dart';
import 'core/widgets/notification_handler.dart';

/// Handler for background messages when app is terminated
/// This runs in a separate isolate and cannot access app state
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables - try .env first (CI/CD), then .env.local (local dev)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Loaded .env file (CI/CD environment)');
  } catch (e) {
    try {
      await dotenv.load(fileName: ".env.local");
      debugPrint('Loaded .env.local file (local development)');
    } catch (e) {
      debugPrint(
          'Warning: No .env or .env.local file found. Using default values.');
    }
  }

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

  // Enable Firestore offline persistence with unlimited cache size
  // This dramatically reduces document reads by caching data between app sessions
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore persistence enabled with unlimited cache');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not enable Firestore persistence: $e');
    // Continue anyway - app will work without persistence
  }

  // Setup background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return NotificationHandler(
      child: MaterialApp.router(
        title: _getAppTitle(),
        theme: darkTheme,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
