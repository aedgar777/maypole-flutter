import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';

void main() {
  group('MaypoleMessage', () {
    test('creates instance with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = MaypoleMessage(
        senderName: 'testuser',
        senderId: 'user123',
        timestamp: timestamp,
        body: 'Hello world',
      );

      expect(message.senderName, 'testuser');
      expect(message.senderId, 'user123');
      expect(message.timestamp, timestamp);
      expect(message.body, 'Hello world');
      expect(message.id, isNull);
      expect(message.senderProfilePictureUrl, '');
      expect(message.taggedUser, '');
      expect(message.taggedUserIds, isEmpty);
    });

    test('creates instance with all optional fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = MaypoleMessage(
        id: 'msg123',
        senderName: 'testuser',
        senderId: 'user123',
        senderProfilePictureUrl: 'https://example.com/pic.jpg',
        timestamp: timestamp,
        body: 'Hello @user2',
        taggedUser: 'user2',
        taggedUserIds: ['user2_id'],
      );

      expect(message.id, 'msg123');
      expect(message.senderProfilePictureUrl, 'https://example.com/pic.jpg');
      expect(message.taggedUser, 'user2');
      expect(message.taggedUserIds, ['user2_id']);
    });

    test('toMap serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = MaypoleMessage(
        senderName: 'testuser',
        senderId: 'user123',
        senderProfilePictureUrl: 'https://example.com/pic.jpg',
        timestamp: timestamp,
        body: 'Hello',
        taggedUser: 'user2',
        taggedUserIds: ['user2_id', 'user3_id'],
      );

      final map = message.toMap();

      expect(map['type'], 'place');
      expect(map['senderName'], 'testuser');
      expect(map['senderId'], 'user123');
      expect(map['senderProfilePictureUrl'], 'https://example.com/pic.jpg');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['body'], 'Hello');
      expect(map['taggedUser'], 'user2');
      expect(map['taggedUserIds'], ['user2_id', 'user3_id']);
    });

    test('fromMap deserializes correctly with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'senderName': 'testuser',
        'senderId': 'user123',
        'senderProfilePictureUrl': 'https://example.com/pic.jpg',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello',
        'taggedUser': 'user2',
        'taggedUserIds': ['user2_id', 'user3_id'],
      };

      final message = MaypoleMessage.fromMap(map, documentId: 'msg123');

      expect(message.id, 'msg123');
      expect(message.senderName, 'testuser');
      expect(message.senderId, 'user123');
      expect(message.senderProfilePictureUrl, 'https://example.com/pic.jpg');
      expect(message.timestamp, timestamp);
      expect(message.body, 'Hello');
      expect(message.taggedUser, 'user2');
      expect(message.taggedUserIds, ['user2_id', 'user3_id']);
    });

    test('fromMap handles legacy sender field', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'sender': 'legacy_user', // Legacy field
        'senderId': 'user123',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello',
      };

      final message = MaypoleMessage.fromMap(map);

      expect(message.senderName, 'legacy_user');
    });

    test('fromMap handles missing optional fields with defaults', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello',
      };

      final message = MaypoleMessage.fromMap(map);

      expect(message.id, isNull);
      expect(message.senderName, '');
      expect(message.senderId, '');
      expect(message.senderProfilePictureUrl, '');
      expect(message.taggedUser, '');
      expect(message.taggedUserIds, isEmpty);
    });

    test('fromMap handles null taggedUserIds', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'senderName': 'testuser',
        'senderId': 'user123',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello',
        'taggedUserIds': null,
      };

      final message = MaypoleMessage.fromMap(map);

      expect(message.taggedUserIds, isEmpty);
    });

    test('serialization round-trip preserves data', () {
      final original = MaypoleMessage(
        id: 'msg_test_123',
        senderName: 'user1',
        senderId: 'id1',
        senderProfilePictureUrl: 'https://pic.com/1.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        body: 'Test message with @mention',
        taggedUser: 'mentioned_user',
        taggedUserIds: ['mention_id_1', 'mention_id_2'],
      );

      final map = original.toMap();
      final restored = MaypoleMessage.fromMap(map, documentId: original.id);

      expect(restored.id, original.id);
      expect(restored.senderName, original.senderName);
      expect(restored.senderId, original.senderId);
      expect(restored.senderProfilePictureUrl, original.senderProfilePictureUrl);
      expect(restored.timestamp, original.timestamp);
      expect(restored.body, original.body);
      expect(restored.taggedUser, original.taggedUser);
      expect(restored.taggedUserIds, original.taggedUserIds);
    });

    test('handles multiple tagged users correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = MaypoleMessage(
        senderName: 'testuser',
        senderId: 'user123',
        timestamp: timestamp,
        body: 'Hello @user1 and @user2',
        taggedUserIds: ['user1_id', 'user2_id', 'user3_id'],
      );

      expect(message.taggedUserIds.length, 3);
      expect(message.taggedUserIds, contains('user1_id'));
      expect(message.taggedUserIds, contains('user2_id'));
      expect(message.taggedUserIds, contains('user3_id'));
    });
  });
}
