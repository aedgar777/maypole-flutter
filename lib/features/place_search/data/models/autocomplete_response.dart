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
  final String place;
  final String placeId;

  PlacePrediction({required this.place, required this.placeId});

  factory PlacePrediction.fromMap(Map<String, dynamic> map) {
    final prediction = map['placePrediction'] as Map<String, dynamic>?;
    return PlacePrediction(
      place: prediction?['text']?['text'] as String? ?? '',
      placeId: prediction?['placeId'] as String? ?? '',
    );
  }

  factory PlacePrediction.fromJson(String source) =>
      PlacePrediction.fromMap(json.decode(source));
}
