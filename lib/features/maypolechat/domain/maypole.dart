import 'package:cloud_firestore/cloud_firestore.dart';
import 'maypole_message.dart';

// Subclass for place-based home threads
class Maypole {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final List<MaypoleMessage> messages;

  const Maypole({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    required this.messages,
  });

  factory Maypole.fromMap(Map<String, dynamic> map) {
    return Maypole(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      messages: (map['messages'] as List<dynamic>?)
              ?.map((e) => MaypoleMessage.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'messages': messages.map((e) => e.toMap()).toList(),
    };
  }
}

class MaypoleMetaData {
  final String id;
  final String name;
  final DateTime lastMessageTime;

  const MaypoleMetaData({
    required this.id,
    required this.name,
    required this.lastMessageTime,
  });

  factory MaypoleMetaData.fromMap(Map<String, dynamic> map) {
    return MaypoleMetaData(
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
