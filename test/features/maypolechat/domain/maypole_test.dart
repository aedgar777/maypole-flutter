import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/maypolechat/domain/maypole.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';

void main() {
  group('Maypole', () {
    test('creates instance with all fields', () {
      final messages = [
        MaypoleMessage(
          senderName: 'user1',
          senderId: 'id1',
          timestamp: DateTime(2024, 1, 1),
          body: 'Hello',
        ),
      ];

      final maypole = Maypole(
        id: 'maypole123',
        name: 'Test Place',
        messages: messages,
      );

      expect(maypole.id, 'maypole123');
      expect(maypole.name, 'Test Place');
      expect(maypole.messages.length, 1);
      expect(maypole.messages[0].body, 'Hello');
    });

    test('creates instance with empty messages', () {
      final maypole = Maypole(
        id: 'maypole123',
        name: 'Test Place',
        messages: const [],
      );

      expect(maypole.messages, isEmpty);
    });

    test('toMap serializes correctly', () {
      final timestamp = DateTime(2024, 1, 1);
      final messages = [
        MaypoleMessage(
          senderName: 'user1',
          senderId: 'id1',
          timestamp: timestamp,
          body: 'Hello',
        ),
      ];

      final maypole = Maypole(
        id: 'maypole123',
        name: 'Test Place',
        messages: messages,
      );

      final map = maypole.toMap();

      expect(map['id'], 'maypole123');
      expect(map['name'], 'Test Place');
      expect(map['messages'], isList);
      expect((map['messages'] as List).length, 1);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'maypole123',
        'name': 'Test Place',
        'messages': [
          {
            'senderName': 'user1',
            'senderId': 'id1',
            'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1)),
            'body': 'Hello',
            'taggedUser': '',
            'taggedUserIds': <String>[],
          },
        ],
      };

      final maypole = Maypole.fromMap(map);

      expect(maypole.id, 'maypole123');
      expect(maypole.name, 'Test Place');
      expect(maypole.messages.length, 1);
      expect(maypole.messages[0].body, 'Hello');
    });

    test('fromMap handles missing messages', () {
      final map = {
        'id': 'maypole123',
        'name': 'Test Place',
      };

      final maypole = Maypole.fromMap(map);

      expect(maypole.id, 'maypole123');
      expect(maypole.name, 'Test Place');
      expect(maypole.messages, isEmpty);
    });

    test('fromMap handles null values with defaults', () {
      final map = <String, dynamic>{
        'id': null,
        'name': null,
        'messages': null,
      };

      final maypole = Maypole.fromMap(map);

      expect(maypole.id, '');
      expect(maypole.name, '');
      expect(maypole.messages, isEmpty);
    });

    test('serialization round-trip preserves data', () {
      final original = Maypole(
        id: 'test123',
        name: 'Test Location',
        messages: [
          MaypoleMessage(
            senderName: 'sender',
            senderId: 'sender_id',
            timestamp: DateTime(2024, 1, 15, 10, 30),
            body: 'Test message',
          ),
        ],
      );

      final map = original.toMap();
      final restored = Maypole.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.messages.length, original.messages.length);
    });
  });

  group('MaypoleMetaData', () {
    test('creates instance with all fields', () {
      final metadata = MaypoleMetaData(
        id: 'meta123',
        name: 'Test Place',
      );

      expect(metadata.id, 'meta123');
      expect(metadata.name, 'Test Place');
    });

    test('toMap serializes correctly', () {
      final metadata = MaypoleMetaData(
        id: 'meta123',
        name: 'Test Place',
      );

      final map = metadata.toMap();

      expect(map['id'], 'meta123');
      expect(map['name'], 'Test Place');
      expect(map.length, 2);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'meta123',
        'name': 'Test Place',
      };

      final metadata = MaypoleMetaData.fromMap(map);

      expect(metadata.id, 'meta123');
      expect(metadata.name, 'Test Place');
    });

    test('fromMap handles null values with defaults', () {
      final map = <String, dynamic>{
        'id': null,
        'name': null,
      };

      final metadata = MaypoleMetaData.fromMap(map);

      expect(metadata.id, '');
      expect(metadata.name, '');
    });

    test('serialization round-trip preserves data', () {
      final original = MaypoleMetaData(
        id: 'test_id_123',
        name: 'Test Location Name',
      );

      final map = original.toMap();
      final restored = MaypoleMetaData.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });
  });
}
