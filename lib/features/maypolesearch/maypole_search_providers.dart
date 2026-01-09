import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/maypolesearch/presentation/viewmodels/maypole_search_viewmodel.dart';
import 'data/models/autocomplete_response.dart';

final maypoleSearchViewModelProvider =
    AsyncNotifierProvider<MaypoleSearchViewModel, List<PlacePrediction>>(
      MaypoleSearchViewModel.new,
    );
