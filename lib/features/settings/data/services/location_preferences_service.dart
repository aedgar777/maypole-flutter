import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/location_preferences.dart';

/// Service for managing location-based feature preferences
class LocationPreferencesService {
  static const String _keyShowWhenAtLocation = 'show_when_at_location';
  static const String _keyHasShownLocationDialog = 'has_shown_location_dialog';

  /// Load location preferences from storage
  Future<LocationPreferences> loadPreferences({
    required bool systemPermissionGranted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    return LocationPreferences(
      systemPermissionGranted: systemPermissionGranted,
      showWhenAtLocation: prefs.getBool(_keyShowWhenAtLocation) ?? false,
    );
  }

  /// Save show when at location preference
  Future<void> setShowWhenAtLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowWhenAtLocation, value);
  }

  /// Check if we've already shown the location features dialog
  Future<bool> hasShownLocationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasShownLocationDialog) ?? false;
  }

  /// Mark that we've shown the location features dialog
  Future<void> setHasShownLocationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasShownLocationDialog, true);
  }
}
