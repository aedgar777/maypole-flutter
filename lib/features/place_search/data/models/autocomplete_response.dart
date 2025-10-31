import 'dart:convert';

class AutocompleteResponse {
  final List<PlacePrediction> predictions;

  AutocompleteResponse({required this.predictions});

  factory AutocompleteResponse.fromMap(Map<String, dynamic> map) {
    return AutocompleteResponse(
      predictions: List<PlacePrediction>.from(
          map['predictions']?.map((x) => PlacePrediction.fromMap(x)) ?? []),
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
    return PlacePrediction(
      place: map['place'] ?? '',
      placeId: map['placeId'] ?? '',
    );
  }

  factory PlacePrediction.fromJson(String source) =>
      PlacePrediction.fromMap(json.decode(source));
}
