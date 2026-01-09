import 'package:riverpod/riverpod.dart';

import 'maypole_search_service.dart';

final maypoleSearchServiceProvider = Provider<MaypoleSearchService>((ref) {
  return MaypoleSearchService();
});
