import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maypole/core/services/location_service.dart';
import '../../domain/location_preferences.dart';
import '../../data/services/location_preferences_service.dart';

class LocationSettingsState {
  final LocationPreferences preferences;
  final bool isLoading;

  const LocationSettingsState({
    required this.preferences,
    this.isLoading = false,
  });

  LocationSettingsState copyWith({
    LocationPreferences? preferences,
    bool? isLoading,
  }) {
    return LocationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationSettingsViewModel extends Notifier<LocationSettingsState> {
  late final LocationPreferencesService _preferencesService;
  late final LocationService _locationService;

  @override
  LocationSettingsState build() {
    _preferencesService = LocationPreferencesService();
    _locationService = LocationService();
    
    // Load initial state
    _loadPreferences();
    
    return const LocationSettingsState(
      preferences: LocationPreferences(),
      isLoading: true,
    );
  }

  Future<void> _loadPreferences() async {
    final systemPermissionGranted = await _locationService.hasLocationPermission();
    final preferences = await _preferencesService.loadPreferences(
      systemPermissionGranted: systemPermissionGranted,
    );
    
    state = LocationSettingsState(
      preferences: preferences,
      isLoading: false,
    );
  }

  /// Refresh permission status (called when app resumes)
  Future<void> refreshPermissionStatus() async {
    final systemPermissionGranted = await _locationService.hasLocationPermission();
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        systemPermissionGranted: systemPermissionGranted,
      ),
    );
  }

  /// Request system location permission
  Future<bool> requestPermission() async {
    final permission = await _locationService.requestPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        systemPermissionGranted: granted,
      ),
    );
    
    return granted;
  }

  /// Open device settings
  Future<void> openSettings() async {
    await _locationService.openAppSettings();
  }

  /// Toggle show when at location feature (pin badge + image upload restriction)
  Future<void> toggleShowWhenAtLocation(bool value) async {
    await _preferencesService.setShowWhenAtLocation(value);
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        showWhenAtLocation: value,
      ),
    );
  }

  /// Enable all location features (for the dialog)
  Future<void> enableAllLocationFeatures() async {
    await _preferencesService.setShowWhenAtLocation(true);
    
    state = state.copyWith(
      preferences: state.preferences.copyWith(
        showWhenAtLocation: true,
      ),
    );
  }

  /// Check if we should show the location features dialog
  Future<bool> shouldShowLocationDialog() async {
    final hasShown = await _preferencesService.hasShownLocationDialog();
    final hasPermission = await _locationService.hasLocationPermission();
    return hasPermission && !hasShown;
  }

  /// Mark dialog as shown
  Future<void> markDialogShown() async {
    await _preferencesService.setHasShownLocationDialog();
  }
}
