import 'maypole_message.dart';

// Subclass for place-based home threads
class Maypole {
  final String id;
  final String name;
  final List<MaypoleMessage> messages;

  const Maypole({
    required this.id,
    required this.name,
    required this.messages,
  });

  factory Maypole.fromMap(Map<String, dynamic> map) {
    return Maypole(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      messages: (map['messages'] as List<dynamic>?)
          ?.map((e) => MaypoleMessage.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((e) => e.toMap()).toList(),
    };
  }
}

class MaypoleMetaData {
  final String id;
  final String name;
  final String address;

  const MaypoleMetaData({
    required this.id,
    required this.name,
    this.address = '',
  });

  factory MaypoleMetaData.fromMap(Map<String, dynamic> map) {
    return MaypoleMetaData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}
