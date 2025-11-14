import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class MaypoleMessage {
  final String sender;
  final DateTime timestamp;
  final String body;
  final String taggedUser;

  const MaypoleMessage({
    required this.sender,
    required this.timestamp,
    required this.body,
    required this.taggedUser,
  });

  factory MaypoleMessage.fromMap(Map<String, dynamic> map) {
    return MaypoleMessage(
      sender: map['sender'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      body: map['body'],
      taggedUser: map['taggedUser'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'place',
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'taggedUser': taggedUser,
    };
  }
}
