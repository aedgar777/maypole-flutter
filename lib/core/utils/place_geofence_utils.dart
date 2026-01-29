import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Utility class for determining geofence ranges based on place types
/// 
/// This class provides intuitive, hierarchical ranges for different types of places
/// based on their administrative level or scope. Larger entities (countries, states)
/// have larger geofence radii than smaller entities (neighborhoods, buildings).
class PlaceGeofenceUtils {
  
  /// Private constructor to prevent instantiation
  PlaceGeofenceUtils._();

  // Geofence radii in meters
  
  /// Countries and continents - 500km radius
  /// Users anywhere in the country can chat
  static const double _countryRadius = 500000.0;
  
  /// First-order administrative areas (states, provinces) - 200km radius
  /// Covers large state/province-level regions
  static const double _stateRadius = 200000.0;
  
  /// Second-order administrative areas (counties) - 75km radius
  /// Covers county or regional district level
  static const double _countyRadius = 75000.0;
  
  /// Third-order administrative areas - 30km radius
  /// Smaller administrative divisions
  static const double _admin3Radius = 30000.0;
  
  /// Cities, towns, and localities - 15km radius
  /// Covers entire city or town area
  static const double _cityRadius = 15000.0;
  
  /// Sublocalities (boroughs, districts) - 10km radius
  /// For major subdivisions of cities like Manhattan, Brooklyn
  static const double _sublocalityRadius = 10000.0;
  
  /// Neighborhoods - 3km radius
  /// Covers neighborhood-level areas like SoHo, Upper East Side
  static const double _neighborhoodRadius = 3000.0;
  
  /// Routes, streets - 2km radius
  /// For street-level locations
  static const double _streetRadius = 2000.0;
  
  /// Specific establishments (restaurants, stores, etc.) - 500m radius
  /// For individual businesses and points of interest
  static const double _establishmentRadius = 500.0;
  
  /// Small premises, addresses - 200m radius
  /// For specific buildings and addresses
  static const double _premiseRadius = 200.0;
  
  /// Default radius for unknown types - 1km radius
  static const double _defaultRadius = 1000.0;

  /// Get the appropriate geofence radius in meters for a given place type
  /// 
  /// [placeType] - The primary type or type from the Google Places API
  /// [types] - Optional fallback: array of types if primaryType is not available
  /// Returns the radius in meters that defines the geofence for this place type
  static double getRadiusForPlaceType(String? placeType, {List<String>? types}) {
    // If no primary type, try to find the best match from types array
    if ((placeType == null || placeType.isEmpty) && types != null && types.isNotEmpty) {
      // Priority order for determining range (most specific to least specific)
      const priorityOrder = [
        'sublocality_level_1',
        'sublocality',
        'locality',
        'neighborhood',
        'administrative_area_level_2',
        'administrative_area_level_1',
        'political',
        'country',
      ];
      
      for (final priority in priorityOrder) {
        if (types.contains(priority)) {
          placeType = priority;
          break;
        }
      }
    }
    
    if (placeType == null || placeType.isEmpty) {
      return _defaultRadius;
    }

    // Administrative and geographic types (largest to smallest)
    switch (placeType) {
      // Continental and country level
      case 'continent':
      case 'country':
        return _countryRadius;

      // First-order civil entities (states, provinces)
      case 'administrative_area_level_1':
        return _stateRadius;

      // Second-order civil entities (counties)
      case 'administrative_area_level_2':
        return _countyRadius;

      // Third-order civil entities
      case 'administrative_area_level_3':
      case 'administrative_area_level_4':
        return _admin3Radius;

      // Cities and towns
      case 'locality':
      case 'postal_town':
      case 'political':
        return _cityRadius;

      // Sublocalities (boroughs, major districts within cities)
      case 'sublocality':
      case 'sublocality_level_1':
        return _sublocalityRadius;
      
      // Neighborhoods and smaller sublocalities
      case 'neighborhood':
      case 'sublocality_level_2':
      case 'sublocality_level_3':
      case 'sublocality_level_4':
      case 'sublocality_level_5':
      case 'colloquial_area':
        return _neighborhoodRadius;

      // Streets and routes
      case 'route':
      case 'intersection':
        return _streetRadius;

      // Specific establishments and points of interest
      case 'establishment':
      case 'point_of_interest':
      case 'restaurant':
      case 'cafe':
      case 'bar':
      case 'store':
      case 'shopping_mall':
      case 'park':
      case 'museum':
      case 'school':
      case 'university':
      case 'hospital':
      case 'airport':
      case 'train_station':
      case 'bus_station':
      case 'subway_station':
      case 'transit_station':
      case 'gas_station':
      case 'bank':
      case 'atm':
      case 'pharmacy':
      case 'supermarket':
      case 'convenience_store':
      case 'lodging':
      case 'tourist_attraction':
      case 'place_of_worship':
      case 'church':
      case 'mosque':
      case 'synagogue':
      case 'hindu_temple':
      case 'stadium':
      case 'gym':
      case 'library':
      case 'post_office':
      case 'fire_station':
      case 'police':
      case 'city_hall':
      case 'courthouse':
      case 'embassy':
      case 'amusement_park':
      case 'aquarium':
      case 'art_gallery':
      case 'bowling_alley':
      case 'casino':
      case 'movie_theater':
      case 'night_club':
      case 'spa':
      case 'zoo':
        return _establishmentRadius;

      // Specific addresses and premises
      case 'premise':
      case 'subpremise':
      case 'street_address':
      case 'street_number':
        return _premiseRadius;

      // Default for unknown types
      default:
        return _defaultRadius;
    }
  }

  /// Check if a user's location is within range of a place
  /// 
  /// [userLatitude] - User's current latitude
  /// [userLongitude] - User's current longitude
  /// [placeLatitude] - Place's latitude
  /// [placeLongitude] - Place's longitude
  /// [placeType] - The type of place (determines radius)
  /// [types] - Optional: array of types as fallback if primaryType is not available
  /// 
  /// Returns true if the user is within the geofence radius for this place type
  static bool isUserInRange({
    required double userLatitude,
    required double userLongitude,
    required double placeLatitude,
    required double placeLongitude,
    String? placeType,
    List<String>? types,
  }) {
    final radius = getRadiusForPlaceType(placeType, types: types);
    final distance = calculateDistance(
      userLatitude,
      userLongitude,
      placeLatitude,
      placeLongitude,
    );
    
    return distance <= radius;
  }

  /// Check if a Position object is within range of a place
  /// 
  /// [position] - User's current position from Geolocator
  /// [placeLatitude] - Place's latitude
  /// [placeLongitude] - Place's longitude
  /// [placeType] - The type of place (determines radius)
  /// 
  /// Returns null if position is null, otherwise returns true if within range
  static bool? isPositionInRange({
    required Position? position,
    required double placeLatitude,
    required double placeLongitude,
    String? placeType,
  }) {
    if (position == null) {
      return null;
    }

    return isUserInRange(
      userLatitude: position.latitude,
      userLongitude: position.longitude,
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
      placeType: placeType,
    );
  }

  /// Check if a Position object is within a custom proximity threshold of a location
  /// 
  /// This method is useful for backward compatibility or when you want to use
  /// a fixed threshold instead of the place type-based radius.
  /// 
  /// [position] - User's current position from Geolocator
  /// [targetLat] - Target location latitude
  /// [targetLon] - Target location longitude
  /// [threshold] - Custom distance threshold in meters
  /// 
  /// Returns null if position is null, otherwise returns true if within threshold
  static bool? isPositionWithinProximity({
    required Position? position,
    required double targetLat,
    required double targetLon,
    required double threshold,
  }) {
    if (position == null) {
      return null;
    }

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      targetLat,
      targetLon,
    );

    return distance <= threshold;
  }

  /// Get the distance from a Position to a place
  /// 
  /// [position] - User's current position from Geolocator
  /// [placeLatitude] - Place's latitude
  /// [placeLongitude] - Place's longitude
  /// 
  /// Returns distance in meters, or null if position is null
  static double? getDistanceToPlace({
    required Position? position,
    required double placeLatitude,
    required double placeLongitude,
  }) {
    if (position == null) {
      return null;
    }

    return calculateDistance(
      position.latitude,
      position.longitude,
      placeLatitude,
      placeLongitude,
    );
  }

  /// Calculate the distance between two geographic coordinates using the Haversine formula
  /// 
  /// Returns the distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get a human-readable description of the geofence range for a place type
  ///
  /// [placeType] - The primary type of the place
  /// [types] - Optional: array of types as fallback if primaryType is not available
  /// 
  /// Useful for UI display to show users how far the geofence extends
  static String getRadiusDescription(String? placeType, {List<String>? types}) {
    final radius = getRadiusForPlaceType(placeType, types: types);
    
    if (radius >= 1000) {
      final km = (radius / 1000).round();
      return '$km km';
    } else {
      return '${radius.round()} m';
    }
  }

  /// Get a categorization of place types for grouping or filtering
  ///
  /// [placeType] - The primary type of the place
  /// [types] - Optional: array of types as fallback if primaryType is not available
  /// 
  /// Returns a category name like 'country', 'state', 'city', 'sublocality', 'neighborhood', or 'establishment'
  static String getPlaceCategory(String? placeType, {List<String>? types}) {
    // If no primary type, try to find the best match from types array
    if ((placeType == null || placeType.isEmpty) && types != null && types.isNotEmpty) {
      const priorityOrder = [
        'sublocality_level_1',
        'sublocality',
        'locality',
        'neighborhood',
        'administrative_area_level_2',
        'administrative_area_level_1',
        'political',
        'country',
      ];
      
      for (final priority in priorityOrder) {
        if (types.contains(priority)) {
          placeType = priority;
          break;
        }
      }
    }
    
    if (placeType == null || placeType.isEmpty) {
      return 'unknown';
    }

    if (placeType == 'continent' || placeType == 'country') {
      return 'country';
    }

    if (placeType == 'administrative_area_level_1') {
      return 'state';
    }

    if (placeType == 'administrative_area_level_2') {
      return 'county';
    }

    if (placeType.startsWith('administrative_area_level_')) {
      return 'administrative';
    }

    if (placeType == 'locality' || placeType == 'postal_town' || placeType == 'political') {
      return 'city';
    }

    if (placeType == 'sublocality' || placeType == 'sublocality_level_1') {
      return 'sublocality';
    }

    if (placeType.contains('sublocality') || 
        placeType == 'neighborhood' || 
        placeType == 'colloquial_area') {
      return 'neighborhood';
    }

    if (placeType == 'route' || placeType == 'intersection') {
      return 'street';
    }

    if (placeType == 'premise' || 
        placeType == 'subpremise' || 
        placeType == 'street_address' ||
        placeType == 'street_number') {
      return 'premise';
    }

    return 'establishment';
  }
}
