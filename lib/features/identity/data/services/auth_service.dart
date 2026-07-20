import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      return _firestore.collection('users').doc(firebaseUser.uid).snapshots().asyncMap((
        docSnapshot,
      ) async {
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
          //
          // We only want to grant a grace period (polling) when a *brand-new*
          // account is mid-registration and the document write hasn't landed
          // yet. In every other case — account deletion, an orphaned/older
          // account, or the document otherwise disappearing — we must resolve
          // to null immediately so the app returns to the login screen cleanly
          // rather than showing a spinner for ~15s (which also keeps a doomed
          // Firestore listener alive on the missing document).
          final hadDocumentPreviously =
              _session.currentUser?.firebaseID == firebaseUser.uid;

          final creationTime = firebaseUser.metadata.creationTime;
          final isNewlyCreatedAccount = creationTime != null &&
              DateTime.now().difference(creationTime) <
                  const Duration(seconds: 30);

          if (hadDocumentPreviously || !isNewlyCreatedAccount) {
            // NOTE: We intentionally do NOT sign out here. During account
            // deletion the document is removed *before* the auth user is
            // deleted; signing out mid-deletion would abort `user.delete()`.
            // Returning null is enough to route back to login.
            _session.currentUser = null;
            return null;
          }

          // The auth state change can fire *before* registration finishes
          // writing the user document, and Firestore writes complete against
          // the local cache before they sync to the server. A single short
          // recheck can therefore race ahead of the write and wrongly conclude
          // the account is orphaned — signing a brand-new user out
          // mid-registration. Instead, poll for the document over a longer
          // window before giving up, so a slow write can never sign the user
          // out.
          const maxRecheckAttempts = 10;
          const recheckDelay = Duration(milliseconds: 1500);

          for (var attempt = 0; attempt < maxRecheckAttempts; attempt++) {
            await Future.delayed(recheckDelay);

            // If the user signed out (or switched) while we were waiting, stop.
            if (_firebaseAuth.currentUser?.uid != firebaseUser.uid) {
              _session.currentUser = null;
              return null;
            }

            final recheckSnapshot = await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

            if (recheckSnapshot.exists) {
              final userData = recheckSnapshot.data() as Map<String, dynamic>;
              final user = DomainUser.fromMap(userData);
              _session.currentUser = user;
              return user;
            }
          }

          // Document still doesn't exist after polling for ~15s - treat the
          // account as genuinely orphaned and sign out.
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

      // Check the usernames collection instead of querying users
      // Use GetOptions to force fetch from server and avoid cache issues
      final DocumentSnapshot result = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get(const GetOptions(source: Source.server));

      // If username document exists, check if it's orphaned
      if (result.exists) {
        final data = result.data() as Map<String, dynamic>?;
        final ownerId = data?['owner'] as String?;

        if (ownerId != null) {
          // Check if the owner user still exists
          final userDoc = await _firestore
              .collection('users')
              .doc(ownerId)
              .get(const GetOptions(source: Source.server));

          if (!userDoc.exists) {
            // Clean up orphaned username
            await _firestore
                .collection('usernames')
                .doc(normalizedUsername)
                .delete();

            return true; // Username is now available
          } else {
            return false;
          }
        } else {
          // Clean up malformed username document
          await _firestore
              .collection('usernames')
              .doc(normalizedUsername)
              .delete();

          return true;
        }
      }

      return true; // Username is available if document doesn't exist
    } catch (e) {
      if (e is FirebaseException) {}
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
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Set display name on Firebase Auth user profile
      // This enables the %DISPLAY_NAME% variable in email templates
      await result.user!.updateDisplayName(username);

      // Reload the user to ensure authentication token is fresh
      // This prevents "Caller does not have permission" errors in Firestore
      await result.user!.reload();
      final freshUser = _firebaseAuth.currentUser;
      if (freshUser == null) {
        throw Exception('User authentication state lost during registration');
      }

      // Get fresh ID token to ensure Firestore has latest auth state
      await freshUser.getIdToken(true);

      // Create domain user
      final DomainUser user = DomainUser(
        username: username,
        email: email,
        firebaseID: freshUser.uid,
      );

      // Store in Firestore
      await _firestore.collection('users').doc(freshUser.uid).set(user.toMap());

      // Set current user in session
      _session.currentUser = user;

      // Reserve the username
      await _firestore.collection('usernames').doc(username.toLowerCase()).set({
        'taken': true,
        'owner': freshUser.uid,
      });

      // Send email verification immediately after registration
      try {
        await sendEmailVerification();
      } catch (e) {
        if (e is FirebaseAuthException) {}
        // Don't fail registration if email sending fails
      }

      // Setup FCM for new user
      try {
        await _fcmService.setupForUser(freshUser.uid);
      } catch (e) {}

      // Prefetch user data in background (new users won't have much data yet)
      _prefetchService.prefetchUserData(freshUser.uid).catchError((e) {});

      return freshUser.uid;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
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
        } catch (e) {}

        // Prefetch user data in background to warm up cache
        // This runs asynchronously and won't block the login flow
        _prefetchService.prefetchUserData(result.user!.uid).catchError((e) {});
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
        docSnapshot.data() as Map<String, dynamic>,
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
        } catch (e) {}
      }

      await _firebaseAuth.signOut();
      _session.currentUser = null;

      // Clear Firestore cache on logout
      // This ensures next user login starts with fresh data
      try {
        await _prefetchService.clearCache();
      } catch (e) {}
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

      // Cleanup FCM tokens
      try {
        await _fcmService.cleanupForUser(uid);
      } catch (e) {}

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
      } catch (e) {}

      // Delete username reservation
      try {
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete();
      } catch (e) {}

      // Delete user document
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {}

      // Finally, delete Firebase Auth account
      // If this fails due to requires-recent-login, the deletionRequested flag
      // will remain and the cloud function can complete the deletion
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // The Firestore data is already marked for deletion
          // The cloud function will complete the auth deletion

          // Sign out the user since their data is marked for deletion
          await signOut();

          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message:
                'Account data has been removed. Please sign in again to complete the deletion process.',
          );
        }
        rethrow;
      }

      // Clear session
      _session.currentUser = null;
    } on FirebaseAuthException {
      // Rethrow auth exceptions
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a verification email via our Cloud Function, which uses our own
  /// SMTP server (Google Workspace) to deliver a branded email. This bypasses
  /// Firebase's email-template / action-URL settings entirely.
  ///
  /// The Cloud Function calls the Admin SDK's generateEmailVerificationLink,
  /// extracts the oobCode + apiKey, builds a URL pointing at our custom
  /// auth-action.html page (hosted on the web domain), and sends the email.
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

      final continueUrl = Uri.parse('${AppConfig.appUrl}/email-verified')
          .replace(queryParameters: {'returnTo': '/settings/account'})
          .toString();

      final functions = FirebaseFunctions.instance;
      // Use the default region (us-central1) — the function is deployed
      // alongside the rest of the auth-functions codebase.
      final callable = functions.httpsCallable('sendCustomVerificationEmail');
      await callable.call(<String, dynamic>{
        'continueUrl': continueUrl,
      });
    } on FirebaseFunctionsException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a password-reset email via our Cloud Function, which uses our own
  /// SMTP server (Google Workspace). Same approach as sendEmailVerification —
  /// the Admin SDK generates the link, we repoint it at auth-action.html, and
  /// send it via SMTP.
  Future<void> sendPasswordResetEmail(String email) async {
    final continueUrl = Uri.parse('${AppConfig.appUrl}/login')
        .replace(queryParameters: {'passwordReset': 'success'})
        .toString();

    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('sendCustomPasswordResetEmail');
    await callable.call(<String, dynamic>{
      'email': email,
      'continueUrl': continueUrl,
    });
  }

  /// Changes the password for a user who still knows their current password.
  ///
  /// Firebase requires a recent login to change a password, so we first
  /// re-authenticate with the supplied current password. A wrong current
  /// password surfaces as a `wrong-password` / `invalid-credential`
  /// [FirebaseAuthException] that the UI can present cleanly.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // Verify the current password before changing it.
    await user.reauthenticateWithCredential(credential);

    // Apply the new password.
    await user.updatePassword(newPassword);
  }

  /// Reloads the current user from the server and, if their email is now
  /// verified, mirrors that to Firestore. Returns whether the email is verified.
  ///
  /// Verification frequently happens *out of band* — the user clicks the link
  /// in an external browser, so the locally-cached auth token still reports
  /// `emailVerified == false`. Calling [User.reload] refreshes the account
  /// info, and forcing a fresh ID token guarantees the updated verification
  /// state is picked up immediately when the user returns to the app.
  Future<bool> checkEmailVerificationStatus() async {
    try {
      var user = _firebaseAuth.currentUser;
      if (user == null) return false;

      if (user.emailVerified) {
        await _updateEmailVerificationStatus(true);
        return true;
      }

      // Reload user to get latest verification status.
      await user.reload();

      // Force a token refresh so a verification performed elsewhere is
      // reflected right away rather than on the next token rotation.
      try {
        await user.getIdToken(true);
      } catch (_) {
        // Token refresh is best-effort; reload above is the primary signal.
      }

      user = _firebaseAuth.currentUser;

      if (user != null && user.emailVerified) {
        // Update Firestore with verification status. The account settings
        // screen streams this field and flips the badge to "Verified".
        await _updateEmailVerificationStatus(true);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateEmailVerificationStatus(bool isVerified) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': isVerified,
      });

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
      rethrow;
    }
  }
}
