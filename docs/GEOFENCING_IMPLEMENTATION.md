# Geofencing Implementation for Place-Based Ranges

This document describes the implementation of dynamic geofencing based on place types in the Maypole Flutter app.

## Overview

The geofencing system automatically adjusts the chat range based on the type of place. Larger geographic entities (countries, states) have larger ranges, while specific establishments (restaurants, stores) have smaller, more focused ranges.

## Key Components

### 1. PlaceGeofenceUtils (`lib/core/utils/place_geofence_utils.dart`)

A utility class that provides:
- **Dynamic radius calculation** based on place type
- **Range checking** to determine if a user is within a place's geofence
- **Distance calculation** using the Haversine formula
- **Human-readable descriptions** for UI display
- **Place categorization** for grouping and filtering

#### Geofence Hierarchy

| Place Type | Radius | Example Use Case |
|------------|--------|------------------|
| Country/Continent | 500 km | National discussions |
| State/Province (admin_level_1) | 200 km | State-wide topics |
| County (admin_level_2) | 75 km | Regional discussions |
| City/Locality | 15 km | City-wide community |
| Neighborhood | 5 km | Neighborhood chats |
| Street/Route | 2 km | Street-level conversations |
| Restaurant/Store/etc. | 500 m | Specific venue discussions |
| Building/Address | 200 m | Building-specific chats |

### 2. Updated Data Models

#### MaypoleMetaData (`lib/features/maypolechat/domain/maypole.dart`)
- Added `placeType` field to store the Google Places API primary type
- Updated `fromMap()` and `toMap()` to serialize/deserialize placeType
- Updated constructor to accept optional placeType parameter

#### PlacePrediction (`lib/features/maypolesearch/data/models/autocomplete_response.dart`)
- Added `placeType` field
- Updated `fromMap()` to parse placeType from place details
- Updated `copyWith()` to support updating placeType

### 3. Updated Services

#### MaypoleSearchService (`lib/features/maypolesearch/data/services/maypole_search_service.dart`)
- Updated `getPlaceDetails()` field mask to include: `primaryType,types`
- Updated `reverseGeocode()` field mask to include: `primaryType,types`
- These methods now return place type information from Google Places API

#### MaypoleChatService (`lib/features/maypolechat/data/maypole_chat_service.dart`)
- Updated `sendMessage()` to accept and store `placeType`
- Updated `sendMaypoleMessage()` to accept and store `placeType`
- Updated `addMaypoleToUserList()` to accept and store `placeType`
- All methods now persist placeType to Firebase

### 4. Updated UI Components

#### MaypoleSearchScreen (`lib/features/maypolesearch/presentation/screens/maypole_search_screen.dart`)
- `_fetchPlaceDetailsAndReturn()` extracts `primaryType` from place details
- `_buildBottomSheet()` extracts `primaryType` for reverse geocoded places
- `_navigateToChat()` passes `placeType` to PlacePrediction

#### HomeScreen (`lib/features/home/presentation/screens/home_screen.dart`)
- `_handleAddPressed()` passes `placeType` when adding maypole to user list
- Navigation to chat screen includes `placeType` in extra data

#### MaypoleChatContent (`lib/features/maypolechat/presentation/widgets/maypole_chat_content.dart`)
- Added `placeType` as a widget property
- Passes `placeType` when sending messages

#### MaypoleChatViewModel (`lib/features/maypolechat/presentation/viewmodels/maypole_chat_view_model.dart`)
- Updated `sendMessage()` to accept and forward `placeType` parameter

## Usage Examples

### Check if User is in Range

```dart
import 'package:maypole/core/utils/place_geofence_utils.dart';

// Check if user can chat at a location
final canChat = PlaceGeofenceUtils.isUserInRange(
  userLatitude: userLat,
  userLongitude: userLon,
  placeLatitude: maypole.latitude!,
  placeLongitude: maypole.longitude!,
  placeType: maypole.placeType,
);

if (canChat) {
  // User is within range, allow chatting
} else {
  // User is out of range, show appropriate message
}
```

### Get Range Information

```dart
// Get the geofence radius in meters
final radius = PlaceGeofenceUtils.getRadiusForPlaceType('restaurant');
print('Radius: $radius meters'); // 500

// Get human-readable description
final description = PlaceGeofenceUtils.getRadiusDescription('restaurant');
print('Range: $description'); // "500 m"

// Get place category for grouping
final category = PlaceGeofenceUtils.getPlaceCategory('restaurant');
print('Category: $category'); // "establishment"
```

### Calculate Distance

```dart
final distance = PlaceGeofenceUtils.calculateDistance(
  userLat,
  userLon,
  placeLat,
  placeLon,
);
print('Distance: ${(distance / 1000).toStringAsFixed(1)} km');
```

## Integration Flow

1. **User searches for a place**
   - Search screen displays autocomplete results
   - User selects a place

2. **Place details are fetched**
   - `MaypoleSearchService.getPlaceDetails()` fetches coordinates and `primaryType`
   - PlacePrediction object is created with placeType

3. **Place is selected/chat is opened**
   - placeType is passed through navigation
   - MaypoleChatContent widget receives placeType

4. **User sends a message**
   - Message is sent with placeType
   - MaypoleMetaData is created/updated with placeType
   - Data is persisted to Firebase with placeType

5. **Range checking (future feature)**
   - Use `PlaceGeofenceUtils.isUserInRange()` to validate user location
   - Show appropriate UI based on range status

## Firebase Data Structure

The placeType is now stored in two places:

### 1. Maypole Document (`maypoles/{placeId}`)
```json
{
  "id": "ChIJ...",
  "name": "Central Park",
  "address": "New York, NY",
  "latitude": 40.785091,
  "longitude": -73.968285,
  "placeType": "park"
}
```

### 2. User's Maypole List (`users/{userId}/maypoleChatThreads`)
```json
{
  "id": "ChIJ...",
  "name": "Central Park",
  "address": "New York, NY",
  "latitude": 40.785091,
  "longitude": -73.968285,
  "placeType": "park",
  "lastTypedAt": "2026-01-29T..."
}
```

## Future Enhancements

1. **Enforce Range Restrictions**
   - Add middleware to check user location before allowing messages
   - Show "Out of Range" UI when user is too far

2. **Visual Range Indicators**
   - Display geofence circle on map
   - Show user's distance from place center

3. **Smart Notifications**
   - Notify users when they enter a maypole's geofence
   - Suggest nearby maypoles based on location

4. **Analytics**
   - Track which place types are most popular
   - Analyze chat activity by place category

## Testing

See `lib/core/utils/place_geofence_utils_example.dart` for comprehensive usage examples.

## Notes

- All existing maypoles without placeType will continue to work (defaults to null)
- PlaceGeofenceUtils uses sensible defaults for unknown place types
- The system is backward compatible with existing data
- Place types come from the new Google Places API (v1)
