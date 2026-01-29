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
        .snapshots(includeMetadataChanges: false) // Only emit when server updates, use cache in build()
        .map((snapshot) {
      // Log cache vs server source for monitoring
      if (snapshot.metadata.isFromCache) {
        debugPrint('📦 Maypole messages loaded from cache for thread: $threadId');
      } else {
        debugPrint('🌐 Maypole messages loaded from server for thread: $threadId');
      }
      
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

  /// Gets cached maypole messages if available
  /// Returns null if no cached data exists
  Future<List<MaypoleMessage>?> getCachedMessages(String threadId) async {
    try {
      final cacheSnapshot = await _firestore
          .collection('maypoles')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messageLimit)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isEmpty) {
        debugPrint('📦 No cached messages found for thread: $threadId');
        return null;
      }

      debugPrint('📦 Retrieved ${cacheSnapshot.docs.length} cached maypole messages for thread: $threadId');
      final messages = cacheSnapshot.docs
          .map((doc) => MaypoleMessage.fromMap(doc.data(), documentId: doc.id))
          .toList();
      return _filterBlockedMessages(messages);
    } catch (e) {
      debugPrint('⚠️ Cache miss for maypole thread $threadId: $e');
      return null;
    }
  }

  /// Peeks at the most recent message timestamp from server (lightweight query)
  /// This only fetches 1 document to check if cache is stale
  Future<DateTime?> getMostRecentMessageTimestamp(String threadId) async {
    try {
      final snapshot = await _firestore
          .collection('maypoles')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final timestamp = (snapshot.docs.first.data()['timestamp'] as Timestamp).toDate();
      debugPrint('🔍 Most recent message timestamp for $threadId: $timestamp');
      return timestamp;
    } catch (e) {
      debugPrint('⚠️ Error checking recent message timestamp: $e');
      return null;
    }
  }

  /// Smart cache strategy: Load cached messages immediately, then validate against server
  /// Returns a CacheValidationResult that indicates what action to take
  Future<CacheValidationResult> validateCachedMessages(
    String threadId,
    List<MaypoleMessage> cachedMessages,
  ) async {
    if (cachedMessages.isEmpty) {
      return CacheValidationResult.noCache;
    }

    // Get the most recent cached message timestamp
    final mostRecentCached = cachedMessages.first.timestamp;
    
    // Peek at server to check most recent message (only 1 document read!)
    final serverMostRecent = await getMostRecentMessageTimestamp(threadId);
    
    if (serverMostRecent == null) {
      // No messages on server, cache is fine
      debugPrint('✅ No server messages, using cache');
      return CacheValidationResult.cacheValid;
    }

    // Compare timestamps (allow 1 second tolerance for clock skew)
    final timeDiff = serverMostRecent.difference(mostRecentCached).inSeconds;
    
    if (timeDiff.abs() <= 1) {
      // Cache is current (within 1 second)
      debugPrint('✅ Cache is current for thread: $threadId');
      return CacheValidationResult.cacheValid;
    } else if (timeDiff > 0) {
      // Server has newer messages
      final newMessageCount = timeDiff ~/ 60; // Rough estimate
      debugPrint('⚠️ Cache is stale: ~$newMessageCount new messages since last visit');
      
      // Check if cached messages would still be in the "top 100" window
      // If hundreds of new messages exist, cached messages might be beyond the limit
      return CacheValidationResult.cacheStale;
    } else {
      // Cache is somehow newer than server (shouldn't happen, but handle gracefully)
      debugPrint('⚠️ Unusual: Cache appears newer than server');
      return CacheValidationResult.cacheValid;
    }
  }

  /// Fetches fresh messages from server
  Future<List<MaypoleMessage>> getFreshMessages(String threadId) async {
    debugPrint('🌐 Fetching fresh messages from server for thread: $threadId');
    final snapshot = await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .get(const GetOptions(source: Source.server));

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
        String address = '',
        double? latitude,
        double? longitude,
        double? senderLatitude,
        double? senderLongitude,
        String? placeType,
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
      senderLatitude: senderLatitude,
      senderLongitude: senderLongitude,
    );

    final maypoleRef = _firestore.collection('maypoles').doc(threadId);
    final messageRef = maypoleRef.collection('messages').doc();

    final batch = _firestore.batch();

    // "Upsert" the maypole document: create if it doesn't exist, update if it does
    final Map<String, dynamic> maypoleData = {
      'id': threadId,
      'name': maypoleName,
      'address': address,
    };
    
    // Add coordinates if provided
    if (latitude != null) {
      maypoleData['latitude'] = latitude;
    }
    if (longitude != null) {
      maypoleData['longitude'] = longitude;
    }
    if (placeType != null) {
      maypoleData['placeType'] = placeType;
    }
    
    batch.set(maypoleRef, maypoleData, SetOptions(merge: true));

    // Add the new message to the subcollection
    batch.set(messageRef, message.toMap());

    // Update or add the maypole thread in user's list with lastTypedAt timestamp
    final userRef = _firestore.collection('users').doc(sender.firebaseID);
    
    // Check if user already has this maypole in their list (using local data)
    final existingThreadIndex = sender.maypoleChatThreads.indexWhere((element) => element.id == threadId);
    
    if (existingThreadIndex == -1) {
      // Thread doesn't exist - add it with lastTypedAt
      final maypoleMetaData = MaypoleMetaData(
        id: threadId,
        name: maypoleName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        lastTypedAt: now,
        placeType: placeType,
      );
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    } else {
      // Thread exists - update lastTypedAt efficiently
      // We need to remove the old entry and add the updated one atomically
      final oldThread = sender.maypoleChatThreads[existingThreadIndex];
      final updatedThread = MaypoleMetaData(
        id: threadId,
        name: maypoleName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        lastTypedAt: now,
        placeType: placeType,
      );
      
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayRemove([oldThread.toMap()])
      });
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([updatedThread.toMap()])
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
        String address = '',
        String? placeType,
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
    
    final Map<String, dynamic> maypoleData = {
      'id': threadId,
      'name': maypoleName,
      'address': address,
    };
    if (placeType != null) {
      maypoleData['placeType'] = placeType;
    }
    
    batch.set(maypoleRef, maypoleData, SetOptions(merge: true));
    batch.set(messageRef, message.toMap());

    // Update or add the maypole thread in user's list with lastTypedAt timestamp
    final userRef = _firestore.collection('users').doc(sender.firebaseID);
    
    // Check if user already has this maypole in their list (using local data)
    final existingThreadIndex = sender.maypoleChatThreads.indexWhere((element) => element.id == threadId);
    
    if (existingThreadIndex == -1) {
      // Thread doesn't exist - add it with lastTypedAt
      final maypoleMetaData = MaypoleMetaData(
        id: threadId, 
        name: maypoleName, 
        address: address,
        lastTypedAt: now,
        placeType: placeType,
      );
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    } else {
      // Thread exists - update lastTypedAt efficiently
      final oldThread = sender.maypoleChatThreads[existingThreadIndex];
      final updatedThread = MaypoleMetaData(
        id: threadId, 
        name: maypoleName, 
        address: address,
        lastTypedAt: now,
        placeType: placeType,
      );
      
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayRemove([oldThread.toMap()])
      });
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([updatedThread.toMap()])
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

  /// Delete a message from a maypole thread
  Future<void> deleteMessage(
    String threadId,
    MaypoleMessage message,
  ) async {
    try {
      // Query for the message document by matching timestamp, senderId, and body
      final querySnapshot = await _firestore
          .collection('maypoles')
          .doc(threadId)
          .collection('messages')
          .where('timestamp', isEqualTo: Timestamp.fromDate(message.timestamp))
          .where('senderId', isEqualTo: message.senderId)
          .where('body', isEqualTo: message.body)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Adds a maypole thread to a user's maypoleChatThreads list
  /// This is called when a user opens a maypole on wide screen to make it immediately visible
  /// Note: lastTypedAt is null until the user sends their first message
  Future<void> addMaypoleToUserList({
    required String userId,
    required String placeId,
    required String placeName,
    required String address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final maypoleMetaData = MaypoleMetaData(
        id: placeId,
        name: placeName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        lastTypedAt: null, // Will be set when user sends first message
        placeType: placeType,
      );
      
      await userRef.update({
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
      
      debugPrint('✓ Added maypole $placeId to user $userId\'s list');
    } catch (e) {
      debugPrint('❌ Error adding maypole to user list: $e');
      rethrow;
    }
  }

  /// Removes a maypole thread from a user's maypoleChatThreads list
  /// This hides the thread from the user's list without deleting the maypole itself
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

/// Result of cache validation check
enum CacheValidationResult {
  /// No cached data available
  noCache,
  
  /// Cache is current and can be used
  cacheValid,
  
  /// Cache exists but is stale (server has newer messages)
  cacheStale,
}
