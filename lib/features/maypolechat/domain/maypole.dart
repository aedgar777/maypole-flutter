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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lastTypedAt: map['lastTypedAt'] != null
          ? (map['lastTypedAt'] as Timestamp).toDate()
          : null,
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

  String get effectiveLocationSlug =>
      (locationSlug != null && locationSlug!.isNotEmpty)
      ? locationSlug!
      : MaypoleSlugUtils.locationSlugFromAddress(address);

  String get effectivePlaceSlug => (placeSlug != null && placeSlug!.isNotEmpty)
      ? placeSlug!
      : MaypoleSlugUtils.slugify(name);

  Uri semanticUri({required Uri baseUri}) {
    return baseUri.replace(
      pathSegments: [effectiveLocationSlug, effectivePlaceSlug],
      queryParameters: {'id': googlePlaceId ?? id},
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> mapData = {
      'id': id,
      'name': name,
      'address': address,
      if (googlePlaceId != null && googlePlaceId!.isNotEmpty)
        'googlePlaceId': googlePlaceId,
      if (googlePlaceIdAliases.isNotEmpty)
        'googlePlaceIdAliases': googlePlaceIdAliases,
      'locationSlug': effectiveLocationSlug,
      'placeSlug': effectivePlaceSlug,
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

    return mapData;
  }
}

class MaypoleSlugUtils {
  static const String fallbackLocationSlug = 'nearby';
  static const String fallbackPlaceSlug = 'maypole';

  const MaypoleSlugUtils._();

  static String slugify(String value, {String fallback = fallbackPlaceSlug}) {
    final slug = value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '')
        .replaceAll(RegExp(r'-{2,}'), '-');

    return slug.isEmpty ? fallback : slug;
  }

  static String locationSlugFromAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return fallbackLocationSlug;
    }

    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final cityOrNeighborhood = parts.length >= 2
        ? parts[parts.length - 2]
        : parts.first;
    final withoutStateOrPostalCode = cityOrNeighborhood
        .replaceAll(RegExp(r'\b[A-Z]{2}\b'), '')
        .replaceAll(RegExp(r'\b\d{5}(?:-\d{4})?\b'), '')
        .trim();

    return slugify(
      withoutStateOrPostalCode.isEmpty
          ? cityOrNeighborhood
          : withoutStateOrPostalCode,
      fallback: fallbackLocationSlug,
    );
  }
}
