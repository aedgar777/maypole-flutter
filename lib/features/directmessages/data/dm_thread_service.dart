import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Creates a local-only ephemeral DM thread (not persisted to Firestore yet)
  DMThread createEphemeralThread({
    required String threadId,
    required String currentUserId,
    required String currentUsername,
    required String currentUserProfpic,
    required String partnerId,
    required String partnerName,
    required String partnerProfpic,
  }) {
    final now = DateTime.now();
    return DMThread(
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
      hasMessages: false,
    );
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
      hasMessages: false, // New threads start without messages
    );

    // Save to Firestore - only one write needed!
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .set(newThread.toMap());


    return newThread;
  }

  Stream<List<DirectMessage>> getDmMessages(String threadId) {
    return _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots(includeMetadataChanges: false) // Only emit when server updates, use cache in build()
        .map((snapshot) {
      // Log cache vs server source for monitoring
      if (snapshot.metadata.isFromCache) {
      } else {
      }
      
      return snapshot.docs
          .map((doc) => DirectMessage.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
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

    return snapshot.docs.map((doc) => DirectMessage.fromMap(doc.data(), documentId: doc.id)).toList();
  }

  /// Gets DM messages from cache first, falls back to server if cache miss
  /// This is useful for initial loads to show cached data immediately
  Future<List<DirectMessage>> getCachedDmMessages(String threadId) async {
    try {
      // Try cache first
      final cacheSnapshot = await _firestore
          .collection('DMThreads')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messageLimit)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return cacheSnapshot.docs
            .map((doc) => DirectMessage.fromMap(doc.data(), documentId: doc.id))
            .toList();
      }
    } catch (e) {
    }

    // Cache miss or error - fetch from server
    final serverSnapshot = await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .get(const GetOptions(source: Source.server));

    return serverSnapshot.docs
        .map((doc) => DirectMessage.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  Future<void> sendDmMessage(
    String threadId,
    String body,
    String senderId,
    String senderUsername,
    String recipientId, {
    List<String> imageUrls = const [],
    DMThread? ephemeralThread,  // Optional ephemeral thread to persist if thread doesn't exist
  }) async {
    final now = DateTime.now();
    final message = DirectMessage(
      sender: senderUsername,
      timestamp: now,
      body: body,
      recipient: recipientId,
      imageUrls: imageUrls,
    );

    // Check if thread exists in Firestore
    final threadDoc = await _firestore.collection('DMThreads').doc(threadId).get();
    
    if (!threadDoc.exists) {
      // Thread doesn't exist - this is an ephemeral thread being persisted
      if (ephemeralThread != null) {
        // Save the ephemeral thread to Firestore first
        await _firestore
            .collection('DMThreads')
            .doc(threadId)
            .set(ephemeralThread.toMap());
      } else {
        throw Exception('Thread does not exist and no ephemeral thread provided');
      }
    }

    // Add message to thread's messages subcollection
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());

    // Get current hiddenFor list
    final data = threadDoc.data();
    final hiddenFor = List<String>.from(data?['hiddenFor'] ?? []);
    
    // Remove both users from hiddenFor list (unhide for both when message is sent)
    hiddenFor.removeWhere((id) => id == senderId || id == recipientId);

    // Update thread's lastMessage, lastMessageTime, unhide for both users,
    // mark as unread for recipient, and set hasMessages to true
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .update({
      'lastMessage': message.toMap(),
      'lastMessageTime': Timestamp.fromDate(now),
      'hiddenFor': hiddenFor,
      'hasMessages': true,  // Mark that this thread now has messages
      'unreadBy.$recipientId': true,  // Mark as unread for recipient
      'unreadBy.$senderId': false,    // Mark as read for sender
    });


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
        .snapshots(includeMetadataChanges: true)
        .handleError((error) {
      // Re-throw to propagate to UI
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          
          // Check if this thread is hidden for the current user
          final hiddenFor = List<String>.from(data['hiddenFor'] ?? []);
          if (hiddenFor.contains(userId)) {
            return null;
          }
          
          // Check if this thread has messages (skip ephemeral threads without messages)
          final hasMessages = data['hasMessages'] ?? false;
          if (!hasMessages) {
            return null;
          }
          
          // Check if this is an old-format thread (missing participants field)
          if (!data.containsKey('participants') || data['participants'] == null) {
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
            lastMessageBody: dmThread.lastMessage?.body,
            hasUnread: dmThread.hasUnreadMessagesFor(userId),
          );
        } catch (e) {
          return null;
        }
      }).whereType<DMThreadMetaData>().toList();
    });
  }

  /// Marks all messages in a DM thread as read for a specific user
  Future<void> markThreadAsRead(String threadId, String userId) async {
    try {
      await _firestore.collection('DMThreads').doc(threadId).update({
        'unreadBy.$userId': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Hides a DM thread for a specific user by adding them to the hiddenFor list
  /// The thread will reappear when a new message is sent
  Future<void> deleteDMThreadForUser(String threadId, String userId) async {
    try {
      final threadDoc = await _firestore.collection('DMThreads').doc(threadId).get();

      if (!threadDoc.exists) {
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

      }
    } catch (e) {
      rethrow;
    }
  }

  /// Unhides a DM thread for a specific user by removing them from the hiddenFor list
  Future<void> unhideDMThreadForUser(String threadId, String userId) async {
    try {
      final threadDoc = await _firestore.collection('DMThreads').doc(threadId).get();

      if (!threadDoc.exists) {
        return;
      }

      final data = threadDoc.data()!;
      final hiddenFor = List<String>.from(data['hiddenFor'] ?? []);

      if (hiddenFor.contains(userId)) {
        hiddenFor.remove(userId);

        await _firestore.collection('DMThreads').doc(threadId).update({
          'hiddenFor': hiddenFor,
        });

      }
    } catch (e) {
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
      // Don't throw - we don't want to fail message sending if notifications fail
    }
  }

  /// Deletes a DM message for a specific user by adding them to deletedFor list
  /// Only the sender can delete their own messages
  /// The message will be displayed as "message deleted" instead of disappearing
  Future<void> deleteDmMessage(
    String threadId,
    String messageId,
    String userId,
    String username,
  ) async {
    try {
      final messageRef = _firestore
          .collection('DMThreads')
          .doc(threadId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        return;
      }

      final data = messageDoc.data()!;
      final sender = data['sender'] as String?;

      // Only allow the sender to delete their own message
      if (sender != username) {
        throw Exception('You can only delete your own messages');
      }

      final deletedFor = List<String>.from(data['deletedFor'] ?? []);

      // Add user to deletedFor list if not already there
      if (!deletedFor.contains(userId)) {
        deletedFor.add(userId);

        // Clear the message body and images when deleting
        await messageRef.update({
          'deletedFor': deletedFor,
          'body': '', // Clear the text
          'imageUrls': [], // Clear the images
        });

      }
    } catch (e) {
      rethrow;
    }
  }
}
