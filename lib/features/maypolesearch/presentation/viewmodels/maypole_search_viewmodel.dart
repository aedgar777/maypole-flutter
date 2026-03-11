import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/autocomplete_request.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/maypole_search_service_provider.dart';

// Async Notifier
class MaypoleSearchViewModel extends AsyncNotifier<List<PlacePrediction>> {
  @override
  Future<List<PlacePrediction>> build() async {
    return [];
  }

  Future<void> searchMaypoles(String input) async {
    debugPrint('🔎 ViewModel: searchMaypoles called with input: "$input"');
    
    // Set state to loading
    state = const AsyncValue.loading();

    try {
      if (input.isEmpty) {
        debugPrint('🔎 ViewModel: Empty input, returning empty list');
        state = const AsyncValue.data([]);
        return;
      }
      
      // Create a request object
      debugPrint('🔎 ViewModel: Creating AutocompleteRequest');
      final request = AutocompleteRequest(input: input);

      // Call the service
      debugPrint('🔎 ViewModel: Getting search service from provider');
      final maypoleSearchService = ref.read(maypoleSearchServiceProvider);
      
      debugPrint('🔎 ViewModel: Calling autocomplete service');
      final response = await maypoleSearchService.autocomplete(request);

      // Set state to data
      debugPrint('🔎 ViewModel: Got ${response.predictions.length} predictions');
      state = AsyncValue.data(response.predictions);
    } catch (e, st) {
      debugPrint('💥 ViewModel: Error during search: $e');
      debugPrint('💥 ViewModel: Stack trace: $st');
      debugPrint('💥 ViewModel: Error type: ${e.runtimeType}');
      
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
