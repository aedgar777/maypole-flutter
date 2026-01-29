# Sublocality vs Neighborhood Range Update

## Problem Identified

Manhattan was being given a **1km radius** (the default) instead of an appropriate range. Investigation revealed:

1. **Manhattan's place types**: `['sublocality_level_1', 'sublocality', 'political']`
2. **Manhattan's actual size**: ~21.5 km long, ~3.7 km wide
3. **Issue**: Getting default 1km radius suggests `primaryType` was `null` or not matching

## Root Cause

Two issues were identified:

### 1. No Distinction Between Sublocalities and Neighborhoods

**Sublocality** (like Manhattan, Brooklyn):
- Major subdivisions of cities (boroughs, districts)
- Size: 10-20+ km across
- Examples: Manhattan (NYC), Brooklyn (NYC), Westminster (London)

**Neighborhood** (like SoHo, Upper East Side):
- Smaller areas within sublocalities or cities
- Size: 1-3 km across
- Examples: SoHo (Manhattan), Upper East Side (Manhattan), Tribeca

**Previous behavior**: Both got 5 km radius - too small for boroughs, possibly too large for small neighborhoods.

### 2. No Fallback for Missing primaryType

If Google Places API doesn't return a `primaryType` (or it's null), we had no fallback to check the `types` array, resulting in the default 1km radius.

## Solution

### 1. Split Sublocality and Neighborhood Ranges

**New constants:**
```dart
static const double _sublocalityRadius = 10000.0;  // 10 km for boroughs
static const double _neighborhoodRadius = 3000.0;  // 3 km for neighborhoods
```

**Updated switch cases:**
```dart
// Sublocalities (boroughs, major districts)
case 'sublocality':
case 'sublocality_level_1':
  return _sublocalityRadius;  // 10 km

// Neighborhoods and smaller sublocalities
case 'neighborhood':
case 'sublocality_level_2':
case 'sublocality_level_3':
case 'sublocality_level_4':
case 'sublocality_level_5':
case 'colloquial_area':
  return _neighborhoodRadius;  // 3 km
```

### 2. Added Fallback to types Array

**New logic in `getRadiusForPlaceType()`:**
```dart
static double getRadiusForPlaceType(String? placeType, {List<String>? types}) {
  // If no primary type, try to find the best match from types array
  if ((placeType == null || placeType.isEmpty) && types != null) {
    const priorityOrder = [
      'sublocality_level_1',  // Most specific first
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
  
  // ... rest of logic
}
```

### 3. Updated All Related Methods

Added optional `types` parameter to:
- `getRadiusForPlaceType(String? placeType, {List<String>? types})`
- `isUserInRange(..., String? placeType, List<String>? types)`
- `getRadiusDescription(String? placeType, {List<String>? types})`
- `getPlaceCategory(String? placeType, {List<String>? types})`

### 4. Updated Category System

Added new category for better organization:
```dart
if (placeType == 'sublocality' || placeType == 'sublocality_level_1') {
  return 'sublocality';  // New category
}

// Falls through to 'neighborhood' for smaller divisions
```

## Updated Geofence Hierarchy

| Place Type | Range | Category | Example |
|------------|-------|----------|---------|
| **Country/Continent** | 500 km | country | USA, Europe |
| **State/Province** | 200 km | state | California, Ontario |
| **County** | 75 km | county | Los Angeles County |
| **City/Locality** | 15 km | city | San Francisco, NYC |
| **Sublocality/Borough** | **10 km** | **sublocality** | **Manhattan, Brooklyn** |
| **Neighborhood** | **3 km** | neighborhood | SoHo, Upper East Side |
| **Street** | 2 km | street | Broadway |
| **Restaurant/Store** | 500 m | establishment | Joe's Pizza |
| **Building** | 200 m | premise | Empire State Building |

## Manhattan Example

### Before
- **Types**: `['sublocality_level_1', 'sublocality', 'political']`
- **Primary Type**: (possibly null)
- **Radius**: 1 km (default) ❌
- **Result**: Users couldn't chat/upload from most of Manhattan

### After
- **Types**: `['sublocality_level_1', 'sublocality', 'political']`
- **Primary Type**: `'sublocality_level_1'` OR falls back to types array
- **Radius**: 10 km ✅
- **Result**: Users anywhere in Manhattan can participate

### Range Justification
- Manhattan is ~21.5 km long and ~3.7 km wide
- 10 km radius from center covers most of the borough
- Appropriate for a major urban subdivision

## Other Examples

### SoHo (Neighborhood in Manhattan)
- **Type**: `'neighborhood'`
- **Radius**: 3 km
- **Justification**: Small neighborhood, ~1-2 km across

### Brooklyn (Borough)
- **Type**: `'sublocality_level_1'`
- **Radius**: 10 km
- **Justification**: Major borough, similar size to Manhattan

### New York City (City)
- **Type**: `'locality'`
- **Radius**: 15 km
- **Justification**: Covers the general metro area

## Benefits

✅ **Manhattan now works properly** - 10 km range appropriate for borough size  
✅ **Distinction between borough and neighborhood** - More intuitive ranges  
✅ **Fallback for missing primaryType** - Uses types array as backup  
✅ **Better category system** - Can differentiate sublocality from neighborhood  
✅ **Backward compatible** - Optional `types` parameter, existing code still works  

## Migration Notes

### For Developers

The `types` parameter is **optional**. Existing code continues to work:

```dart
// Still works
final radius = PlaceGeofenceUtils.getRadiusForPlaceType('sublocality_level_1');

// Enhanced fallback
final radius = PlaceGeofenceUtils.getRadiusForPlaceType(
  primaryType,  // Might be null
  types: typesArray,  // Fallback if primaryType is null
);
```

### Future Enhancement

Consider storing both `primaryType` and `types` array in:
- `MaypoleMetaData`
- `PlacePrediction`

This would provide the most reliable range detection.

## Testing

Test cases to verify:

1. **Manhattan (sublocality_level_1)**
   - Expected: 10 km radius
   - Verify: Users in Manhattan can upload images

2. **SoHo (neighborhood)**
   - Expected: 3 km radius
   - Verify: Smaller range than Manhattan

3. **Missing primaryType**
   - Types: `['sublocality_level_1', 'political']`
   - Expected: Falls back to 'sublocality_level_1', gets 10 km

4. **Political only**
   - Types: `['political']`
   - Expected: Falls back to 'political', gets 15 km (city range)

## Files Modified

1. `lib/core/utils/place_geofence_utils.dart`
   - Split `_neighborhoodRadius` into `_sublocalityRadius` (10km) and `_neighborhoodRadius` (3km)
   - Updated switch cases to distinguish sublocality from neighborhood
   - Added `types` parameter to all relevant methods
   - Added fallback logic to check types array
   - Updated `getPlaceCategory()` to return 'sublocality' category

## Summary

Manhattan (and similar boroughs) now gets an appropriate **10 km range** instead of 1 km, making the feature actually usable. The system also gained a fallback mechanism to handle cases where `primaryType` is missing, and can now distinguish between major subdivisions (boroughs) and smaller neighborhoods.
