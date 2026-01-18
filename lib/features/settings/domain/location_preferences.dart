/// Domain model for location-based feature preferences
class LocationPreferences {
  final bool systemPermissionGranted;
  final bool showWhenAtLocation; // Show pin icon badge AND restrict image uploads when at location

  const LocationPreferences({
    this.systemPermissionGranted = false,
    this.showWhenAtLocation = false,
  });

  LocationPreferences copyWith({
    bool? systemPermissionGranted,
    bool? showWhenAtLocation,
  }) {
    return LocationPreferences(
      systemPermissionGranted: systemPermissionGranted ?? this.systemPermissionGranted,
      showWhenAtLocation: showWhenAtLocation ?? this.showWhenAtLocation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'systemPermissionGranted': systemPermissionGranted,
      'showWhenAtLocation': showWhenAtLocation,
    };
  }

  factory LocationPreferences.fromMap(Map<String, dynamic> map) {
    return LocationPreferences(
      systemPermissionGranted: map['systemPermissionGranted'] as bool? ?? false,
      showWhenAtLocation: map['showWhenAtLocation'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPreferences &&
          runtimeType == other.runtimeType &&
          systemPermissionGranted == other.systemPermissionGranted &&
          showWhenAtLocation == other.showWhenAtLocation;

  @override
  int get hashCode =>
      systemPermissionGranted.hashCode ^
      showWhenAtLocation.hashCode;
}
