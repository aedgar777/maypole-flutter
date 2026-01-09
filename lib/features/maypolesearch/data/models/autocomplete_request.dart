import 'dart:convert';

class AutocompleteRequest {
  final String input;
  final LocationBias? locationBias;
  final LocationRestriction? locationRestriction;

  AutocompleteRequest({
    required this.input,
    this.locationBias,
    this.locationRestriction,
  });

  Map<String, dynamic> toMap() {
    return {
      'input': input,
      if (locationBias != null) 'locationBias': locationBias!.toMap(),
      if (locationRestriction != null)
        'locationRestriction': locationRestriction!.toMap(),
    };
  }

  String toJson() => json.encode(toMap());
}

class LocationBias {
  final Circle circle;

  LocationBias({required this.circle});

  Map<String, dynamic> toMap() {
    return {
      'circle': circle.toMap(),
    };
  }
}

class LocationRestriction {
  final Circle circle;

  LocationRestriction({required this.circle});

  Map<String, dynamic> toMap() {
    return {
      'circle': circle.toMap(),
    };
  }
}

class Circle {
  final Center center;
  final double radius;

  Circle({required this.center, required this.radius});

  Map<String, dynamic> toMap() {
    return {
      'center': center.toMap(),
      'radius': radius,
    };
  }
}

class Center {
  final double latitude;
  final double longitude;

  Center({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
