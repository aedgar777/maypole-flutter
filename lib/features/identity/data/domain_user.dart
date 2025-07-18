class DomainUser {
  String username;
  String email;
  String firebaseID;
  String profilePictureUrl;

  DomainUser({
    required this.username,
    required this.email,
    required this.firebaseID,
    this.profilePictureUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firebaseID': firebaseID,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  factory DomainUser.fromMap(Map<String, dynamic> map) {
    return DomainUser(
      username: map['username'],
      email: map['email'],
      firebaseID: map['firebaseID'],
      profilePictureUrl: map['profilePictureUrl'] ?? '',
    );
  }
}