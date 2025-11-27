import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';

/// Helper class for displaying user information, especially for deleted users.
/// 
/// This provides utilities to handle cases where a user has been deleted
/// but their messages still exist in the system.
class UserDisplayHelper {
  static const String deletedUserPlaceholder = '[Deleted User]';

  final FirebaseFirestore _firestore;
  final Map<String, DomainUser?> _cache = {};

  UserDisplayHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Attempts to fetch a user by username.
  /// Returns null if the user doesn't exist (e.g., account deleted).
  /// 
  /// Results are cached to minimize Firestore reads.
  Future<DomainUser?> getUserByUsername(String username) async {
    // Return from cache if available
    if (_cache.containsKey(username)) {
      return _cache[username];
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // User not found (likely deleted)
        _cache[username] = null;
        return null;
      }

      final user = DomainUser.fromMap(
        querySnapshot.docs.first.data(),
      );
      _cache[username] = user;
      return user;
    } catch (e) {
      // On error, return null and cache it
      _cache[username] = null;
      return null;
    }
  }

  /// Returns a display-friendly username.
  /// If the user is null (deleted), returns the placeholder text.
  String getDisplayUsername(DomainUser? user, {String? fallbackUsername}) {
    if (user != null) {
      return user.username;
    }
    if (fallbackUsername != null) {
      return fallbackUsername;
    }
    return deletedUserPlaceholder;
  }

  /// Clears the internal cache.
  /// Call this when you want to force refresh user data.
  void clearCache() {
    _cache.clear();
  }

  /// Removes a specific user from the cache.
  void invalidateUser(String username) {
    _cache.remove(username);
  }
}
