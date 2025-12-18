import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';

import '../domain/direct_message.dart';

class DMThreadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  /// Generates a deterministic conversation ID for a DM thread between two users.
  /// The ID is the same regardless of which user initiates the conversation.
  /// 
  /// Example: generateThreadId('user123', 'user456') == generateThreadId('user456', 'user123')
  String generateThreadId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<DMThread?> getDMThreadById(String threadId) async {
    final dmThreadDoc =
    await _firestore.collection('DMThreads').doc(threadId).get();
    if (dmThreadDoc.exists) {
      return DMThread.fromMap(dmThreadDoc.data()!);
    }
    return null;
  }

  /// Gets or creates a DM thread between two users.
  /// Uses the deterministic thread ID generation to ensure consistency.
  /// Throws an exception if either user has blocked the other.
  Future<DMThread> getOrCreateDMThread({
    required String currentUserId,
    required String currentUsername,
    required String currentUserProfpic,
    required String partnerId,
    required String partnerName,
    required String partnerProfpic,
  }) async {
    // Check if current user has blocked the partner
    final currentUser = AppSession().currentUser;
    if (currentUser != null) {
      final isBlocked = currentUser.blockedUsers
          .any((user) => user.firebaseId == partnerId);
      if (isBlocked) {
        throw Exception('Cannot create DM thread with blocked user');
      }
    }

    // Note: We don't check if partner has blocked current user here due to
    // Firestore security rules preventing reading other users' documents.
    // The partner's client will handle blocking/filtering messages from blocked users.

    final threadId = generateThreadId(currentUserId, partnerId);

    // Try to get existing thread
    final existingThread = await getDMThreadById(threadId);
    if (existingThread != null) {
      debugPrint('✓ Found existing DM thread: $threadId');
      return existingThread;
    }

    // Create new thread if it doesn't exist
    final now = DateTime.now();
    final newThread = DMThread(
      id: threadId,
      lastMessageTime: now,
      participants: {
        currentUserId: DMParticipant(
          id: currentUserId,
          username: currentUsername,
          profilePicUrl: currentUserProfpic,
        ),
        partnerId: DMParticipant(
          id: partnerId,
          username: partnerName,
          profilePicUrl: partnerProfpic,
        ),
      },
      lastMessage: null,
    );

    // Save to Firestore - only one write needed!
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .set(newThread.toMap());

    debugPrint('✓ Created DM thread: $threadId with participants: [$currentUserId, $partnerId]');

    return newThread;
  }

  Stream<List<DirectMessage>> getDmMessages(String threadId) {
    return _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DirectMessage.fromMap(doc.data()))
            .toList());
  }

  Future<List<DirectMessage>> getMoreDmMessages(String threadId, DirectMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => DirectMessage.fromMap(doc.data())).toList();
  }

  Future<void> sendDmMessage(String threadId,
      String body,
      String senderId,
      String senderUsername,
      String recipientId,) async {
    final now = DateTime.now();
    final message = DirectMessage(
      sender: senderUsername,
      timestamp: now,
      body: body,
      recipient: recipientId,
    );

    // Add message to thread's messages subcollection
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());

    // Get current hiddenFor list
    final threadDoc = await _firestore.collection('DMThreads').doc(threadId).get();
    final data = threadDoc.data();
    final hiddenFor = List<String>.from(data?['hiddenFor'] ?? []);
    
    // Remove both users from hiddenFor list (unhide for both when message is sent)
    hiddenFor.removeWhere((id) => id == senderId || id == recipientId);

    // Update thread's lastMessage, lastMessageTime, and unhide for both users
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .update({
      'lastMessage': message.toMap(),
      'lastMessageTime': Timestamp.fromDate(now),
      'hiddenFor': hiddenFor,
    });

    debugPrint('✓ Sent DM message to thread: $threadId');

    // Send notification to recipient
    await _sendDmNotification(
      recipientId: recipientId,
      senderUsername: senderUsername,
      messageBody: body,
      threadId: threadId,
    );
  }

  /// Streams all DM threads for a user, ordered by most recent activity
  /// This replaces the old approach of storing dmThreads in user documents
  Stream<List<DMThreadMetaData>> getUserDmThreads(String userId) {
    return _firestore
        .collection('DMThreads')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('❌ Error in DM threads stream: $error');
      debugPrint('⚠️ This might be a missing Firestore index!');
      debugPrint('⚠️ Check the error message for a link to create the index');
      debugPrint('⚠️ Or run: firebase deploy --only firestore:indexes');
      // Re-throw to propagate to UI
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          
          // Check if this is an old-format thread (missing participants field)
          if (!data.containsKey('participants') || data['participants'] == null) {
            debugPrint('⚠️ Skipping old-format DM thread ${doc.id} - needs migration');
            return null;
          }
          
          final participantsMap = data['participants'] as Map<String, dynamic>?;
          if (participantsMap == null || participantsMap.isEmpty) {
            return null;
          }
          
          final dmThread = DMThread.fromMap(data);
          
          // Filter out threads that are hidden for this user
          if (dmThread.isHiddenFor(userId)) {
            return null;
          }
          
          // Get the partner (the other participant)
          final partner = dmThread.getPartner(userId);
          
          if (partner == null || partner.id.isEmpty) {
            return null;
          }
          
          // Convert to DMThreadMetaData from the user's perspective
          return DMThreadMetaData(
            id: dmThread.id,
            name: partner.username,
            lastMessageTime: dmThread.lastMessageTime,
            partnerName: partner.username,
            partnerId: partner.id,
            partnerProfpic: partner.profilePicUrl,
          );
        } catch (e) {
          debugPrint('Error processing DM thread ${doc.id}: $e');
          return null;
        }
      }).whereType<DMThreadMetaData>().toList();
    });
  }

  /// Hides a DM thread for a specific user by adding them to the hiddenFor list
  /// The thread will reappear when a new message is sent
  Future<void> deleteDMThreadForUser(String threadId, String userId) async {
    try {
      final threadDoc = await _firestore.collection('DMThreads').doc(threadId).get();
      
      if (!threadDoc.exists) {
        debugPrint('Thread $threadId does not exist');
        return;
      }
      
      final data = threadDoc.data()!;
      final hiddenFor = List<String>.from(data['hiddenFor'] ?? []);
      
      // Add user to hiddenFor list if not already there
      if (!hiddenFor.contains(userId)) {
        hiddenFor.add(userId);
        
        await _firestore.collection('DMThreads').doc(threadId).update({
          'hiddenFor': hiddenFor,
        });
        
        debugPrint('✓ Hidden DM thread $threadId for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Error hiding DM thread for user: $e');
      rethrow;
    }
  }

  /// Send DM notification to recipient
  Future<void> _sendDmNotification({
    required String recipientId,
    required String senderUsername,
    required String messageBody,
    required String threadId,
  }) async {
    try {
      // Create a notification document for the recipient
      final notificationRef = _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc();

      await notificationRef.set({
        'type': 'dm',
        'senderName': senderUsername,
        'messageBody': messageBody,
        'threadId': threadId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error sending DM notification: $e');
      // Don't throw - we don't want to fail message sending if notifications fail
    }
  }
}
