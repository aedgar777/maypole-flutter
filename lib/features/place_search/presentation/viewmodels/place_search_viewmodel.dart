import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/autocomplete_request.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/places_service_provider.dart';

// State Notifier
class PlaceSearchViewModel
    extends StateNotifier<AsyncValue<List<PlacePrediction>>> {
  final Ref _ref;

  PlaceSearchViewModel(this._ref) : super(const AsyncValue.data([]));

  Future<void> searchPlaces(String input) async {
    // Set state to loading
    state = const AsyncValue.loading();

    try {
      if (input.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      // Create a request object
      final request = AutocompleteRequest(input: input);

      // Call the service
      final placesService = _ref.read(placesServiceProvider);
      final response = await placesService.autocomplete(request);

      // Set state to data
      state = AsyncValue.data(response.predictions);
    } catch (e, st) {
      // Set state to error
      state = AsyncValue.error(e, st);
    }
  }
}
