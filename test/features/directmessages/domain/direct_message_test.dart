import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';

void main() {
  group('DirectMessage', () {
    test('creates instance with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Hello!',
      );

      expect(message.sender, 'user1');
      expect(message.recipient, 'user2');
      expect(message.timestamp, timestamp);
      expect(message.body, 'Hello!');
      expect(message.id, isNull);
      expect(message.deletedFor, isEmpty);
    });

    test('creates instance with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = DirectMessage(
        id: 'msg123',
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Hello!',
        deletedFor: ['user1'],
      );

      expect(message.id, 'msg123');
      expect(message.deletedFor, ['user1']);
    });

    test('toMap serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Hello!',
        deletedFor: ['user1', 'user2'],
      );

      final map = message.toMap();

      expect(map['type'], 'direct');
      expect(map['sender'], 'user1');
      expect(map['recipient'], 'user2');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['body'], 'Hello!');
      expect(map['deletedFor'], ['user1', 'user2']);
    });

    test('fromMap deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'sender': 'user1',
        'recipient': 'user2',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello!',
        'deletedFor': ['user1'],
      };

      final message = DirectMessage.fromMap(map, documentId: 'msg123');

      expect(message.id, 'msg123');
      expect(message.sender, 'user1');
      expect(message.recipient, 'user2');
      expect(message.timestamp, timestamp);
      expect(message.body, 'Hello!');
      expect(message.deletedFor, ['user1']);
    });

    test('fromMap handles missing deletedFor with default empty list', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'sender': 'user1',
        'recipient': 'user2',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello!',
      };

      final message = DirectMessage.fromMap(map);

      expect(message.deletedFor, isEmpty);
    });

    test('fromMap handles null deletedFor', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'sender': 'user1',
        'recipient': 'user2',
        'timestamp': Timestamp.fromDate(timestamp),
        'body': 'Hello!',
        'deletedFor': null,
      };

      final message = DirectMessage.fromMap(map);

      expect(message.deletedFor, isEmpty);
    });

    test('isDeletedFor returns true when user is in deletedFor list', () {
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: DateTime.now(),
        body: 'Test',
        deletedFor: ['user1', 'user3'],
      );

      expect(message.isDeletedFor('user1'), isTrue);
      expect(message.isDeletedFor('user3'), isTrue);
    });

    test('isDeletedFor returns false when user is not in deletedFor list', () {
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: DateTime.now(),
        body: 'Test',
        deletedFor: ['user1'],
      );

      expect(message.isDeletedFor('user2'), isFalse);
      expect(message.isDeletedFor('user3'), isFalse);
    });

    test('isDeletedFor returns false when deletedFor is empty', () {
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: DateTime.now(),
        body: 'Test',
      );

      expect(message.isDeletedFor('user1'), isFalse);
      expect(message.isDeletedFor('user2'), isFalse);
    });

    test('serialization round-trip preserves data', () {
      final original = DirectMessage(
        id: 'test_msg_123',
        sender: 'sender_user',
        recipient: 'recipient_user',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        body: 'Test message content',
        deletedFor: ['user1', 'user2'],
      );

      final map = original.toMap();
      final restored = DirectMessage.fromMap(map, documentId: original.id);

      expect(restored.id, original.id);
      expect(restored.sender, original.sender);
      expect(restored.recipient, original.recipient);
      expect(restored.timestamp, original.timestamp);
      expect(restored.body, original.body);
      expect(restored.deletedFor, original.deletedFor);
    });

    test('handles empty body', () {
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: DateTime.now(),
        body: '',
      );

      expect(message.body, '');
    });

    test('handles long message body', () {
      final longBody = 'A' * 10000;
      final message = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: DateTime.now(),
        body: longBody,
      );

      expect(message.body.length, 10000);
    });
  });
}
