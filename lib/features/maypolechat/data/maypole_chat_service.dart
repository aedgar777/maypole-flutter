import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import '../domain/maypole.dart';
import '../domain/maypole_message.dart';

class MaypoleChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  /// Filter out messages from blocked users
  List<MaypoleMessage> _filterBlockedMessages(List<MaypoleMessage> messages) {
    final currentUser = AppSession().currentUser;
    if (currentUser == null) return messages;

    final blockedUserIds =
    currentUser.blockedUsers.map((user) => user.firebaseId).toSet();

    return messages
        .where((message) => !blockedUserIds.contains(message.senderId))
        .toList();
  }

  Future<Maypole?> getMaypoleById(String threadId) async {
    final maypoleDoc =
        await _firestore.collection('maypoles').doc(threadId).get();
    if (maypoleDoc.exists) {
      return Maypole.fromMap(maypoleDoc.data()!);
    }
    return null;
  }

  Stream<List<MaypoleMessage>> getMessages(String threadId) {
    return _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MaypoleMessage.fromMap(doc.data(), documentId: doc.id))
          .toList();
      return _filterBlockedMessages(messages);
    });
  }

  Future<List<MaypoleMessage>> getMoreMessages(
      String threadId, MaypoleMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    final messages = snapshot.docs
        .map((doc) => MaypoleMessage.fromMap(doc.data(), documentId: doc.id))
        .toList();
    return _filterBlockedMessages(messages);
  }

  Future<void> sendMessage(
    String threadId,
    String maypoleName,
    String body,
    DomainUser sender, {
        List<String> taggedUserIds = const [],
      }) async {
    final now = DateTime.now();
    final message = MaypoleMessage(
      senderName: sender.username,
      senderId: sender.firebaseID,
      senderProfilePictureUrl: sender.profilePictureUrl,
      timestamp: now,
      body: body,
      taggedUser: '',
      taggedUserIds: taggedUserIds,
    );

    final maypoleRef = _firestore.collection('maypoles').doc(threadId);
    final messageRef = maypoleRef.collection('messages').doc();

    final batch = _firestore.batch();

    // "Upsert" the maypole document: create if it doesn't exist, update if it does
    batch.set(
        maypoleRef,
        {
          'id': threadId,
          'name': maypoleName,
        },
        SetOptions(merge: true));

    // Add the new message to the subcollection
    batch.set(messageRef, message.toMap());

    // Check if user already has this maypole in their list (using local data)
    if (!sender.maypoleChatThreads.any((element) => element.id == threadId)) {
      final maypoleMetaData = MaypoleMetaData(
        id: threadId,
        name: maypoleName,
      );
      final userRef = _firestore.collection('users').doc(sender.firebaseID);
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    }

    await batch.commit();

    // Send notifications to tagged users
    if (taggedUserIds.isNotEmpty) {
      await _sendTagNotifications(
        taggedUserIds: taggedUserIds,
        senderName: sender.username,
        maypoleName: maypoleName,
        messageBody: body,
        threadId: threadId,
      );
    }
  }

  Future<void> sendMaypoleMessage(String threadId,
      String maypoleName,
      String body,
      DomainUser sender, {
        List<String> taggedUserIds = const [],
      }) async {
    final now = DateTime.now();
    final message = MaypoleMessage(
      senderName: sender.username,
      senderId: sender.firebaseID,
      senderProfilePictureUrl: sender.profilePictureUrl,
      timestamp: now,
      body: body,
      taggedUser: '',
      taggedUserIds: taggedUserIds,
    );

    final maypoleRef = _firestore.collection('maypoles').doc(threadId);
    final messageRef = maypoleRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(
        maypoleRef,
        {
          'id': threadId,
          'name': maypoleName,
        },
        SetOptions(merge: true));
    batch.set(messageRef, message.toMap());

    // Check if user already has this maypole in their list (using local data)
    if (!sender.maypoleChatThreads.any((element) => element.id == threadId)) {
      final maypoleMetaData =
      MaypoleMetaData(id: threadId, name: maypoleName);
      final userRef = _firestore.collection('users').doc(sender.firebaseID);
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    }

    await batch.commit();

    // Send notifications to tagged users
    if (taggedUserIds.isNotEmpty) {
      await _sendTagNotifications(
        taggedUserIds: taggedUserIds,
        senderName: sender.username,
        maypoleName: maypoleName,
        messageBody: body,
        threadId: threadId,
      );
    }
  }

  /// Send tag notifications to mentioned users
  Future<void> _sendTagNotifications({
    required List<String> taggedUserIds,
    required String senderName,
    required String maypoleName,
    required String messageBody,
    required String threadId,
  }) async {
    try {
      // Create a notification document for each tagged user
      for (final userId in taggedUserIds) {
        final notificationRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();

        await notificationRef.set({
          'type': 'tag',
          'senderName': senderName,
          'maypoleName': maypoleName,
          'messageBody': messageBody,
          'threadId': threadId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Error sending tag notifications: $e');
      // Don't throw - we don't want to fail message sending if notifications fail
    }
  }

  /// Removes a maypole thread from the user's list of maypole chats
  /// This only removes it from the user's personal list, not from Firebase
  Future<void> deleteMaypoleThreadForUser(String threadId, String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        debugPrint('User $userId does not exist');
        return;
      }
      
      final data = userDoc.data()!;
      final maypoleChatThreads = List<Map<String, dynamic>>.from(
        data['maypoleChatThreads'] ?? []
      );
      
      // Remove the thread with matching id
      maypoleChatThreads.removeWhere((thread) => thread['id'] == threadId);
      
      await userRef.update({
        'maypoleChatThreads': maypoleChatThreads,
      });
      
      debugPrint('✓ Removed maypole thread $threadId from user $userId\'s list');
    } catch (e) {
      debugPrint('❌ Error removing maypole thread from user: $e');
      rethrow;
    }
  }

  /// Completely deletes a maypole message from Firebase
  /// Only the sender can delete their own messages
  /// The message is removed for all users in the maypole chat
  Future<void> deleteMaypoleMessage(
    String threadId,
    String messageId,
    String userId,
  ) async {
    try {
      final messageRef = _firestore
          .collection('maypoles')
          .doc(threadId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        debugPrint('Message $messageId does not exist');
        return;
      }

      final data = messageDoc.data()!;
      final senderId = data['senderId'] as String?;

      // Only allow the sender to delete their own message
      if (senderId != userId) {
        throw Exception('You can only delete your own messages');
      }

      // Permanently delete the message from Firebase
      await messageRef.delete();

      debugPrint('✓ Permanently deleted maypole message $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting maypole message: $e');
      rethrow;
    }
  }
}
