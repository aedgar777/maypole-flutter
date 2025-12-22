import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_request.dart';
import 'dart:convert';

void main() {
  group('Center', () {
    test('creates instance with latitude and longitude', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);

      expect(center.latitude, 37.7749);
      expect(center.longitude, -122.4194);
    });

    test('toMap serializes correctly', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final map = center.toMap();

      expect(map['latitude'], 37.7749);
      expect(map['longitude'], -122.4194);
    });

    test('handles negative coordinates', () {
      final center = Center(latitude: -33.8688, longitude: 151.2093);
      final map = center.toMap();

      expect(map['latitude'], -33.8688);
      expect(map['longitude'], 151.2093);
    });
  });

  group('Circle', () {
    test('creates instance with center and radius', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);

      expect(circle.center.latitude, 37.7749);
      expect(circle.radius, 1000);
    });

    test('toMap serializes correctly', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 5000);
      final map = circle.toMap();

      expect(map['center'], isA<Map<String, dynamic>>());
      expect(map['radius'], 5000);
    });
  });

  group('LocationBias', () {
    test('creates instance with circle', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final bias = LocationBias(circle: circle);

      expect(bias.circle.radius, 1000);
    });

    test('toMap serializes correctly', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final bias = LocationBias(circle: circle);
      final map = bias.toMap();

      expect(map['circle'], isA<Map<String, dynamic>>());
    });
  });

  group('LocationRestriction', () {
    test('creates instance with circle', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final restriction = LocationRestriction(circle: circle);

      expect(restriction.circle.radius, 1000);
    });

    test('toMap serializes correctly', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final restriction = LocationRestriction(circle: circle);
      final map = restriction.toMap();

      expect(map['circle'], isA<Map<String, dynamic>>());
    });
  });

  group('AutocompleteRequest', () {
    test('creates instance with input only', () {
      final request = AutocompleteRequest(input: 'pizza');

      expect(request.input, 'pizza');
      expect(request.locationBias, isNull);
      expect(request.locationRestriction, isNull);
    });

    test('creates instance with all fields', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final bias = LocationBias(circle: circle);
      final restriction = LocationRestriction(circle: circle);

      final request = AutocompleteRequest(
        input: 'pizza',
        locationBias: bias,
        locationRestriction: restriction,
      );

      expect(request.input, 'pizza');
      expect(request.locationBias, isNotNull);
      expect(request.locationRestriction, isNotNull);
    });

    test('toMap includes only input when no location data', () {
      final request = AutocompleteRequest(input: 'coffee');
      final map = request.toMap();

      expect(map['input'], 'coffee');
      expect(map.containsKey('locationBias'), isFalse);
      expect(map.containsKey('locationRestriction'), isFalse);
    });

    test('toMap includes locationBias when provided', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final bias = LocationBias(circle: circle);

      final request = AutocompleteRequest(
        input: 'restaurant',
        locationBias: bias,
      );
      final map = request.toMap();

      expect(map['input'], 'restaurant');
      expect(map['locationBias'], isA<Map<String, dynamic>>());
      expect(map.containsKey('locationRestriction'), isFalse);
    });

    test('toMap includes locationRestriction when provided', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final restriction = LocationRestriction(circle: circle);

      final request = AutocompleteRequest(
        input: 'bar',
        locationRestriction: restriction,
      );
      final map = request.toMap();

      expect(map['input'], 'bar');
      expect(map['locationRestriction'], isA<Map<String, dynamic>>());
      expect(map.containsKey('locationBias'), isFalse);
    });

    test('toMap includes both location bias and restriction', () {
      final center = Center(latitude: 37.7749, longitude: -122.4194);
      final circle = Circle(center: center, radius: 1000);
      final bias = LocationBias(circle: circle);
      final restriction = LocationRestriction(circle: circle);

      final request = AutocompleteRequest(
        input: 'hotel',
        locationBias: bias,
        locationRestriction: restriction,
      );
      final map = request.toMap();

      expect(map['input'], 'hotel');
      expect(map['locationBias'], isA<Map<String, dynamic>>());
      expect(map['locationRestriction'], isA<Map<String, dynamic>>());
    });

    test('toJson returns valid JSON string', () {
      final request = AutocompleteRequest(input: 'cafe');
      final jsonStr = request.toJson();

      expect(() => json.decode(jsonStr), returnsNormally);
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      expect(decoded['input'], 'cafe');
    });

    test('handles empty input string', () {
      final request = AutocompleteRequest(input: '');
      final map = request.toMap();

      expect(map['input'], '');
    });

    test('handles special characters in input', () {
      final request = AutocompleteRequest(input: 'café & résτaurant');
      final map = request.toMap();

      expect(map['input'], 'café & résτaurant');
    });

    test('complete serialization produces valid nested structure', () {
      final center = Center(latitude: 40.7128, longitude: -74.0060);
      final circle = Circle(center: center, radius: 2500);
      final bias = LocationBias(circle: circle);

      final request = AutocompleteRequest(
        input: 'museum',
        locationBias: bias,
      );
      final map = request.toMap();

      expect(map['input'], 'museum');
      expect(map['locationBias']['circle']['center']['latitude'], 40.7128);
      expect(map['locationBias']['circle']['center']['longitude'], -74.0060);
      expect(map['locationBias']['circle']['radius'], 2500);
    });
  });
}
