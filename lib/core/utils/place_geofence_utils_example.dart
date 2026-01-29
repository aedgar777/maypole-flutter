/// Example usage of PlaceGeofenceUtils
/// 
/// This file demonstrates how to use the PlaceGeofenceUtils class for
/// determining geofence ranges based on place types and checking if a
/// user is within range of a place.

import 'place_geofence_utils.dart';

void main() {
  // Example 1: Check if a user is in range of different place types
  
  // User's current location (e.g., San Francisco)
  const double userLat = 37.7749;
  const double userLon = -122.4194;
  
  // Restaurant location (very close to user)
  const double restaurantLat = 37.7750;
  const double restaurantLon = -122.4195;
  const String restaurantType = 'restaurant';
  
  // Check if user is in range of the restaurant (500m radius)
  final isInRestaurantRange = PlaceGeofenceUtils.isUserInRange(
    userLatitude: userLat,
    userLongitude: userLon,
    placeLatitude: restaurantLat,
    placeLongitude: restaurantLon,
    placeType: restaurantType,
  );
  print('User in restaurant range: $isInRestaurantRange'); // true
  
  // Example 2: Check if user is in range of a city
  
  // San Francisco city center
  const double cityCenterLat = 37.7749;
  const double cityCenterLon = -122.4194;
  const String cityType = 'locality'; // City type
  
  // User 10km away from city center
  const double distantUserLat = 37.8749;
  const double distantUserLon = -122.4194;
  
  final isInCityRange = PlaceGeofenceUtils.isUserInRange(
    userLatitude: distantUserLat,
    userLongitude: distantUserLon,
    placeLatitude: cityCenterLat,
    placeLongitude: cityCenterLon,
    placeType: cityType,
  );
  print('User in city range: $isInCityRange'); // true (15km radius for cities)
  
  // Example 3: Get the radius for different place types
  
  final restaurantRadius = PlaceGeofenceUtils.getRadiusForPlaceType('restaurant');
  print('Restaurant geofence radius: $restaurantRadius meters'); // 500m
  
  final cityRadius = PlaceGeofenceUtils.getRadiusForPlaceType('locality');
  print('City geofence radius: $cityRadius meters'); // 15000m (15km)
  
  final stateRadius = PlaceGeofenceUtils.getRadiusForPlaceType('administrative_area_level_1');
  print('State geofence radius: $stateRadius meters'); // 200000m (200km)
  
  final countryRadius = PlaceGeofenceUtils.getRadiusForPlaceType('country');
  print('Country geofence radius: $countryRadius meters'); // 500000m (500km)
  
  // Example 4: Get human-readable radius descriptions
  
  final restaurantDesc = PlaceGeofenceUtils.getRadiusDescription('restaurant');
  print('Restaurant range: $restaurantDesc'); // "500 m"
  
  final cityDesc = PlaceGeofenceUtils.getRadiusDescription('locality');
  print('City range: $cityDesc'); // "15 km"
  
  final stateDesc = PlaceGeofenceUtils.getRadiusDescription('administrative_area_level_1');
  print('State range: $stateDesc'); // "200 km"
  
  // Example 5: Get place categories
  
  final restaurantCategory = PlaceGeofenceUtils.getPlaceCategory('restaurant');
  print('Restaurant category: $restaurantCategory'); // "establishment"
  
  final cityCategory = PlaceGeofenceUtils.getPlaceCategory('locality');
  print('City category: $cityCategory'); // "city"
  
  final neighborhoodCategory = PlaceGeofenceUtils.getPlaceCategory('neighborhood');
  print('Neighborhood category: $neighborhoodCategory'); // "neighborhood"
  
  // Example 6: Calculate distance between two points
  
  const double point1Lat = 37.7749; // San Francisco
  const double point1Lon = -122.4194;
  const double point2Lat = 37.3382; // San Jose
  const double point2Lon = -121.8863;
  
  final distance = PlaceGeofenceUtils.calculateDistance(
    point1Lat,
    point1Lon,
    point2Lat,
    point2Lon,
  );
  print('Distance SF to San Jose: ${(distance / 1000).toStringAsFixed(1)} km'); // ~68 km
  
  // Example 7: Real-world usage in a chat app
  
  void checkIfUserCanChatInPlace({
    required double userLat,
    required double userLon,
    required double placeLat,
    required double placeLon,
    required String? placeType,
    required String placeName,
  }) {
    final isInRange = PlaceGeofenceUtils.isUserInRange(
      userLatitude: userLat,
      userLongitude: userLon,
      placeLatitude: placeLat,
      placeLongitude: placeLon,
      placeType: placeType,
    );
    
    if (isInRange) {
      final rangeDesc = PlaceGeofenceUtils.getRadiusDescription(placeType);
      print('✅ You can chat in $placeName (within $rangeDesc range)');
    } else {
      final rangeDesc = PlaceGeofenceUtils.getRadiusDescription(placeType);
      final distance = PlaceGeofenceUtils.calculateDistance(
        userLat,
        userLon,
        placeLat,
        placeLon,
      );
      print('❌ You are too far from $placeName');
      print('   Distance: ${(distance / 1000).toStringAsFixed(1)} km');
      print('   Required range: $rangeDesc');
    }
  }
  
  // Example usage: User trying to chat in a restaurant
  checkIfUserCanChatInPlace(
    userLat: userLat,
    userLon: userLon,
    placeLat: restaurantLat,
    placeLon: restaurantLon,
    placeType: restaurantType,
    placeName: 'Local Pizza Place',
  );
  
  // Example usage: User trying to chat in San Francisco
  checkIfUserCanChatInPlace(
    userLat: userLat,
    userLon: userLon,
    placeLat: cityCenterLat,
    placeLon: cityCenterLon,
    placeType: cityType,
    placeName: 'San Francisco',
  );
}

/// Integration example with MaypoleMetaData
void exampleWithMaypoleMetaData() {
  // Assuming you have a MaypoleMetaData object with place information:
  // final maypole = MaypoleMetaData(
  //   id: 'place_id',
  //   name: 'Central Park',
  //   address: 'New York, NY',
  //   latitude: 40.785091,
  //   longitude: -73.968285,
  //   placeType: 'park',
  // );
  
  // Check if user can access this maypole:
  // final canAccess = PlaceGeofenceUtils.isUserInRange(
  //   userLatitude: currentUserLat,
  //   userLongitude: currentUserLon,
  //   placeLatitude: maypole.latitude!,
  //   placeLongitude: maypole.longitude!,
  //   placeType: maypole.placeType,
  // );
  
  // Display appropriate UI based on range:
  // if (canAccess) {
  //   // Show chat interface
  // } else {
  //   final requiredRange = PlaceGeofenceUtils.getRadiusDescription(maypole.placeType);
  //   // Show "You must be within $requiredRange to chat here"
  // }
}

/// Geofence Hierarchy Overview:
/// 
/// Place Type                         | Radius    | Use Case
/// -----------------------------------|-----------|------------------------------------------
/// country, continent                 | 500 km    | National/continental discussions
/// administrative_area_level_1        | 200 km    | State/province-wide topics
/// administrative_area_level_2        | 75 km     | County/regional discussions
/// administrative_area_level_3/4      | 30 km     | District-level conversations
/// locality, postal_town              | 15 km     | City-wide community
/// neighborhood, sublocality          | 5 km      | Neighborhood discussions
/// route, intersection                | 2 km      | Street-level conversations
/// establishment, restaurant, etc.    | 500 m     | Specific venue discussions
/// premise, street_address            | 200 m     | Building/address-specific chats
/// unknown/default                    | 1 km      | Default fallback
