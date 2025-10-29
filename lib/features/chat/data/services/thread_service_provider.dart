import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/chat/data/services/thread_service.dart';

final threadServiceProvider = Provider<ThreadService>((ref) {
  return ThreadService();
});
