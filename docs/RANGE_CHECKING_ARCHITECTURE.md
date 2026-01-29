# Range Checking Architecture

This document describes the location and flow of range checking logic in the Maypole app.

## Architecture Overview

The range checking system is organized in three layers:

```
PlaceGeofenceUtils (Core Logic)
         ↓
LocationService (Location Management)
         ↓
MaypoleChatContent (UI Logic)
```

## 1. Core Logic Layer: PlaceGeofenceUtils

**Location**: `lib/core/utils/place_geofence_utils.dart`

This is the **single source of truth** for all geofencing and distance calculations.

### Key Methods

#### Distance Calculation
```dart
static double calculateDistance(
  double lat1, double lon1,
  double lat2, double lon2,
) // Returns meters
```
- Uses Haversine formula
- Returns distance in meters between two coordinates

#### Dynamic Radius Based on Place Type
```dart
static double getRadiusForPlaceType(String? placeType)
```
- Returns appropriate geofence radius for a place type:
  - Countries: 500 km
  - States: 200 km
  - Cities: 15 km
  - Neighborhoods: 5 km
  - Establishments: 500 m
  - Buildings: 200 m

#### Range Checking with Coordinates
```dart
static bool isUserInRange({
  required double userLatitude,
  required double userLongitude,
  required double placeLatitude,
  required double placeLongitude,
  String? placeType,
})
```
- Checks if user coordinates are within the place's geofence
- Uses place type to determine appropriate radius

#### Range Checking with Position Objects
```dart
static bool? isPositionInRange({
  required Position? position,
  required double placeLatitude,
  required double placeLongitude,
  String? placeType,
})
```
- Works with Geolocator Position objects
- Returns null if position is null
- Delegates to `isUserInRange()` internally

#### Fixed Threshold Proximity Check
```dart
static bool? isPositionWithinProximity({
  required Position? position,
  required double targetLat,
  required double targetLon,
  required double threshold,
})
```
- For backward compatibility with fixed thresholds
- Used by "Show When at Location" feature (100m)

#### Distance Helper
```dart
static double? getDistanceToPlace({
  required Position? position,
  required double placeLatitude,
  required double placeLongitude,
})
```
- Returns distance from position to place
- Returns null if position is null

#### UI Helpers
```dart
static String getRadiusDescription(String? placeType) // "500 m", "15 km"
static String getPlaceCategory(String? placeType)     // "city", "establishment"
```

---

## 2. Location Management Layer: LocationService

**Location**: `lib/core/services/location_service.dart`

Handles location permissions, GPS, and delegates calculations to PlaceGeofenceUtils.

### Key Methods

#### Get Current Position
```dart
Future<Position?> getCurrentPosition()
```
- Checks permissions
- Fetches GPS location
- Caches last known position

#### Fixed Proximity Check (100m threshold)
```dart
bool? isPositionWithinProximity({
  required double targetLat,
  required double targetLon,
  Position? position,
  double? customThreshold,
})
```
- Delegates to `PlaceGeofenceUtils.isPositionWithinProximity()`
- Defaults to 100m threshold
- Used for "Show When at Location" feature

#### Dynamic Place-Type-Based Range Check
```dart
bool? isPositionInRangeOfPlace({
  required double placeLatitude,
  required double placeLongitude,
  Position? position,
  String? placeType,
})
```
- **NEW METHOD** - Delegates to `PlaceGeofenceUtils.isPositionInRange()`
- Uses dynamic radius based on place type
- Recommended for maypole chat access control

#### Async Versions
```dart
Future<bool?> isWithinProximity({...})     // Fixed threshold
Future<bool?> isInRangeOfPlace({...})      // Dynamic range
```
- Fetch current position first, then check range

#### Distance Calculation
```dart
double calculateDistance(...)
Future<double?> getDistanceToLocation({...})
```
- Delegates to PlaceGeofenceUtils
- Async version fetches current position first

---

## 3. UI Logic Layer: MaypoleChatContent

**Location**: `lib/features/maypolechat/presentation/widgets/maypole_chat_content.dart`

Implements range checking for the maypole chat UI.

### Properties

```dart
final String? placeType;  // Place type from Google Places API
Position? _currentPosition;  // User's current location
```

### Range Check Getters

#### Fixed Proximity Check (100m)
```dart
bool get _isWithinProximity
```
- **Used for**: "Show When at Location" feature
- **Threshold**: Fixed 100 meters
- **Checks**: 
  1. Feature enabled in settings
  2. Has place coordinates
  3. Has current position
  4. Within 100m of place
- Calls `locationService.isPositionWithinProximity()`

#### Dynamic Place-Type-Based Range Check
```dart
bool get _isWithinPlaceRange
```
- **NEW GETTER** - Uses place type for dynamic geofencing
- **Threshold**: Based on place type (see table below)
- **Checks**:
  1. Has place coordinates
  2. Has current position
  3. Within place's geofence radius
- Calls `locationService.isPositionInRangeOfPlace()`
- Logs distance and radius for debugging

### Usage Examples in UI

#### Current Usage (Fixed 100m)
```dart
// For "Show When at Location" feature
if (_isWithinProximity) {
  // Show badge or special UI
}

// For image uploads
if (_canUploadImage) {
  // Enable image upload button
}
```

#### New Usage (Dynamic Range)
```dart
// For chat access control
if (!_isWithinPlaceRange) {
  // Show "You must be within X km/m to chat here"
  // Where X is determined by place type
}

// For sending messages
if (_isWithinPlaceRange) {
  // Allow message to be sent
} else {
  // Show out-of-range error
}
```

---

## Range Thresholds by Place Type

| Place Type | Radius | Category | Example Use Case |
|------------|--------|----------|------------------|
| `country`, `continent` | 500 km | Country | National discussions |
| `administrative_area_level_1` | 200 km | State | State-wide topics |
| `administrative_area_level_2` | 75 km | County | Regional discussions |
| `administrative_area_level_3/4` | 30 km | Administrative | District-level |
| `locality`, `postal_town` | 15 km | City | City-wide community |
| `neighborhood`, `sublocality_*` | 5 km | Neighborhood | Local area chats |
| `route`, `intersection` | 2 km | Street | Street-level |
| `restaurant`, `store`, etc. | 500 m | Establishment | Venue discussions |
| `premise`, `street_address` | 200 m | Premise | Building-specific |
| *unknown/default* | 1 km | Default | Fallback |

---

## Data Flow Examples

### Example 1: User Opens Maypole Chat

```
1. User searches for "Central Park" (type: park)
2. MaypoleSearchService fetches place details with primaryType
3. PlacePrediction created with placeType="park"
4. User navigates to chat
5. MaypoleChatContent receives placeType prop
6. On init: _updateCurrentPosition() fetches GPS location
7. _isWithinPlaceRange checks:
   - Gets radius for "park" → 500m
   - Calculates distance from user to park
   - Returns true if distance ≤ 500m
```

### Example 2: User Tries to Send Message

```
1. User types message
2. User taps send button
3. (Future enhancement) Check _isWithinPlaceRange
4. If false:
   - Get radius: PlaceGeofenceUtils.getRadiusDescription("park") → "500 m"
   - Show error: "You must be within 500 m to chat here"
   - Get distance: PlaceGeofenceUtils.getDistanceToPlace() → "1,200 m"
   - Show: "You are 1,200 m away"
5. If true:
   - Send message with placeType
```

### Example 3: Checking Multiple Places

```dart
// Check if user can access any nearby maypoles
final userPosition = await locationService.getCurrentPosition();

for (final maypole in maypoles) {
  final canAccess = PlaceGeofenceUtils.isPositionInRange(
    position: userPosition,
    placeLatitude: maypole.latitude!,
    placeLongitude: maypole.longitude!,
    placeType: maypole.placeType,
  );
  
  if (canAccess == true) {
    // Show this maypole as accessible
  }
}
```

---

## Migration Path

### Phase 1: ✅ COMPLETE
- PlaceGeofenceUtils implemented with all core methods
- LocationService delegates to PlaceGeofenceUtils
- placeType added to all data models
- placeType persisted to Firebase

### Phase 2: CURRENT
- `_isWithinPlaceRange` getter added to MaypoleChatContent
- Both fixed (100m) and dynamic range checking available

### Phase 3: TODO
- Replace `_isWithinProximity` with `_isWithinPlaceRange` for chat access
- Show range information in UI ("You must be within X km")
- Add range violation error messages
- Show user's distance from place
- Add range indicator on map

---

## Testing

See `lib/core/utils/place_geofence_utils_example.dart` for comprehensive usage examples and test cases.

---

## Key Takeaways

1. **All geofencing logic is in PlaceGeofenceUtils** - single source of truth
2. **LocationService is a thin wrapper** - handles GPS, delegates calculations
3. **MaypoleChatContent has two getters**:
   - `_isWithinProximity` - Fixed 100m for "Show When at Location"
   - `_isWithinPlaceRange` - Dynamic range based on place type
4. **Use `_isWithinPlaceRange` for chat access control** - respects place hierarchy
5. **Always pass placeType** for accurate range checking
