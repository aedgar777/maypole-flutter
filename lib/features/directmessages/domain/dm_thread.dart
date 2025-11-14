import 'package:cloud_firestore/cloud_firestore.dart';

import 'direct_message.dart';

// Subclass for direct message threads
class DMThread {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final String partnerName;
  final String partnerId;
  final String partnerProfpic;
  final DirectMessage? lastMessage;

  const DMThread({
    required this.id,
    required this.name,
    required this.lastMessageTime,
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
          ? DirectMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

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

class DMThreadMetaData {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final String partnerName;
  final String partnerId;
  final String partnerProfpic;

  const DMThreadMetaData({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    required this.partnerName,
    required this.partnerId,
    required this.partnerProfpic,
  });

  factory DMThreadMetaData.fromMap(Map<String, dynamic> map) {
    return DMThreadMetaData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      partnerName: map['partnerName'] ?? '',
      partnerId: map['partnerId'] ?? '',
      partnerProfpic: map['partnerProfpic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'partnerName': partnerName,
      'partnerId': partnerId,
      'partnerProfpic': partnerProfpic,
    };
  }
}
