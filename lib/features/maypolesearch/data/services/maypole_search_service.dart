import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/app_config.dart';
import '../models/autocomplete_request.dart';
import '../models/autocomplete_response.dart';

class MaypoleSearchService {
  final String _apiKey = AppConfig.googlePlacesApiKey;

  // Use Cloud Function for web (required due to CORS), direct API for mobile
  String get _baseUrl {
    if (kIsWeb) {
      // Use Cloud Function to avoid CORS issues with Places API (New)
      return AppConfig.cloudFunctionsUrl;
    }
    return 'https://places.googleapis.com/v1/places:autocomplete';
  }

  /// Fetch place details including coordinates and place type
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    debugPrint('📍 Fetching Place Details for: $placeId');
    
    // Use Cloud Function for web to avoid CORS and referrer issues
    final String url;
    final Map<String, String> headers;
    
    if (kIsWeb) {
      url = AppConfig.cloudFunctionsPlaceDetailsUrl;
      // Cloud Function uses Secret Manager - don't send API key from client
      headers = {
        'Content-Type': 'application/json',
        'X-Place-Id': placeId,
      };
    } else {
      url = 'https://places.googleapis.com/v1/places/$placeId';
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,primaryType,types',
      };
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 Place Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint("✅ Place Details Response: ${response.body.substring(
            0, response.body.length > 200 ? 200 : response.body.length)}...");
        
        // Parse the response to extract coordinates and place type
        final Map<String, dynamic> data = json.decode(response.body);
        
        return data;
      } else {
        debugPrint('❌ Error Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Exception during place details fetch: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to get nearest place details.
  /// Returns the best match place and its distance from the tap point in meters.
  Future<Map<String, dynamic>?> reverseGeocode(
    double latitude,
    double longitude, {
    double radiusMeters = 150,
    int maxResultCount = 5,
  }) async {
    debugPrint('🗺️ Reverse geocoding: lat=$latitude, lon=$longitude, radius=$radiusMeters, maxResults=$maxResultCount');
    
    // Use Cloud Function for web to avoid CORS and referrer issues
    final String url;
    final Map<String, String> headers;
    final String? body;
    
    if (kIsWeb) {
      url = AppConfig.cloudFunctionsReverseGeocodeUrl;
      // Cloud Function uses Secret Manager - don't send API key from client
      headers = {
        'Content-Type': 'application/json',
      };
      body = json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'maxResultCount': maxResultCount,
      });
    } else {
      url = 'https://places.googleapis.com/v1/places:searchNearby';
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types',
      };
      body = json.encode({
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': radiusMeters,
          }
        },
        'maxResultCount': maxResultCount,
        'rankPreference': 'DISTANCE',
      });
    }

    try {
      debugPrint('📤 Reverse Geocode Request URL: $url');
      debugPrint('📤 Reverse Geocode Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      debugPrint('📡 Reverse Geocode Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint("✅ Reverse Geocode Response: ${response.body.substring(
            0, response.body.length > 200 ? 200 : response.body.length)}...");
        
        final Map<String, dynamic> data = json.decode(response.body);
        final places = data['places'] as List<dynamic>?;

        if (places == null || places.isEmpty) {
          return null;
        }

        Map<String, dynamic>? bestPlace;
        var bestDistance = double.infinity;

        for (final item in places) {
          if (item is! Map<String, dynamic>) continue;
          final location = item['location'] as Map<String, dynamic>?;
          final placeLat = location?['latitude'] as double?;
          final placeLon = location?['longitude'] as double?;
          if (placeLat == null || placeLon == null) continue;

          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            placeLat,
            placeLon,
          );

          if (distance < bestDistance) {
            bestDistance = distance;
            bestPlace = item;
          }
        }

        if (bestPlace == null) {
          return null;
        }

        return {
          ...bestPlace,
          '_distanceMeters': bestDistance,
        };
      } else {
        debugPrint('❌ Error Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Exception during reverse geocode: $e');
      return null;
    }
  }

  Future<AutocompleteResponse> autocomplete(AutocompleteRequest request) async {
    debugPrint('🔍 Places Autocomplete Request - START');
    debugPrint('  URL: $_baseUrl');
    debugPrint('  kIsWeb: $kIsWeb');
    
    // Build headers based on platform
    Map<String, String> headers;
    
    if (kIsWeb) {
      debugPrint('  Platform: Web (Cloud Function) - building headers...');
      // Cloud Function uses Secret Manager - don't send API key from client
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      };
      debugPrint('  Headers built for Cloud Function (no API key - uses Secret Manager)');
    } else {
      debugPrint('  Platform: Mobile (Direct API)');
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      };
      debugPrint('  Headers built with API key for direct API');
    }

    try {
      final body = request.toJson();
      debugPrint('📤 Request body: $body');
      debugPrint('📤 Sending POST to: $_baseUrl');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      debugPrint('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Got 200 response, parsing...');
        return AutocompleteResponse.fromJson(response.body);
      } else {
        debugPrint('❌ Error Response (${response.statusCode}): ${response.body}');
        throw Exception('Failed to load predictions (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 Exception during autocomplete: $e');
      debugPrint('💥 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
