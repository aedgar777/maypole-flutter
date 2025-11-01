import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/placechat/domain/place_chat_thread.dart';

class DomainUser {
  String username;
  String email;
  String firebaseID;
  String profilePictureUrl;
  List<PlaceChatThreadMetaData> placeChatThreads;
  List<DMThreadMetaData> dmThreads;

  DomainUser({
    required this.username,
    required this.email,
    required this.firebaseID,
    this.profilePictureUrl = '',
    this.placeChatThreads = const [],
    this.dmThreads = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firebaseID': firebaseID,
      'profilePictureUrl': profilePictureUrl,
      'placeChatThreads': placeChatThreads.map((e) => e.toMap()).toList(),
      'dmThreads': dmThreads.map((e) => e.toMap()).toList(),
    };
  }

  factory DomainUser.fromMap(Map<String, dynamic> map) {
    return DomainUser(
      username: map['username'],
      email: map['email'],
      firebaseID: map['firebaseID'],
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      placeChatThreads: List<PlaceChatThreadMetaData>.from(map['placeChatThreads']?.map((x) => PlaceChatThreadMetaData.fromMap(x)) ?? []),
      dmThreads: List<DMThreadMetaData>.from(map['dmThreads']?.map((x) => DMThreadMetaData.fromMap(x)) ?? []),
    );
  }
}
