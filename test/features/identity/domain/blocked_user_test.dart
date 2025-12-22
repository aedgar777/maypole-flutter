import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/identity/domain/blocked_user.dart';

void main() {
  group('BlockedUser', () {
    test('creates instance with required fields', () {
      final blockedUser = BlockedUser(
        username: 'blocked_user',
        firebaseId: 'firebase123',
      );

      expect(blockedUser.username, 'blocked_user');
      expect(blockedUser.firebaseId, 'firebase123');
    });

    test('toMap returns correct Map', () {
      final blockedUser = BlockedUser(
        username: 'blocked_user',
        firebaseId: 'firebase123',
      );

      final map = blockedUser.toMap();

      expect(map['username'], 'blocked_user');
      expect(map['firebaseId'], 'firebase123');
      expect(map.length, 2);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'username': 'blocked_user',
        'firebaseId': 'firebase123',
      };

      final blockedUser = BlockedUser.fromMap(map);

      expect(blockedUser.username, 'blocked_user');
      expect(blockedUser.firebaseId, 'firebase123');
    });

    test('equality operator works correctly for same firebaseId', () {
      final user1 = BlockedUser(
        username: 'user1',
        firebaseId: 'firebase123',
      );
      final user2 = BlockedUser(
        username: 'user2', // Different username
        firebaseId: 'firebase123', // Same firebaseId
      );

      expect(user1 == user2, isTrue);
    });

    test('equality operator works correctly for different firebaseId', () {
      final user1 = BlockedUser(
        username: 'user1',
        firebaseId: 'firebase123',
      );
      final user2 = BlockedUser(
        username: 'user1',
        firebaseId: 'firebase456',
      );

      expect(user1 == user2, isFalse);
    });

    test('hashCode is based on firebaseId', () {
      final user1 = BlockedUser(
        username: 'user1',
        firebaseId: 'firebase123',
      );
      final user2 = BlockedUser(
        username: 'user2',
        firebaseId: 'firebase123',
      );

      expect(user1.hashCode, user2.hashCode);
    });

    test('serialization round-trip preserves data', () {
      final original = BlockedUser(
        username: 'test_user',
        firebaseId: 'test_id_123',
      );

      final map = original.toMap();
      final restored = BlockedUser.fromMap(map);

      expect(restored.username, original.username);
      expect(restored.firebaseId, original.firebaseId);
    });
  });
}
