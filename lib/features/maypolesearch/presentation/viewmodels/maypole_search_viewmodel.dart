import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/autocomplete_request.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/maypole_search_service_provider.dart';

typedef SelectedPlaceState = ({Map<String, dynamic> placeDetails, LatLng location});

class SelectedPlaceViewModel extends Notifier<SelectedPlaceState?> {
  @override
  SelectedPlaceState? build() => null;

  void setSelectedPlace({
    required Map<String, dynamic> placeDetails,
    required LatLng location,
  }) {
    state = (placeDetails: placeDetails, location: location);
  }

  void clearSelectedPlace() {
    state = null;
  }
}

final selectedPlaceViewModelProvider =
    NotifierProvider<SelectedPlaceViewModel, SelectedPlaceState?>(
      SelectedPlaceViewModel.new,
    );

// Async Notifier
class MaypoleSearchViewModel extends AsyncNotifier<List<PlacePrediction>> {
  void setSelectedPlace({
    required Map<String, dynamic> placeDetails,
    required LatLng location,
  }) {
    ref.read(selectedPlaceViewModelProvider.notifier).setSelectedPlace(
          placeDetails: placeDetails,
          location: location,
        );
  }

  void clearSelectedPlace() {
    ref.read(selectedPlaceViewModelProvider.notifier).clearSelectedPlace();
  }

  @override
  Future<List<PlacePrediction>> build() async {
    return [];
  }

  Future<void> searchMaypoles(String input) async {
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
      final maypoleSearchService = ref.read(maypoleSearchServiceProvider);
      final response = await maypoleSearchService.autocomplete(request);

      // Set state to data
      state = AsyncValue.data(response.predictions);
    } catch (e, st) {
      
      // Try to extract a meaningful error message
      String errorMessage;
      final errorStr = e.toString();
      
      if (errorStr.startsWith('Instance of')) {
        // This is likely a parsing error - the response format is unexpected
        errorMessage = 'Search failed due to unexpected server response. Please check the Cloud Function logs.';
      } else if (errorStr.contains('XMLHttpRequest')) {
        errorMessage = 'Network error: Unable to connect to search server. Please check your internet connection.';
      } else if (errorStr.contains('Timeout')) {
        errorMessage = 'Search timed out. Please try again.';
      } else {
        errorMessage = errorStr;
      }
      
      // Set state to error with descriptive message
      state = AsyncValue.error(Exception(errorMessage), st);
    }
  }
}
