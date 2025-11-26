import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/features/identity/domain/domain_user.dart';

/// Service for searching users in the system
class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for users in a specific maypole thread by username prefix
  /// Returns users who have posted in this maypole
  Future<List<DomainUser>> searchUsersInMaypole(String threadId,
      String query,) async {
    if (query.isEmpty) return [];

    try {
      // Get recent messages from the maypole to find active users
      final messagesSnapshot = await _firestore
          .collection('maypoles')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(200) // Look at recent messages
          .get();

      // Extract unique sender usernames
      final senderUsernames = <String>{};
      for (var doc in messagesSnapshot.docs) {
        final sender = doc.data()['sender'] as String?;
        if (sender != null && sender.isNotEmpty) {
          senderUsernames.add(sender);
        }
      }

      if (senderUsernames.isEmpty) return [];

      // Search for users whose username starts with the query
      final queryLower = query.toLowerCase();
      final matchingUsers = <DomainUser>[];

      // Fetch user documents for the senders
      // We'll do this in batches to avoid too many reads
      final usernamesToFetch = senderUsernames
          .where((username) => username.toLowerCase().startsWith(queryLower))
          .take(10) // Limit to 10 matches
          .toList();

      for (var username in usernamesToFetch) {
        // Query users by username
        final userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final user = DomainUser.fromMap(userQuery.docs.first.data());
          matchingUsers.add(user);
        }
      }

      return matchingUsers;
    } catch (e) {
      debugPrint('Error searching users in maypole: $e');
      return [];
    }
  }

  /// Search for all users by username prefix (for general search)
  Future<List<DomainUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Query users whose username starts with the query
      // Note: Firestore doesn't support case-insensitive queries directly,
      // so we'll use a range query
      final usersSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      return usersSnapshot.docs
          .map((doc) => DomainUser.fromMap(doc.data()))
          .where((user) => user.username.toLowerCase().startsWith(queryLower))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get a user by their Firebase ID
  Future<DomainUser?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return DomainUser.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }
}
