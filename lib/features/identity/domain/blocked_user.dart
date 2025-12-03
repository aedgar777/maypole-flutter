class BlockedUser {
  final String username;
  final String firebaseId;

  BlockedUser({
    required this.username,
    required this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'firebaseId': firebaseId,
    };
  }

  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    return BlockedUser(
      username: map['username'] as String,
      firebaseId: map['firebaseId'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockedUser && other.firebaseId == firebaseId;
  }

  @override
  int get hashCode => firebaseId.hashCode;
}
