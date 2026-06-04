import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maypole/core/app_config.dart';
import 'package:maypole/features/maypolechat/domain/maypole.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';

class ResolvedMaypole {
  final String maypoleId;
  final String? googlePlaceId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeType;
  final String? locationSlug;
  final String? placeSlug;

  const ResolvedMaypole({
    required this.maypoleId,
    this.googlePlaceId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.placeType,
    this.locationSlug,
    this.placeSlug,
  });

  factory ResolvedMaypole.fromMap(Map<String, dynamic> map) {
    return ResolvedMaypole(
      maypoleId: map['maypoleId'] as String,
      googlePlaceId: map['googlePlaceId'] as String?,
      name: map['name'] as String? ?? 'Unknown Place',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeType: map['placeType'] as String?,
      locationSlug: map['locationSlug'] as String?,
      placeSlug: map['placeSlug'] as String?,
    );
  }

  MaypoleMetaData toMetaData({DateTime? lastTypedAt}) {
    return MaypoleMetaData(
      id: maypoleId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      lastTypedAt: lastTypedAt,
      placeType: placeType,
      googlePlaceId: googlePlaceId,
      googlePlaceIdAliases: [
        if (googlePlaceId != null && googlePlaceId!.isNotEmpty) googlePlaceId!,
      ],
      locationSlug: locationSlug,
      placeSlug: placeSlug,
    );
  }

  Map<String, dynamic> toNavigationExtra() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeType': placeType,
      'googlePlaceId': googlePlaceId,
      'locationSlug': locationSlug,
      'placeSlug': placeSlug,
    };
  }
}

class MaypoleResolverService {
  Uri get _resolveMaypoleUri {
    final autocompleteUri = Uri.parse(AppConfig.cloudFunctionsUrl);
    final host = autocompleteUri.host.replaceFirst(
      'places-autocomplete',
      'resolve-maypole',
    );
    final path = autocompleteUri.path.replaceFirst(
      RegExp(r'places[_-]autocomplete$'),
      'resolve_maypole',
    );

    return autocompleteUri.replace(host: host, path: path);
  }

  Future<ResolvedMaypole> resolvePrediction(PlacePrediction prediction) {
    return resolvePlace(
      googlePlaceId: prediction.placeId,
      name: prediction.placeName,
      address: prediction.address,
      latitude: prediction.latitude,
      longitude: prediction.longitude,
      placeType: prediction.placeType,
    );
  }

  Future<ResolvedMaypole> resolvePlace({
    String? googlePlaceId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
    String? locationSlug,
    String? placeSlug,
  }) async {
    final requestBody = {
      if (googlePlaceId != null && googlePlaceId.isNotEmpty)
        'googlePlaceId': googlePlaceId,
      if (name != null && name.isNotEmpty) 'name': name,
      if (address != null && address.isNotEmpty) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeType != null && placeType.isNotEmpty) 'placeType': placeType,
      if (locationSlug != null && locationSlug.isNotEmpty)
        'locationSlug': locationSlug,
      if (placeSlug != null && placeSlug.isNotEmpty) 'placeSlug': placeSlug,
    };

    debugPrint(
      '🔁 Resolving canonical maypole for Google Place ID: $googlePlaceId',
    );

    final response = await http.post(
      _resolveMaypoleUri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    debugPrint('📡 Resolve Maypole Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ Resolve Maypole Error: ${response.body}');
      throw Exception('Failed to resolve maypole (${response.statusCode})');
    }

    return ResolvedMaypole.fromMap(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
