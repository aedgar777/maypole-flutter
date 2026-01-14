import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/services/fcm_service.dart';
import 'package:maypole/core/services/user_data_prefetch_service.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = AppSession();
  final FCMService _fcmService = FCMService();
  final UserDataPrefetchService _prefetchService = UserDataPrefetchService();

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
          .asyncMap((docSnapshot) async {
        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          final user = DomainUser.fromMap(userData);
          _session.currentUser = user;
          return user;
        } else {
          // User document doesn't exist but Firebase Auth user does
          // This can happen if:
          // 1. User was just created and Firestore document is being written (registration in progress)
          // 2. User was created in Firebase Auth but Firestore write failed
          // 3. User document was manually deleted
          // 4. Old test data exists
          
          // Wait a moment to allow registration to complete
          // If the user was just created, the Firestore document should appear within 2-3 seconds
          debugPrint('⚠️ Firebase Auth user exists but Firestore document missing for ${firebaseUser.uid}');
          debugPrint('   Display name: ${firebaseUser.displayName}');
          debugPrint('   Email: ${firebaseUser.email}');
          debugPrint('⏳ Waiting 3 seconds for Firestore document to be created (may be registration in progress)...');
          
          await Future.delayed(const Duration(seconds: 3));
          
          // Check again if document exists now
          final recheckSnapshot = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          
          if (recheckSnapshot.exists) {
            debugPrint('✅ Firestore document appeared - registration completed successfully');
            final userData = recheckSnapshot.data() as Map<String, dynamic>;
            final user = DomainUser.fromMap(userData);
            _session.currentUser = user;
            return user;
          }
          
          // Document still doesn't exist after waiting - sign out the user
          debugPrint('❌ Firestore document still missing after 3 seconds');
          debugPrint('🔄 Signing out user due to missing Firestore document');
          await signOut();
          
          _session.currentUser = null;
          return null;
        }
      });
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.toLowerCase();
      debugPrint('=== USERNAME CHECK START ===');
      debugPrint('Original username: $username');
      debugPrint('Normalized username: $normalizedUsername');

      // Check the usernames collection instead of querying users
      // Use GetOptions to force fetch from server and avoid cache issues
      final DocumentSnapshot result = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get(const GetOptions(source: Source.server));

      debugPrint('Username document exists: ${result.exists}');
      
      // If username document exists, check if it's orphaned
      if (result.exists) {
        final data = result.data() as Map<String, dynamic>?;
        final ownerId = data?['owner'] as String?;
        
        debugPrint('Username document data: $data');
        debugPrint('Owner ID from document: $ownerId');
        
        if (ownerId != null) {
          // Check if the owner user still exists
          debugPrint('Checking if owner user exists...');
          final userDoc = await _firestore
              .collection('users')
              .doc(ownerId)
              .get(const GetOptions(source: Source.server));
          
          debugPrint('Owner user exists: ${userDoc.exists}');
          
          if (!userDoc.exists) {
            debugPrint('🧹 ORPHANED USERNAME DETECTED!');
            debugPrint('Owner $ownerId does not exist in users collection');
            debugPrint('Deleting orphaned username document...');
            
            // Clean up orphaned username
            await _firestore
                .collection('usernames')
                .doc(normalizedUsername)
                .delete();
            
            debugPrint('✅ Orphaned username cleaned up successfully');
            debugPrint('=== USERNAME CHECK END - AVAILABLE (after cleanup) ===');
            return true; // Username is now available
          } else {
            debugPrint('❌ Username is legitimately taken by existing user $ownerId');
            debugPrint('=== USERNAME CHECK END - NOT AVAILABLE ===');
            return false;
          }
        } else {
          debugPrint('⚠️ Username document has no owner field - malformed!');
          debugPrint('Deleting malformed username document...');
          
          // Clean up malformed username document
          await _firestore
              .collection('usernames')
              .doc(normalizedUsername)
              .delete();
          
          debugPrint('✅ Malformed username document cleaned up');
          debugPrint('=== USERNAME CHECK END - AVAILABLE (after cleanup) ===');
          return true;
        }
      }
      
      debugPrint('✅ Username document does not exist - available');
      debugPrint('=== USERNAME CHECK END - AVAILABLE ===');
      return true; // Username is available if document doesn't exist
    } catch (e) {
      debugPrint('❌ USERNAME CHECK FAILED WITH ERROR: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      }
      debugPrint('=== USERNAME CHECK END - ERROR ===');
      // Re-throw the error so it's clear there's a problem
      // Don't silently return false as that makes it seem like username is taken
      rethrow;
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

      // Set display name on Firebase Auth user profile
      // This enables the %DISPLAY_NAME% variable in email templates
      await result.user!.updateDisplayName(username);
      debugPrint('✓ Set display name to: $username');

      // Reload the user to ensure authentication token is fresh
      // This prevents "Caller does not have permission" errors in Firestore
      await result.user!.reload();
      final freshUser = _firebaseAuth.currentUser;
      if (freshUser == null) {
        throw Exception('User authentication state lost during registration');
      }
      
      // Get fresh ID token to ensure Firestore has latest auth state
      await freshUser.getIdToken(true);
      debugPrint('✓ Refreshed authentication token');

      // Create domain user
      final DomainUser user = DomainUser(
        username: username,
        email: email,
        firebaseID: freshUser.uid,
      );

      // Store in Firestore
      await _firestore
          .collection('users')
          .doc(freshUser.uid)
          .set(user.toMap());

      // Set current user in session
      _session.currentUser = user;

      // Reserve the username
      await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .set({
        'taken': true,
        'owner': freshUser.uid,
      });

      // Send email verification immediately after registration
      debugPrint('📧 Attempting to send verification email...');
      try {
        await sendEmailVerification();
        debugPrint('✅ Verification email sent successfully');
      } catch (e) {
        debugPrint('❌ Failed to send verification email: $e');
        debugPrint('   Error type: ${e.runtimeType}');
        if (e is FirebaseAuthException) {
          debugPrint('   Firebase error code: ${e.code}');
          debugPrint('   Firebase error message: ${e.message}');
        }
        // Don't fail registration if email sending fails
      }

      // Setup FCM for new user
      try {
        await _fcmService.setupForUser(freshUser.uid);
        debugPrint('✓ FCM initialized for new user');
      } catch (e) {
        debugPrint('⚠️ FCM setup failed (non-critical): $e');
      }

      // Prefetch user data in background (new users won't have much data yet)
      _prefetchService.prefetchUserData(freshUser.uid).catchError((e) {
        debugPrint('⚠️ Prefetch failed (non-critical): $e');
      });

      return freshUser.uid;
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
        
        // Check and update email verification status
        await checkEmailVerificationStatus();
        
        // Setup FCM for returning user
        try {
          await _fcmService.setupForUser(result.user!.uid);
          debugPrint('✓ FCM initialized for returning user');
        } catch (e) {
          debugPrint('⚠️ FCM setup failed (non-critical): $e');
        }

        // Prefetch user data in background to warm up cache
        // This runs asynchronously and won't block the login flow
        _prefetchService.prefetchUserData(result.user!.uid).catchError((e) {
          debugPrint('⚠️ Prefetch failed (non-critical): $e');
        });
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
      // Cleanup FCM token before signing out
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId != null) {
        try {
          await _fcmService.cleanupForUser(userId);
          debugPrint('✓ FCM cleaned up for user');
        } catch (e) {
          debugPrint('⚠️ FCM cleanup failed (non-critical): $e');
        }
      }
      
      await _firebaseAuth.signOut();
      _session.currentUser = null;

      // Clear Firestore cache on logout
      // This ensures next user login starts with fresh data
      try {
        await _prefetchService.clearCache();
        debugPrint('✓ Cache cleared on logout');
      } catch (e) {
        debugPrint('⚠️ Cache clear failed (non-critical): $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(DomainUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.firebaseID)
          .update(user.toMap());

      // Update session
      _session.currentUser = user;
    } catch (e) {
      debugPrint('Error updating user data: $e');
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

      // Mark the account for deletion in Firestore FIRST
      // This is a write operation that will succeed even if auth deletion fails
      // The cloud function will complete the deletion if we get interrupted
      await _firestore.collection('users').doc(uid).update({
        'deletionRequested': true,
        'deletionRequestedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✓ Marked account for deletion');

      // Cleanup FCM tokens
      try {
        await _fcmService.cleanupForUser(uid);
        debugPrint('✓ FCM cleaned up');
      } catch (e) {
        debugPrint('⚠️ FCM cleanup failed (non-critical): $e');
      }

      // Delete notifications subcollection
      try {
        final notificationsSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .get();

        final batch = _firestore.batch();
        for (final doc in notificationsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('✓ Deleted ${notificationsSnapshot.docs.length} notifications');
      } catch (e) {
        debugPrint('⚠️ Error deleting notifications: $e');
      }

      // Delete username reservation
      try {
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete();
        debugPrint('✓ Deleted username reservation for $username');
      } catch (e) {
        debugPrint('⚠️ Error deleting username: $e');
      }

      // Delete user document
      try {
        await _firestore.collection('users').doc(uid).delete();
        debugPrint('✓ Deleted user document');
      } catch (e) {
        debugPrint('⚠️ Error deleting user document: $e');
      }

      // Finally, delete Firebase Auth account
      // If this fails due to requires-recent-login, the deletionRequested flag
      // will remain and the cloud function can complete the deletion
      try {
        await user.delete();
        debugPrint('✓ Deleted Firebase Auth account');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // The Firestore data is already marked for deletion
          // The cloud function will complete the auth deletion
          debugPrint('❌ Re-authentication required for auth deletion');
          
          // Sign out the user since their data is marked for deletion
          await signOut();
          
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Account data has been removed. Please sign in again to complete the deletion process.',
          );
        }
        rethrow;
      }

      // Clear session
      _session.currentUser = null;
      
      debugPrint('✅ Account deletion completed successfully');
    } on FirebaseAuthException catch (e) {
      // Rethrow auth exceptions
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (user.emailVerified) {
        // If Firebase Auth already shows verified, update Firestore
        await _updateEmailVerificationStatus(true);
        throw Exception('Email is already verified');
      }

      // Send verification email with custom landing page
      // The continueUrl is where users will be redirected after verifying their email
      final projectId = AppConfig.isProduction 
          ? 'maypole-flutter-ce6c3' 
          : 'maypole-flutter-dev';
      
      final actionCodeSettings = ActionCodeSettings(
        // Users will land on this page after clicking the verification link in their email
        url: 'https://$projectId.web.app/email-verified',
        // For mobile apps, this ensures the link opens in the app if installed
        handleCodeInApp: false,
        // iOS app settings (optional - allows deep linking to app)
        iOSBundleId: 'app.maypole.maypole',
        // Android app settings (optional - allows deep linking to app)
        androidPackageName: 'app.maypole.maypole',
        androidInstallApp: false,
        androidMinimumVersion: '1',
      );
      
      await user.sendEmailVerification(actionCodeSettings);
      debugPrint('✓ Verification email sent to ${user.email} with redirect to https://$projectId.web.app/email-verified');
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      // Reload user to get latest verification status
      await user.reload();
      final reloadedUser = _firebaseAuth.currentUser;
      
      if (reloadedUser != null && reloadedUser.emailVerified) {
        // Update Firestore with verification status
        await _updateEmailVerificationStatus(true);
        debugPrint('✓ Email verification status updated in Firestore');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking email verification status: $e');
    }
  }

  Future<void> _updateEmailVerificationStatus(bool isVerified) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'emailVerified': isVerified});

      // Update session
      if (_session.currentUser != null) {
        _session.currentUser = DomainUser(
          username: _session.currentUser!.username,
          email: _session.currentUser!.email,
          firebaseID: _session.currentUser!.firebaseID,
          profilePictureUrl: _session.currentUser!.profilePictureUrl,
          maypoleChatThreads: _session.currentUser!.maypoleChatThreads,
          blockedUsers: _session.currentUser!.blockedUsers,
          fcmToken: _session.currentUser!.fcmToken,
          emailVerified: isVerified,
        );
      }
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
      rethrow;
    }
  }
}
