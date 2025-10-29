import 'package:cloud_firestore/cloud_firestore.dart';

// Parent class for all thread metadata types
abstract class ThreadMetadata {
  final String id;
  final String name;
  final DateTime lastMessageTime;

  ThreadMetadata({
    required this.id,
    required this.name,
    required this.lastMessageTime,
  });

  factory ThreadMetadata.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('partnerId')) {
      return DMThreadMetadata.fromMap(map);
    } else {
      return PlaceChatThreadMetadata.fromMap(map);
    }
  }
}

// Subclass for place-based chat thread metadata
class PlaceChatThreadMetadata extends ThreadMetadata {
  PlaceChatThreadMetadata({
    required super.id,
    required super.name,
    required super.lastMessageTime,
  });

  factory PlaceChatThreadMetadata.fromMap(Map<String, dynamic> map) {
    return PlaceChatThreadMetadata(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }
}

// Subclass for direct message thread metadata
class DMThreadMetadata extends ThreadMetadata {
  final String partnerName;
  final String partnerId;
  final dynamic
      lastMessage; // Will be Message type when Message class is created

  DMThreadMetadata({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required this.partnerName,
    required this.partnerId,
    required this.lastMessage,
  });

  factory DMThreadMetadata.fromMap(Map<String, dynamic> map) {
    return DMThreadMetadata(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      partnerName: map['partnerName'] ?? '',
      partnerId: map['partnerId'] ?? '',
      lastMessage: map['lastMessage'],
    );
  }
}
