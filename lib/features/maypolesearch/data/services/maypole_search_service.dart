import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../../../core/app_config.dart';
import '../models/autocomplete_request.dart';
import '../models/autocomplete_response.dart';

class MaypoleSearchService {
  final String _apiKey = AppConfig.googlePlacesApiKey;

  // Use direct Google API for mobile (no CORS issues)
  // Use Cloud Function proxy for web (to avoid CORS issues)
  String get _baseUrl {
    if (kIsWeb) {
      // Web platform: use Cloud Function proxy to avoid CORS
      return '${AppConfig.cloudFunctionsUrl}/places_autocomplete';
    } else {
      // Mobile/Desktop platforms: call Google API directly for better performance
      return 'https://places.googleapis.com/v1/places:autocomplete';
    }
  }

  /// Fetch place details including coordinates
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    debugPrint('📍 Fetching Place Details for: $placeId');
    
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

  Future<AutocompleteResponse> autocomplete(AutocompleteRequest request) async {
    debugPrint('🔍 Places Autocomplete Request');
    debugPrint('  URL: $_baseUrl');
    debugPrint('  API Key: ${_apiKey.isNotEmpty ? "✓ Present" : "✗ Missing"}');
    debugPrint('  Cloud Functions URL: ${AppConfig.cloudFunctionsUrl}');

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-Field-Mask':
      'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: request.toJson(),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint("✅ Place Response: ${response.body.substring(
            0, response.body.length > 200 ? 200 : response.body.length)}...");
        return AutocompleteResponse.fromJson(response.body);
      } else {
        debugPrint('❌ Error Response: ${response.body}');
        throw Exception(
            'Failed to load predictions (${response.statusCode}): ${response
                .body}');
      }
    } catch (e) {
      debugPrint('💥 Exception during autocomplete: $e');
      rethrow;
    }
  }
}
