import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import 'dart:convert';

void main() {
  group('PlacePrediction', () {
    test('creates instance with all fields', () {
      final prediction = PlacePrediction(
        place: 'Pizza Palace, 123 Main St',
        placeName: 'Pizza Palace',
        placeId: 'place123',
      );

      expect(prediction.place, 'Pizza Palace, 123 Main St');
      expect(prediction.placeName, 'Pizza Palace');
      expect(prediction.placeId, 'place123');
    });

    test('fromMap deserializes correctly with full data', () {
      final map = {
        'placePrediction': {
          'text': {'text': 'Pizza Palace, 123 Main St'},
          'structuredFormat': {
            'mainText': {'text': 'Pizza Palace'},
          },
          'placeId': 'place123',
        },
      };

      final prediction = PlacePrediction.fromMap(map);

      expect(prediction.place, 'Pizza Palace, 123 Main St');
      expect(prediction.placeName, 'Pizza Palace');
      expect(prediction.placeId, 'place123');
    });

    test('fromMap handles missing structured format', () {
      final map = {
        'placePrediction': {
          'text': {'text': 'Some Place'},
          'placeId': 'place456',
        },
      };

      final prediction = PlacePrediction.fromMap(map);

      expect(prediction.place, 'Some Place');
      expect(prediction.placeName, 'Some Place'); // Falls back to full text
      expect(prediction.placeId, 'place456');
    });

    test('fromMap handles missing data with defaults', () {
      final map = <String, dynamic>{
        'placePrediction': <String, dynamic>{},
      };

      final prediction = PlacePrediction.fromMap(map);

      expect(prediction.place, '');
      expect(prediction.placeName, '');
      expect(prediction.placeId, '');
    });

    test('fromMap handles missing placePrediction', () {
      final map = <String, dynamic>{};

      final prediction = PlacePrediction.fromMap(map);

      expect(prediction.place, '');
      expect(prediction.placeName, '');
      expect(prediction.placeId, '');
    });

    test('fromJson deserializes from JSON string', () {
      final jsonStr = json.encode({
        'placePrediction': {
          'text': {'text': 'Coffee Shop, 456 Oak St'},
          'structuredFormat': {
            'mainText': {'text': 'Coffee Shop'},
          },
          'placeId': 'place789',
        },
      });

      final prediction = PlacePrediction.fromJson(jsonStr);

      expect(prediction.place, 'Coffee Shop, 456 Oak St');
      expect(prediction.placeName, 'Coffee Shop');
      expect(prediction.placeId, 'place789');
    });

    test('handles nested null values gracefully', () {
      final map = <String, dynamic>{
        'placePrediction': <String, dynamic>{
          'text': null,
          'structuredFormat': null,
          'placeId': null,
        },
      };

      final prediction = PlacePrediction.fromMap(map);

      expect(prediction.place, '');
      expect(prediction.placeName, '');
      expect(prediction.placeId, '');
    });
  });

  group('AutocompleteResponse', () {
    test('creates instance with predictions', () {
      final predictions = [
        PlacePrediction(
          place: 'Place 1',
          placeName: 'Name 1',
          placeId: 'id1',
        ),
        PlacePrediction(
          place: 'Place 2',
          placeName: 'Name 2',
          placeId: 'id2',
        ),
      ];

      final response = AutocompleteResponse(predictions: predictions);

      expect(response.predictions.length, 2);
      expect(response.predictions[0].placeId, 'id1');
      expect(response.predictions[1].placeId, 'id2');
    });

    test('creates instance with empty predictions', () {
      final response = AutocompleteResponse(predictions: []);

      expect(response.predictions, isEmpty);
    });

    test('fromMap deserializes correctly with suggestions', () {
      final map = {
        'suggestions': [
          {
            'placePrediction': {
              'text': {'text': 'Restaurant A, 123 St'},
              'structuredFormat': {
                'mainText': {'text': 'Restaurant A'},
              },
              'placeId': 'placeA',
            },
          },
          {
            'placePrediction': {
              'text': {'text': 'Restaurant B, 456 Ave'},
              'structuredFormat': {
                'mainText': {'text': 'Restaurant B'},
              },
              'placeId': 'placeB',
            },
          },
        ],
      };

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions.length, 2);
      expect(response.predictions[0].placeName, 'Restaurant A');
      expect(response.predictions[1].placeName, 'Restaurant B');
    });

    test('fromMap handles missing suggestions with empty list', () {
      final map = <String, dynamic>{};

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions, isEmpty);
    });

    test('fromMap handles null suggestions', () {
      final map = {
        'suggestions': null,
      };

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions, isEmpty);
    });

    test('fromJson deserializes from JSON string', () {
      final jsonStr = json.encode({
        'suggestions': [
          {
            'placePrediction': {
              'text': {'text': 'Cafe X, Downtown'},
              'structuredFormat': {
                'mainText': {'text': 'Cafe X'},
              },
              'placeId': 'cafeX',
            },
          },
        ],
      });

      final response = AutocompleteResponse.fromJson(jsonStr);

      expect(response.predictions.length, 1);
      expect(response.predictions[0].placeName, 'Cafe X');
    });

    test('handles empty suggestions array', () {
      final map = {
        'suggestions': [],
      };

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions, isEmpty);
    });

    test('handles multiple predictions correctly', () {
      final map = {
        'suggestions': List.generate(
          5,
          (i) => {
            'placePrediction': {
              'text': {'text': 'Place $i'},
              'structuredFormat': {
                'mainText': {'text': 'Name $i'},
              },
              'placeId': 'id$i',
            },
          },
        ),
      };

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions.length, 5);
      for (var i = 0; i < 5; i++) {
        expect(response.predictions[i].placeId, 'id$i');
        expect(response.predictions[i].placeName, 'Name $i');
      }
    });

    test('handles malformed suggestions gracefully', () {
      final map = {
        'suggestions': [
          {
            'placePrediction': {
              'text': {'text': 'Valid Place'},
              'placeId': 'valid',
            },
          },
          {
            'placePrediction': {
              // Missing text field
              'placeId': 'place2',
            },
          },
          {
            'placePrediction': {
              // Missing placeId field
              'text': {'text': 'Place without ID'},
            },
          },
        ],
      };

      final response = AutocompleteResponse.fromMap(map);

      expect(response.predictions.length, 3);
      expect(response.predictions[0].place, 'Valid Place');
      expect(response.predictions[1].place, ''); // Missing text defaults to empty
      expect(response.predictions[2].placeId, ''); // Missing placeId defaults to empty
    });

    test('fromJson handles invalid JSON gracefully', () {
      expect(
        () => AutocompleteResponse.fromJson('invalid json'),
        throwsFormatException,
      );
    });
  });
}
