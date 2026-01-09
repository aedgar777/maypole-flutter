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

  PlacePrediction({
    required this.place,
    required this.placeName,
    required this.placeId,
    this.address = '',
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
    );
  }

  factory PlacePrediction.fromJson(String source) =>
      PlacePrediction.fromMap(json.decode(source));
}
