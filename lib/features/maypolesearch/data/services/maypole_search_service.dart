import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/app_config.dart';
import '../models/autocomplete_request.dart';
import '../models/autocomplete_response.dart';

class MaypoleSearchService {
  // All platforms route Places (New) requests through Cloud Functions so the
  // API key stays server-side (in Secret Manager). This avoids CORS issues on
  // web and per-platform API key restriction issues on mobile (an API key can
  // only be restricted to one of Android OR iOS apps, never both).
  String get _baseUrl => AppConfig.cloudFunctionsUrl;

  /// Fetch place details including coordinates and place type
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    // Cloud Function uses Secret Manager - don't send API key from client
    final String url = AppConfig.cloudFunctionsPlaceDetailsUrl;
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Place-Id': placeId,
    };

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
        debugPrint('MaypoleSearchService: getPlaceDetails failed with status: ${response.statusCode}');
        debugPrint('MaypoleSearchService: Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      return null;
    }
  }

  /// Search for the nearest place around coordinates.
  /// Prefer `searchNearbyPlaces` plus map viewport/screen filtering for map taps,
  /// because this may return places that are near the coordinate but not visible.
  Future<Map<String, dynamic>?> reverseGeocode(
    double latitude,
    double longitude, {
    double radiusMeters = 150,
    int maxResultCount = 5,
  }) async {
    // Cloud Function uses Secret Manager - don't send API key from client.
    final String url = AppConfig.cloudFunctionsReverseGeocodeUrl;
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    final String body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'maxResultCount': maxResultCount,
    });

    try {
      debugPrint('MaypoleSearchService: reverseGeocode called at ($latitude, $longitude)');
      debugPrint('MaypoleSearchService: Environment: ${AppConfig.isProduction ? "PROD" : "DEV"}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final places = data['places'] as List<dynamic>?;

        debugPrint('MaypoleSearchService: Found ${places?.length ?? 0} places');

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

        debugPrint('MaypoleSearchService: Best match: ${bestPlace['displayName']?['text']} at ${bestDistance.toStringAsFixed(1)}m');

        return {
          ...bestPlace,
          '_distanceMeters': bestDistance,
        };
      } else {
        debugPrint('MaypoleSearchService: Error ${response.statusCode}');
        debugPrint('MaypoleSearchService: Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('MaypoleSearchService: Exception: $e');
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
    // Cloud Function uses Secret Manager - don't send API key from client.
    final String url = AppConfig.cloudFunctionsReverseGeocodeUrl;
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    final String body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'maxResultCount': maxResultCount,
    });

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
    // Cloud Function uses Secret Manager - don't send API key from client.
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
    };

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
