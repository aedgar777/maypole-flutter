import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class MaypoleMessage {
  final String sender;
  final DateTime timestamp;
  final String body;
  final String taggedUser; // Legacy field for backward compatibility
  final List<String> taggedUserIds; // New field for multiple mentions

  const MaypoleMessage({
    required this.sender,
    required this.timestamp,
    required this.body,
    this.taggedUser = '',
    this.taggedUserIds = const [],
  });

  factory MaypoleMessage.fromMap(Map<String, dynamic> map) {
    return MaypoleMessage(
      sender: map['sender'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      body: map['body'] as String,
      taggedUser: map['taggedUser'] as String? ?? '',
      taggedUserIds:
          (map['taggedUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'place',
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'taggedUser': taggedUser,
      'taggedUserIds': taggedUserIds,
    };
  }
}
