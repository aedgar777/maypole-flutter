import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/place_search/presentation/viewmodels/place_search_viewmodel.dart';
import 'data/models/autocomplete_response.dart';
import 'data/services/places_service.dart';

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService();
});

final placeSearchViewModelProvider = StateNotifierProvider<
    PlaceSearchViewModel, AsyncValue<List<PlacePrediction>>>((ref) {
  return PlaceSearchViewModel(ref);
});
