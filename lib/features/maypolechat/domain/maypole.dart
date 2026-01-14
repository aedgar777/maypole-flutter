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
      messages: (map['messages'] as List<dynamic>?)
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

  const MaypoleMetaData({
    required this.id,
    required this.name,
    this.address = '',
    this.latitude,
    this.longitude,
  });

  factory MaypoleMetaData.fromMap(Map<String, dynamic> map) {
    return MaypoleMetaData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
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
    
    return mapData;
  }
}
