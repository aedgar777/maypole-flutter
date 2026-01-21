import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Fetch place details including coordinates
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    debugPrint('📍 Fetching Place Details for: $placeId');
    
    // Use direct Google API for all platforms (less frequent, CORS should work with proper key setup)
    final url = 'https://places.googleapis.com/v1/places/$placeId';
    
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('📡 Place Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint("✅ Place Details Response: ${response.body.substring(
            0, response.body.length > 200 ? 200 : response.body.length)}...");
        
        // Parse the response to extract coordinates
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

  /// Reverse geocode coordinates to get place details
  Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude) async {
    debugPrint('🗺️ Reverse geocoding: lat=$latitude, lon=$longitude');
    
    // Use direct Google API for all platforms (less frequent, CORS should work with proper key setup)
    final url = 'https://places.googleapis.com/v1/places:searchNearby';
    
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
    };

    final body = json.encode({
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': 50.0, // Search within 50 meters
        }
      },
      'maxResultCount': 1,
    });

    try {
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
        
        if (places != null && places.isNotEmpty) {
          return places[0] as Map<String, dynamic>;
        }
        
        return null;
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
    debugPrint('🔍 Places Autocomplete Request');
    debugPrint('  URL: $_baseUrl');
    debugPrint('  Platform: ${kIsWeb ? "Web (Cloud Function)" : "Mobile (Direct API)"}');
    
    // For web, we use the mobile API key (not the web key) because the Cloud Function
    // makes server-side calls to Google. The web key is only for Maps JavaScript API.
    final apiKeyToUse = kIsWeb 
        ? (AppConfig.isProduction 
            ? dotenv.env['GOOGLE_PLACES_PROD_API_KEY'] ?? _apiKey
            : dotenv.env['GOOGLE_PLACES_DEV_API_KEY'] ?? _apiKey)
        : _apiKey;
    
    debugPrint('  API Key: ${apiKeyToUse.isNotEmpty ? "✓ Present (${apiKeyToUse.substring(0, 10)}...)" : "✗ Missing"}');

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKeyToUse,
      'X-Goog-Field-Mask':
          'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
    };

    try {
      debugPrint('📤 Sending request to: $_baseUrl');
      debugPrint('📤 Request headers: $headers');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: request.toJson(),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📡 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Check if response is JSON
        final contentType = response.headers['content-type'];
        if (contentType != null && !contentType.contains('application/json')) {
          debugPrint('❌ Unexpected content type: $contentType');
          debugPrint('❌ Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          throw Exception('Server returned non-JSON response. Content-Type: $contentType');
        }
        
        debugPrint("✅ Place Response: ${response.body.substring(
            0, response.body.length > 200 ? 200 : response.body.length)}...");
        return AutocompleteResponse.fromJson(response.body);
      } else {
        debugPrint('❌ Error Response (${response.statusCode}): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        throw Exception(
            'Failed to load predictions (${response.statusCode}): ${response
                .body}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 Exception during autocomplete: $e');
      debugPrint('💥 Stack trace: $stackTrace');
      
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        throw Exception(
            'Network error: Unable to reach server. This may be due to:\n'
            '1. CORS restrictions\n'
            '2. localhost not being in allowed websites\n'
            '3. Network connectivity issues\n\n'
            'Try adding http://localhost:* to your API key website restrictions for local testing.');
      }
      rethrow;
    }
  }
}
