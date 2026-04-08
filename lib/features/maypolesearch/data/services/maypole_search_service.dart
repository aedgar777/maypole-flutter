import 'dart:convert';
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


      if (response.statusCode == 200) {
        
        // Parse the response to extract coordinates and place type
        final Map<String, dynamic> data = json.decode(response.body);
        
        return data;
      } else {
        return null;
      }
    } catch (e) {
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

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );


      if (response.statusCode == 200) {
        
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Search nearby places around a center point.
  Future<List<Map<String, dynamic>>> searchNearbyPlaces(
    double latitude,
    double longitude, {
    double radiusMeters = 300,
    int maxResultCount = 20,
  }) async {
    final String url;
    final Map<String, String> headers;
    final String body;

    if (kIsWeb) {
      url = AppConfig.cloudFunctionsReverseGeocodeUrl;
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
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types',
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
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        return const [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final places = data['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) {
        return const [];
      }

      final results = <Map<String, dynamic>>[];
      for (final item in places) {
        if (item is! Map<String, dynamic>) continue;
        final location = item['location'] as Map<String, dynamic>?;
        final placeLat = location?['latitude'] as double?;
        final placeLon = location?['longitude'] as double?;
        final placeId = item['id'] as String?;
        if (placeLat == null || placeLon == null || placeId == null || placeId.isEmpty) {
          continue;
        }

        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          placeLat,
          placeLon,
        );

        results.add({
          ...item,
          '_distanceMeters': distance,
        });
      }

      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<AutocompleteResponse> autocomplete(AutocompleteRequest request) async {
    // Build headers based on platform
    Map<String, String> headers;
    
    if (kIsWeb) {
      // Cloud Function uses Secret Manager - don't send API key from client
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      };
    } else {
      headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      };
    }

    try {
      final body = request.toJson();
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return AutocompleteResponse.fromJson(response.body);
      } else {
        throw Exception('Failed to load predictions (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
