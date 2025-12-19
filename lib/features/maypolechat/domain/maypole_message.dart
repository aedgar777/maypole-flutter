import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class MaypoleMessage {
  final String? id; // Firestore document ID
  final String senderName;
  final String senderId;
  final String senderProfilePictureUrl;
  final DateTime timestamp;
  final String body;
  final String taggedUser; // Legacy field for backward compatibility
  final List<String> taggedUserIds; // New field for multiple mentions

  const MaypoleMessage({
    this.id,
    required this.senderName,
    required this.senderId,
    this.senderProfilePictureUrl = '',
    required this.timestamp,
    required this.body,
    this.taggedUser = '',
    this.taggedUserIds = const [],
  });

  factory MaypoleMessage.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return MaypoleMessage(
      id: documentId,
      senderName:
          map['senderName'] as String? ?? map['sender'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderProfilePictureUrl: map['senderProfilePictureUrl'] as String? ?? '',
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
      'senderName': senderName,
      'senderId': senderId,
      'senderProfilePictureUrl': senderProfilePictureUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'taggedUser': taggedUser,
      'taggedUserIds': taggedUserIds,
    };
  }
}
