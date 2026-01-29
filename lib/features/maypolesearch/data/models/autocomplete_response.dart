import 'dart:convert';

class AutocompleteResponse {
  final List<PlacePrediction> predictions;

  AutocompleteResponse({required this.predictions});

  factory AutocompleteResponse.fromMap(Map<String, dynamic> map) {
    return AutocompleteResponse(
      predictions: (map['suggestions'] as List<dynamic>?)
              ?.map((e) => PlacePrediction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory AutocompleteResponse.fromJson(String source) =>
      AutocompleteResponse.fromMap(json.decode(source));
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
