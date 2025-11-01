import 'package:cloud_firestore/cloud_firestore.dart';

// Subclass for place-based home threads
class PlaceChatThread {
  final String id;
  final String name;
  final DateTime lastMessageTime;

  const PlaceChatThread({
    required this.id,
    required this.name,
    required this.lastMessageTime,
  });

  factory PlaceChatThread.fromMap(Map<String, dynamic> map) {
    return PlaceChatThread(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }
}

class PlaceChatThreadMetaData {
  final String id;
  final String name;
  final DateTime lastMessageTime;

  const PlaceChatThreadMetaData({
    required this.id,
    required this.name,
    required this.lastMessageTime,
  });

  factory PlaceChatThreadMetaData.fromMap(Map<String, dynamic> map) {
    return PlaceChatThreadMetaData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }
}
