import 'package:cloud_firestore/cloud_firestore.dart';
import 'maypole_message.dart';

// Subclass for place-based home threads
class Maypole {
  final String id;
  final String name;
  final List<MaypoleMessage> messages;
  final int imageCount; // Track total number of images for display purposes

  const Maypole({
    required this.id,
    required this.name,
    required this.messages,
    this.imageCount = 0,
  });

  factory Maypole.fromMap(Map<String, dynamic> map) {
    return Maypole(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      messages:
          (map['messages'] as List<dynamic>?)
              ?.map((e) => MaypoleMessage.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      imageCount: map['imageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((e) => e.toMap()).toList(),
      'imageCount': imageCount,
    };
  }
}

class MaypoleMetaData {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? lastTypedAt;
  final String? placeType; // Primary type from Google Places API
  final String? googlePlaceId;
  final List<String> googlePlaceIdAliases;
  final String? locationSlug;
  final String? placeSlug;

  const MaypoleMetaData({
    required this.id,
    required this.name,
    this.address = '',
    this.latitude,
    this.longitude,
    this.lastTypedAt,
    this.placeType,
    this.googlePlaceId,
    this.googlePlaceIdAliases = const [],
    this.locationSlug,
    this.placeSlug,
  });

  factory MaypoleMetaData.fromMap(Map<String, dynamic> map) {
    return MaypoleMetaData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: _nullableDouble(map['latitude']),
      longitude: _nullableDouble(map['longitude']),
      lastTypedAt: _nullableDateTime(map['lastTypedAt']),
      placeType: map['placeType'] as String?,
      googlePlaceId: map['googlePlaceId'] as String?,
      googlePlaceIdAliases:
          (map['googlePlaceIdAliases'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      locationSlug: map['locationSlug'] as String?,
      placeSlug: map['placeSlug'] as String?,
    );
  }

  static double? _nullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> mapData = {
      'id': id,
      'name': name,
      'address': address,
    };

    if (latitude != null) {
      mapData['latitude'] = latitude!;
    }
    if (longitude != null) {
      mapData['longitude'] = longitude!;
    }
    if (lastTypedAt != null) {
      mapData['lastTypedAt'] = Timestamp.fromDate(lastTypedAt!);
    }
    if (placeType != null) {
      mapData['placeType'] = placeType!;
    }
    if (googlePlaceId != null) {
      mapData['googlePlaceId'] = googlePlaceId!;
    }
    if (googlePlaceIdAliases.isNotEmpty) {
      mapData['googlePlaceIdAliases'] = googlePlaceIdAliases;
    }
    if (locationSlug != null) {
      mapData['locationSlug'] = locationSlug!;
    }
    if (placeSlug != null) {
      mapData['placeSlug'] = placeSlug!;
    }

    return mapData;
  }
}
