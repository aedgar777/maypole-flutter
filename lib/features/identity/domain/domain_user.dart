import 'package:maypole/features/maypolechat/domain/maypole.dart';
import 'package:maypole/features/identity/domain/blocked_user.dart';

class DomainUser {
  String username;
  String email;
  String firebaseID;
  String profilePictureUrl;
  List<MaypoleMetaData> maypoleChatThreads;
  List<BlockedUser> blockedUsers;
  String? fcmToken;
  bool emailVerified;

  DomainUser({
    required this.username,
    required this.email,
    required this.firebaseID,
    this.profilePictureUrl = '',
    this.maypoleChatThreads = const [],
    this.blockedUsers = const [],
    this.fcmToken,
    this.emailVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firebaseID': firebaseID,
      'profilePictureUrl': profilePictureUrl,
      'maypoleChatThreads': maypoleChatThreads.map((e) => e.toMap()).toList(),
      'blockedUsers': blockedUsers.map((e) => e.toMap()).toList(),
      'fcmToken': fcmToken,
      'emailVerified': emailVerified,
    };
  }

  factory DomainUser.fromMap(Map<String, dynamic> map) {
    return DomainUser(
      username: map['username'],
      email: map['email'],
      firebaseID: map['firebaseID'],
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      maypoleChatThreads: List<MaypoleMetaData>.from(
          map['maypoleChatThreads']?.map((x) => MaypoleMetaData.fromMap(x)) ??
              []),
      blockedUsers: List<BlockedUser>.from(
          map['blockedUsers']?.map((x) => BlockedUser.fromMap(x)) ?? []),
      fcmToken: map['fcmToken'] as String?,
      emailVerified: map['emailVerified'] ?? false,
    );
  }
}
