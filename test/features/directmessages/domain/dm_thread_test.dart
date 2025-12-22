import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';

void main() {
  group('DMParticipant', () {
    test('creates instance with all fields', () {
      final participant = DMParticipant(
        id: 'user123',
        username: 'testuser',
        profilePicUrl: 'https://example.com/pic.jpg',
      );

      expect(participant.id, 'user123');
      expect(participant.username, 'testuser');
      expect(participant.profilePicUrl, 'https://example.com/pic.jpg');
    });

    test('toMap serializes correctly', () {
      final participant = DMParticipant(
        id: 'user123',
        username: 'testuser',
        profilePicUrl: 'https://example.com/pic.jpg',
      );

      final map = participant.toMap();

      expect(map['id'], 'user123');
      expect(map['username'], 'testuser');
      expect(map['profilePicUrl'], 'https://example.com/pic.jpg');
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'user123',
        'username': 'testuser',
        'profilePicUrl': 'https://example.com/pic.jpg',
      };

      final participant = DMParticipant.fromMap(map);

      expect(participant.id, 'user123');
      expect(participant.username, 'testuser');
      expect(participant.profilePicUrl, 'https://example.com/pic.jpg');
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final participant = DMParticipant.fromMap(map);

      expect(participant.id, '');
      expect(participant.username, '');
      expect(participant.profilePicUrl, '');
    });
  });

  group('DMThread', () {
    test('creates instance with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
        'user2': DMParticipant(id: 'user2', username: 'bob', profilePicUrl: ''),
      };

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: timestamp,
        participants: participants,
      );

      expect(thread.id, 'thread123');
      expect(thread.lastMessageTime, timestamp);
      expect(thread.participants.length, 2);
      expect(thread.lastMessage, isNull);
      expect(thread.hiddenFor, isEmpty);
    });

    test('creates instance with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
      };
      final lastMessage = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Last message',
      );

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: timestamp,
        participants: participants,
        lastMessage: lastMessage,
        hiddenFor: ['user1'],
      );

      expect(thread.lastMessage, isNotNull);
      expect(thread.lastMessage!.body, 'Last message');
      expect(thread.hiddenFor, ['user1']);
    });

    test('participantIds returns list of participant IDs', () {
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
        'user2': DMParticipant(id: 'user2', username: 'bob', profilePicUrl: ''),
      };

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: DateTime.now(),
        participants: participants,
      );

      final ids = thread.participantIds;
      expect(ids.length, 2);
      expect(ids, contains('user1'));
      expect(ids, contains('user2'));
    });

    test('isHiddenFor returns true when user is in hiddenFor list', () {
      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: DateTime.now(),
        participants: {},
        hiddenFor: ['user1', 'user3'],
      );

      expect(thread.isHiddenFor('user1'), isTrue);
      expect(thread.isHiddenFor('user3'), isTrue);
    });

    test('isHiddenFor returns false when user is not in hiddenFor list', () {
      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: DateTime.now(),
        participants: {},
        hiddenFor: ['user1'],
      );

      expect(thread.isHiddenFor('user2'), isFalse);
    });

    test('getPartner returns the other participant', () {
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: 'pic1.jpg'),
        'user2': DMParticipant(id: 'user2', username: 'bob', profilePicUrl: 'pic2.jpg'),
      };

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: DateTime.now(),
        participants: participants,
      );

      final partner = thread.getPartner('user1');
      expect(partner, isNotNull);
      expect(partner!.id, 'user2');
      expect(partner.username, 'bob');
    });

    test('getPartner returns empty participant when no other user found', () {
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
      };

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: DateTime.now(),
        participants: participants,
      );

      final partner = thread.getPartner('user1');
      expect(partner, isNotNull);
      expect(partner!.id, '');
    });

    test('toMap serializes correctly without lastMessage', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
      };

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: timestamp,
        participants: participants,
        hiddenFor: ['user1'],
      );

      final map = thread.toMap();

      expect(map['id'], 'thread123');
      expect(map['lastMessageTime'], isA<Timestamp>());
      expect(map['participants'], isA<Map>());
      expect(map['participantIds'], ['user1']);
      expect(map['hiddenFor'], ['user1']);
      expect(map['lastMessage'], isNull);
    });

    test('toMap serializes correctly with lastMessage', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: ''),
      };
      final lastMessage = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Hello',
      );

      final thread = DMThread(
        id: 'thread123',
        lastMessageTime: timestamp,
        participants: participants,
        lastMessage: lastMessage,
      );

      final map = thread.toMap();

      expect(map['lastMessage'], isNotNull);
      expect(map['lastMessage']['body'], 'Hello');
    });

    test('fromMap deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'id': 'thread123',
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'participants': {
          'user1': {
            'id': 'user1',
            'username': 'alice',
            'profilePicUrl': 'pic1.jpg',
          },
          'user2': {
            'id': 'user2',
            'username': 'bob',
            'profilePicUrl': 'pic2.jpg',
          },
        },
        'hiddenFor': ['user1'],
        'lastMessage': {
          'sender': 'user1',
          'recipient': 'user2',
          'timestamp': Timestamp.fromDate(timestamp),
          'body': 'Hello',
        },
      };

      final thread = DMThread.fromMap(map);

      expect(thread.id, 'thread123');
      expect(thread.lastMessageTime, timestamp);
      expect(thread.participants.length, 2);
      expect(thread.participants['user1']!.username, 'alice');
      expect(thread.hiddenFor, ['user1']);
      expect(thread.lastMessage, isNotNull);
      expect(thread.lastMessage!.body, 'Hello');
    });

    test('fromMap handles missing optional fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'id': 'thread123',
        'lastMessageTime': Timestamp.fromDate(timestamp),
      };

      final thread = DMThread.fromMap(map);

      expect(thread.id, 'thread123');
      expect(thread.participants, isEmpty);
      expect(thread.hiddenFor, isEmpty);
      expect(thread.lastMessage, isNull);
    });

    test('serialization round-trip preserves data', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final participants = {
        'user1': DMParticipant(id: 'user1', username: 'alice', profilePicUrl: 'pic1.jpg'),
        'user2': DMParticipant(id: 'user2', username: 'bob', profilePicUrl: 'pic2.jpg'),
      };
      final lastMessage = DirectMessage(
        sender: 'user1',
        recipient: 'user2',
        timestamp: timestamp,
        body: 'Test message',
      );

      final original = DMThread(
        id: 'thread_test_123',
        lastMessageTime: timestamp,
        participants: participants,
        lastMessage: lastMessage,
        hiddenFor: ['user1'],
      );

      final map = original.toMap();
      final restored = DMThread.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.lastMessageTime, original.lastMessageTime);
      expect(restored.participants.length, original.participants.length);
      expect(restored.hiddenFor, original.hiddenFor);
      expect(restored.lastMessage!.body, original.lastMessage!.body);
    });
  });

  group('DMThreadMetaData', () {
    test('creates instance with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final metadata = DMThreadMetaData(
        id: 'thread123',
        name: 'Chat with Bob',
        lastMessageTime: timestamp,
        partnerName: 'Bob',
        partnerId: 'user2',
        partnerProfpic: 'pic2.jpg',
      );

      expect(metadata.id, 'thread123');
      expect(metadata.name, 'Chat with Bob');
      expect(metadata.lastMessageTime, timestamp);
      expect(metadata.partnerName, 'Bob');
      expect(metadata.partnerId, 'user2');
      expect(metadata.partnerProfpic, 'pic2.jpg');
    });

    test('toMap serializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final metadata = DMThreadMetaData(
        id: 'thread123',
        name: 'Chat with Bob',
        lastMessageTime: timestamp,
        partnerName: 'Bob',
        partnerId: 'user2',
        partnerProfpic: 'pic2.jpg',
      );

      final map = metadata.toMap();

      expect(map['id'], 'thread123');
      expect(map['name'], 'Chat with Bob');
      expect(map['lastMessageTime'], isA<Timestamp>());
      expect(map['partnerName'], 'Bob');
      expect(map['partnerId'], 'user2');
      expect(map['partnerProfpic'], 'pic2.jpg');
    });

    test('fromMap deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'id': 'thread123',
        'name': 'Chat with Bob',
        'lastMessageTime': Timestamp.fromDate(timestamp),
        'partnerName': 'Bob',
        'partnerId': 'user2',
        'partnerProfpic': 'pic2.jpg',
      };

      final metadata = DMThreadMetaData.fromMap(map);

      expect(metadata.id, 'thread123');
      expect(metadata.name, 'Chat with Bob');
      expect(metadata.lastMessageTime, timestamp);
      expect(metadata.partnerName, 'Bob');
      expect(metadata.partnerId, 'user2');
      expect(metadata.partnerProfpic, 'pic2.jpg');
    });

    test('fromMap handles missing fields with defaults', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'lastMessageTime': Timestamp.fromDate(timestamp),
      };

      final metadata = DMThreadMetaData.fromMap(map);

      expect(metadata.id, '');
      expect(metadata.name, '');
      expect(metadata.partnerName, '');
      expect(metadata.partnerId, '');
      expect(metadata.partnerProfpic, '');
    });

    test('serialization round-trip preserves data', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final original = DMThreadMetaData(
        id: 'test_thread_123',
        name: 'Test Chat',
        lastMessageTime: timestamp,
        partnerName: 'Partner',
        partnerId: 'partner_id',
        partnerProfpic: 'partner.jpg',
      );

      final map = original.toMap();
      final restored = DMThreadMetaData.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.lastMessageTime, original.lastMessageTime);
      expect(restored.partnerName, original.partnerName);
      expect(restored.partnerId, original.partnerId);
      expect(restored.partnerProfpic, original.partnerProfpic);
    });
  });
}
