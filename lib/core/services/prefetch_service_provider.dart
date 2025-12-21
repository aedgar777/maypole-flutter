import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_data_prefetch_service.dart';

/// Provider for the user data prefetch service
/// This is a singleton service that manages data prefetching
final userDataPrefetchServiceProvider = Provider<UserDataPrefetchService>((ref) {
  return UserDataPrefetchService();
});
