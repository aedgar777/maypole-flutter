import 'package:riverpod/riverpod.dart';

import 'places_service.dart';

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService();
});
