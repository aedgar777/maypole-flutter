import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/services/fcm_service.dart';

/// Provider for FCM service
/// Use this to access FCM functionality throughout the app
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});
