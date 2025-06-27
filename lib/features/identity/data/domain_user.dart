class DomainUser {
  String username;
  String email;
  String firebaseID;

  DomainUser({
    required this.username,
    required this.email,
    required this.firebaseID,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firebaseID': firebaseID,
    };
  }

  factory DomainUser.fromMap(Map<String, dynamic> map) {
    return DomainUser(
      username: map['username'],
      email: map['email'],
      firebaseID: map['firebaseID'],
    );
  }
}