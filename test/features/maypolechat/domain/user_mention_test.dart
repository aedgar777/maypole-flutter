import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';

void main() {
  group('UserMention', () {
    test('creates instance with all required fields', () {
      final mention = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );

      expect(mention.userId, 'user123');
      expect(mention.username, 'testuser');
      expect(mention.startIndex, 0);
      expect(mention.endIndex, 9);
    });

    test('toMap returns correct Map', () {
      final mention = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 5,
        endIndex: 14,
      );

      final map = mention.toMap();

      expect(map['userId'], 'user123');
      expect(map['username'], 'testuser');
      expect(map['startIndex'], 5);
      expect(map['endIndex'], 14);
      expect(map.length, 4);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'userId': 'user123',
        'username': 'testuser',
        'startIndex': 5,
        'endIndex': 14,
      };

      final mention = UserMention.fromMap(map);

      expect(mention.userId, 'user123');
      expect(mention.username, 'testuser');
      expect(mention.startIndex, 5);
      expect(mention.endIndex, 14);
    });

    test('equality operator works for identical mentions', () {
      final mention1 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );
      final mention2 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );

      expect(mention1 == mention2, isTrue);
    });

    test('equality operator works for different mentions', () {
      final mention1 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );
      final mention2 = UserMention(
        userId: 'user456',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );

      expect(mention1 == mention2, isFalse);
    });

    test('equality operator detects different indices', () {
      final mention1 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );
      final mention2 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 5,
        endIndex: 14,
      );

      expect(mention1 == mention2, isFalse);
    });

    test('hashCode is consistent for equal objects', () {
      final mention1 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );
      final mention2 = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 0,
        endIndex: 9,
      );

      expect(mention1.hashCode, mention2.hashCode);
    });

    test('toString returns formatted string', () {
      final mention = UserMention(
        userId: 'user123',
        username: 'testuser',
        startIndex: 5,
        endIndex: 14,
      );

      final str = mention.toString();

      expect(str, contains('user123'));
      expect(str, contains('testuser'));
      expect(str, contains('5'));
      expect(str, contains('14'));
    });

    test('serialization round-trip preserves data', () {
      final original = UserMention(
        userId: 'user_id_123',
        username: 'cool_user',
        startIndex: 10,
        endIndex: 20,
      );

      final map = original.toMap();
      final restored = UserMention.fromMap(map);

      expect(restored, original);
    });
  });
}
