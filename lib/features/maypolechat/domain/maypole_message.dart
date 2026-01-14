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
  final String? messageType; // Type of message: 'text', 'image_upload'
  final String? imageId; // For image upload messages, the ID of the uploaded image
  final double? senderLatitude; // Sender's latitude when message was sent
  final double? senderLongitude; // Sender's longitude when message was sent

  const MaypoleMessage({
    this.id,
    required this.senderName,
    required this.senderId,
    this.senderProfilePictureUrl = '',
    required this.timestamp,
    required this.body,
    this.taggedUser = '',
    this.taggedUserIds = const [],
    this.messageType,
    this.imageId,
    this.senderLatitude,
    this.senderLongitude,
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
      messageType: map['messageType'] as String?,
      imageId: map['imageId'] as String?,
      senderLatitude: map['senderLatitude'] as double?,
      senderLongitude: map['senderLongitude'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'type': 'place',
      'senderName': senderName,
      'senderId': senderId,
      'senderProfilePictureUrl': senderProfilePictureUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'taggedUser': taggedUser,
      'taggedUserIds': taggedUserIds,
    };
    
    // Add optional fields only if they exist
    if (messageType != null) {
      map['messageType'] = messageType!;
    }
    if (imageId != null) {
      map['imageId'] = imageId!;
    }
    if (senderLatitude != null) {
      map['senderLatitude'] = senderLatitude!;
    }
    if (senderLongitude != null) {
      map['senderLongitude'] = senderLongitude!;
    }
    
    return map;
  }
  
  /// Helper to check if this is an image upload notification
  bool get isImageUpload => messageType == 'image_upload';
}
