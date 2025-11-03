import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class Message {
  final String sender;
  final DateTime timestamp;
  final String body;

  const Message({
    required this.sender,
    required this.timestamp,
    required this.body,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final String type = map['type'];
    if (type == 'place') {
      return PlaceChatMessage.fromMap(map);
    } else { // 'direct'
      return DirectMessage.fromMap(map);
    }
  }

  Map<String, dynamic> toMap();
}

@immutable
class PlaceChatMessage extends Message {
  final String taggedUser;

  const PlaceChatMessage({
    required super.sender,
    required super.timestamp,
    required super.body,
    required this.taggedUser,
  });

  factory PlaceChatMessage.fromMap(Map<String, dynamic> map) {
    return PlaceChatMessage(
      sender: map['sender'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      body: map['body'],
      taggedUser: map['taggedUser'],
    );
  }

  @override
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

@immutable
class DirectMessage extends Message {
  final String recipient;

  const DirectMessage({
    required super.sender,
    required super.timestamp,
    required super.body,
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

  @override
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
