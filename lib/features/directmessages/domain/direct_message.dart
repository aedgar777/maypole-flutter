import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


@immutable
class DirectMessage {
  final String recipient;
  final String sender;
  final DateTime timestamp;
  final String body;


  const DirectMessage({
    required this.sender,
    required this.timestamp,
    required this.body,
    required this.recipient,
  });

  factory DirectMessage.fromMap(Map<String, dynamic> map) {
    return DirectMessage(
      sender: map['sender'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      body: map['body'],
      recipient: map['recipient'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'direct',
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'recipient': recipient,
    };
  }
}
