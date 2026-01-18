import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


@immutable
class DirectMessage {
  final String? id; // Firestore document ID
  final String recipient;
  final String sender;
  final DateTime timestamp;
  final String body;
  final List<String> deletedFor; // List of user IDs who deleted this message
  final List<String> imageUrls; // List of image URLs (max 5)


  const DirectMessage({
    this.id,
    required this.sender,
    required this.timestamp,
    required this.body,
    required this.recipient,
    this.deletedFor = const [],
    this.imageUrls = const [],
  });

  factory DirectMessage.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return DirectMessage(
      id: documentId,
      sender: map['sender'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      body: map['body'],
      recipient: map['recipient'],
      deletedFor:
          (map['deletedFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrls:
          (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'direct',
      'sender': sender,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'recipient': recipient,
      'deletedFor': deletedFor,
      'imageUrls': imageUrls,
    };
  }

  /// Check if this message is deleted for a specific user
  bool isDeletedFor(String userId) {
    return deletedFor.contains(userId);
  }
}
