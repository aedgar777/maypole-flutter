import 'dart:convert';
import 'package:flutter/foundation.dart';

class AutocompleteResponse {
  final List<PlacePrediction> predictions;

  AutocompleteResponse({required this.predictions});

  factory AutocompleteResponse.fromMap(Map<String, dynamic> map) {
    // Handle Cloud Function response format - may be wrapped differently
    List<dynamic>? suggestions;
    
    if (map.containsKey('suggestions')) {
      // Direct Google Places API format
      suggestions = map['suggestions'] as List<dynamic>?;
    } else if (map.containsKey('predictions')) {
      // Alternative format
      suggestions = map['predictions'] as List<dynamic>?;
    } else if (map.containsKey('results')) {
      // Another possible format
      suggestions = map['results'] as List<dynamic>?;
    } else if (map.length == 1) {
      // Maybe wrapped in a single key
      final firstValue = map.values.first;
      if (firstValue is Map<String, dynamic>) {
        if (firstValue.containsKey('suggestions')) {
          suggestions = firstValue['suggestions'] as List<dynamic>?;
        }
      }
    }
    
    final predictions = suggestions
            ?.map((e) {
              if (e is Map<String, dynamic>) {
                return PlacePrediction.fromMap(e);
              }
              return null;
            })
            .where((p) => p != null)
            .cast<PlacePrediction>()
            .toList() ??
        [];
    
    return AutocompleteResponse(predictions: predictions);
  }

  factory AutocompleteResponse.fromJson(String source) {
    try {
      final decoded = json.decode(source);
      if (decoded is Map<String, dynamic>) {
        return AutocompleteResponse.fromMap(decoded);
      } else {
        throw Exception('Invalid response format: expected JSON object');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class PlacePrediction {
  final String place; // Full text (business name + address) for display in search
  final String placeName; // Just the business name for the chat screen
  final String placeId;
  final String address; // Secondary text (address) from structured format
  final double? latitude; // Place latitude
  final double? longitude; // Place longitude
  final String? placeType; // Primary type from Google Places API

  PlacePrediction({
    required this.place,
    required this.placeName,
    required this.placeId,
    this.address = '',
    this.latitude,
    this.longitude,
    this.placeType,
  });

  factory PlacePrediction.fromMap(Map<String, dynamic> map) {
    final prediction = map['placePrediction'] as Map<String, dynamic>?;
    final structuredFormat =
        prediction?['structuredFormat'] as Map<String, dynamic>?;

    return PlacePrediction(
      place: prediction?['text']?['text'] as String? ?? '',
      placeName:
          structuredFormat?['mainText']?['text'] as String? ??
          prediction?['text']?['text'] as String? ?? '',
      placeId: prediction?['placeId'] as String? ?? '',
      address: structuredFormat?['secondaryText']?['text'] as String? ?? '',
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      placeType: map['placeType'] as String?,
    );
  }
  
  /// Create a copy with updated coordinates and/or place type
  PlacePrediction copyWith({
    String? place,
    String? placeName,
    String? placeId,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) {
    return PlacePrediction(
      place: place ?? this.place,
      placeName: placeName ?? this.placeName,
      placeId: placeId ?? this.placeId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeType: placeType ?? this.placeType,
    );
  }

  factory PlacePrediction.fromJson(String source) =>
      PlacePrediction.fromMap(json.decode(source));
}
