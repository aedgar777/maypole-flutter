import 'package:flutter/foundation.dart';

/// Represents a user mention in a message
@immutable
class UserMention {
  final String userId;
  final String username;
  final int startIndex;
  final int endIndex;

  const UserMention({
    required this.userId,
    required this.username,
    required this.startIndex,
    required this.endIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'startIndex': startIndex,
      'endIndex': endIndex,
    };
  }

  factory UserMention.fromMap(Map<String, dynamic> map) {
    return UserMention(
      userId: map['userId'] as String,
      username: map['username'] as String,
      startIndex: map['startIndex'] as int,
      endIndex: map['endIndex'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserMention &&
              runtimeType == other.runtimeType &&
              userId == other.userId &&
              username == other.username &&
              startIndex == other.startIndex &&
              endIndex == other.endIndex;

  @override
  int get hashCode =>
      userId.hashCode ^
      username.hashCode ^
      startIndex.hashCode ^
      endIndex.hashCode;

  @override
  String toString() {
    return 'UserMention(userId: $userId, username: $username, range: $startIndex-$endIndex)';
  }
}
