import 'package:cloud_firestore/cloud_firestore.dart';
import './message.dart';

// Parent class for all thread types
abstract class Thread {
  final String id;
  final String name;
  final DateTime lastMessageTime;

  const Thread({
    required this.id,
    required this.name,
    required this.lastMessageTime,
  });

  factory Thread.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('partnerId')) {
      return DMThread.fromMap(map);
    } else {
      return PlaceChatThread.fromMap(map);
    }
  }

  Map<String, dynamic> toMap();
}

// Subclass for place-based chat threads
class PlaceChatThread extends Thread {
  const PlaceChatThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
  });

  factory PlaceChatThread.fromMap(Map<String, dynamic> map) {
    return PlaceChatThread(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }
}

// Subclass for direct message threads
class DMThread extends Thread {
  final String partnerName;
  final String partnerId;
  final String partnerProfpic;
  final Message? lastMessage;

  const DMThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required this.partnerName,
    required this.partnerId,
    required this.partnerProfpic,
    this.lastMessage,
  });

  factory DMThread.fromMap(Map<String, dynamic> map) {
    return DMThread(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      partnerName: map['partnerName'] ?? '',
      partnerId: map['partnerId'] ?? '',
      partnerProfpic: map['partnerProfpic'] ?? '',
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'partnerName': partnerName,
      'partnerId': partnerId,
      'partnerProfpic': partnerProfpic,
      'lastMessage': lastMessage?.toMap(),
    };
  }
}
