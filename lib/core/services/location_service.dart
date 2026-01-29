import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/place_geofence_utils.dart';

/// Service for handling location permissions and calculations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Proximity threshold in meters (100 meters)
  static const double proximityThreshold = 100.0;

  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Check if we have permission to access location
  Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get the current position of the device
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await hasLocationPermission();
      debugPrint('🔐 Location permission status: $hasPermission');
      if (!hasPermission) {
        debugPrint('❌ No location permission');
        return null;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      debugPrint('📡 Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        debugPrint('❌ Location service not enabled');
        return null;
      }

      debugPrint('📍 Fetching current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('✅ Got position: lat=${position.latitude}, lon=${position.longitude}');
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('💥 Error getting position: $e');
      // Return last known position if available
      return _lastKnownPosition;
    }
  }

  /// Get last known position without requesting a new one
  Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }

  /// Start listening to position changes
  void startLocationUpdates({
    required Function(Position) onPositionChanged,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (Position position) {
        _lastKnownPosition = position;
        onPositionChanged(position);
      },
      onError: (error) {
        // Handle error silently, keep last known position
      },
    );
  }

  /// Stop listening to position changes
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  /// 
  /// Delegates to PlaceGeofenceUtils for consistent distance calculations
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return PlaceGeofenceUtils.calculateDistance(lat1, lon1, lat2, lon2);
  }

  /// Check if user is within proximity threshold of a given location
  /// Returns null if current position cannot be determined
  /// 
  /// Delegates to PlaceGeofenceUtils for consistent proximity checks
  Future<bool?> isWithinProximity({
    required double targetLat,
    required double targetLon,
    double? customThreshold,
  }) async {
    final position = await getCurrentPosition();
    return PlaceGeofenceUtils.isPositionWithinProximity(
      position: position,
      targetLat: targetLat,
      targetLon: targetLon,
      threshold: customThreshold ?? proximityThreshold,
    );
  }

  /// Check if user is within range of a place based on its type
  /// Returns null if current position cannot be determined
  /// 
  /// This method uses dynamic geofencing based on place type:
  /// - Countries: 500 km
  /// - States: 200 km
  /// - Cities: 15 km
  /// - Neighborhoods: 5 km
  /// - Establishments: 500 m
  /// - Buildings: 200 m
  Future<bool?> isInRangeOfPlace({
    required double placeLatitude,
    required double placeLongitude,
    String? placeType,
  }) async {
    final position = await getCurrentPosition();
    return PlaceGeofenceUtils.isPositionInRange(
      position: position,
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
      placeType: placeType,
    );
  }

  /// Check if a position is within proximity of a target location
  /// Uses cached position if available, returns null if no position
  /// 
  /// Delegates to PlaceGeofenceUtils for consistent proximity checks
  bool? isPositionWithinProximity({
    required double targetLat,
    required double targetLon,
    Position? position,
    double? customThreshold,
  }) {
    final pos = position ?? _lastKnownPosition;
    return PlaceGeofenceUtils.isPositionWithinProximity(
      position: pos,
      targetLat: targetLat,
      targetLon: targetLon,
      threshold: customThreshold ?? proximityThreshold,
    );
  }

  /// Check if a position is within range of a place based on its type
  /// Uses cached position if available, returns null if no position
  /// 
  /// This method uses dynamic geofencing based on place type:
  /// - Countries: 500 km
  /// - States: 200 km
  /// - Cities: 15 km
  /// - Neighborhoods: 5 km
  /// - Establishments: 500 m
  /// - Buildings: 200 m
  bool? isPositionInRangeOfPlace({
    required double placeLatitude,
    required double placeLongitude,
    Position? position,
    String? placeType,
  }) {
    final pos = position ?? _lastKnownPosition;
    return PlaceGeofenceUtils.isPositionInRange(
      position: pos,
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
      placeType: placeType,
    );
  }

  /// Get distance to a location in meters
  /// Returns null if current position cannot be determined
  /// 
  /// Delegates to PlaceGeofenceUtils for consistent distance calculations
  Future<double?> getDistanceToLocation({
    required double targetLat,
    required double targetLon,
  }) async {
    final position = await getCurrentPosition();
    return PlaceGeofenceUtils.getDistanceToPlace(
      position: position,
      placeLatitude: targetLat,
      placeLongitude: targetLon,
    );
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app-specific settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Clean up resources
  void dispose() {
    stopLocationUpdates();
  }
}
