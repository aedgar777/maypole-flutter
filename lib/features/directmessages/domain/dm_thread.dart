import 'package:cloud_firestore/cloud_firestore.dart';

import 'direct_message.dart';

// Participant info stored in DMThread
class DMParticipant {
  final String id;
  final String username;
  final String profilePicUrl;

  const DMParticipant({
    required this.id,
    required this.username,
    required this.profilePicUrl,
  });

  factory DMParticipant.fromMap(Map<String, dynamic> map) {
    return DMParticipant(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      profilePicUrl: map['profilePicUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'profilePicUrl': profilePicUrl,
    };
  }
}

// Subclass for direct message threads
class DMThread {
  final String id;
  final DateTime lastMessageTime;
  final DirectMessage? lastMessage;
  final Map<String, DMParticipant> participants;  // Map of userId -> participant info

  const DMThread({
    required this.id,
    required this.lastMessageTime,
    required this.participants,
    this.lastMessage,
  });

  // Helper to get participantIds as a list (for Firestore queries)
  List<String> get participantIds => participants.keys.toList();

  factory DMThread.fromMap(Map<String, dynamic> map) {
    final participantsMap = (map['participants'] as Map<String, dynamic>?) ?? {};
    final participants = participantsMap.map(
      (key, value) => MapEntry(key, DMParticipant.fromMap(value as Map<String, dynamic>)),
    );

    return DMThread(
      id: map['id'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      participants: participants,
      lastMessage: map['lastMessage'] != null
          ? DirectMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'participantIds': participantIds,  // Denormalized for queries
      'lastMessage': lastMessage?.toMap(),
    };
  }

  // Get the other participant (not the current user)
  DMParticipant? getPartner(String currentUserId) {
    return participants.entries
        .firstWhere((entry) => entry.key != currentUserId, orElse: () => MapEntry('', DMParticipant(id: '', username: '', profilePicUrl: '')))
        .value;
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
