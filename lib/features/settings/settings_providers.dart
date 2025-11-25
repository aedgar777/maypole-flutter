import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/settings/data/services/storage_service.dart';
import 'package:maypole/features/settings/domain/settings_state.dart';
import 'package:maypole/features/settings/presentation/viewmodels/settings_viewmodel.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final settingsViewModelProvider = NotifierProvider<
    SettingsViewModel,
    SettingsState>(
  SettingsViewModel.new,
);
