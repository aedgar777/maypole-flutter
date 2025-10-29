import 'package:cloud_firestore/cloud_firestore.dart';

// Parent class for all thread types
class Thread {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final List<dynamic>
      messages; // Will be List<Message> when Message class is created

  Thread({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    required this.messages,
  });

  factory Thread.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('partnerId')) {
      return DMThread.fromMap(map);
    } else {
      return PlaceChatThread.fromMap(map);
    }
  }
}

// Subclass for place-based chat threads
class PlaceChatThread extends Thread {
  PlaceChatThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required super.messages,
  });

  factory PlaceChatThread.fromMap(Map<String, dynamic> map) {
    return PlaceChatThread(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      messages: List<dynamic>.from(map['messages'] ?? []),
    );
  }
}

// Subclass for direct message threads
class DMThread extends Thread {
  final String partnerName;
  final String partnerId;
  final dynamic
      lastMessage; // Will be Message type when Message class is created

  DMThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required super.messages,
    required this.partnerName,
    required this.partnerId,
    required this.lastMessage,
  });

  factory DMThread.fromMap(Map<String, dynamic> map) {
    return DMThread(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      messages: List<dynamic>.from(map['messages'] ?? []),
      partnerName: map['partnerName'] ?? '',
      partnerId: map['partnerId'] ?? '',
      lastMessage: map['lastMessage'],
    );
  }
}
