import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/autocomplete_request.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/maypole_search_service_provider.dart';

// State Notifier
class MaypoleSearchViewModel
    extends StateNotifier<AsyncValue<List<PlacePrediction>>> {
  final Ref _ref;

  MaypoleSearchViewModel(this._ref) : super(const AsyncValue.data([]));

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
      final maypoleSearchService = _ref.read(maypoleSearchServiceProvider);
      final response = await maypoleSearchService.autocomplete(request);

      // Set state to data
      state = AsyncValue.data(response.predictions);
    } catch (e, st) {
      // Set state to error
      state = AsyncValue.error(e, st);
    }
  }
}
