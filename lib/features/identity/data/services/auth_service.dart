import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = AppSession();

  Stream<DomainUser?> get user {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        _session.currentUser = null;
        return Stream.value(null);
      }
      // Listen to real-time Firestore updates
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((docSnapshot) {
        if (docSnapshot.exists) {
          final user = DomainUser.fromMap(
              docSnapshot.data() as Map<String, dynamic>);
          _session.currentUser = user;
          return user;
        } else {
          _session.currentUser = null;
          return null;
        }
      });
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      debugPrint('Checking username: $username');

      // Check the usernames collection instead of querying users
      final DocumentSnapshot result = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase()) // Use lowercase for consistency
          .get();

      debugPrint('Query completed. Username exists: ${result.exists}');
      return !result.exists; // Username is available if document doesn't exist
    } catch (e) {
      debugPrint('Username check failed: $e');
      // Instead of throwing, return false to indicate username is not available
      return false;
    }
  }

  Future<String?> registerWithEmailAndPassword(
      String email,
      String password,
      String username,
      ) async {
    try {
      // Check username availability
      if (!await isUsernameAvailable(username)) {
        throw FirebaseAuthException(
          code: 'username-taken',
          message: 'Username is already taken',
        );
      }

      // Create Firebase Auth user
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create domain user

      final DomainUser user = DomainUser(
        username: username,
        email: email,
        firebaseID: result.user!.uid,
      );

      // Store in Firestore
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());

      // Set current user in session
      _session.currentUser = user;

      // Reserve the username
      await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .set({
        'taken': true,
        'owner': result.user!.uid,
      });

      return result.user?.uid;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch and set domain user
      if (result.user != null) {
        await _fetchAndSetDomainUser(result.user!.uid);
      }

      return result.user?.uid;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchAndSetDomainUser(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      _session.currentUser = DomainUser.fromMap(
          docSnapshot.data() as Map<String, dynamic>
      );
    } else {
      _session.currentUser = null;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _session.currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final uid = user.uid;
      final currentUser = _session.currentUser;

      if (currentUser == null) {
        throw Exception('User data not found');
      }

      final username = currentUser.username;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete username reservation
      await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .delete();

      // Delete Firebase Auth account
      await user.delete();

      // Clear session
      _session.currentUser = null;
    } on FirebaseAuthException catch (e) {
      // If re-authentication is required, throw a more specific error
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Please log out and log back in before deleting your account',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
