import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/utils/string_utils.dart';
import 'package:maypole/core/services/fcm_service.dart';
import 'package:maypole/core/services/user_data_prefetch_service.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/identity/data/services/google_sign_in_service.dart';
import 'package:maypole/features/identity/domain/google_sign_in_result.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = AppSession();
  final FCMService _fcmService = FCMService();
  final UserDataPrefetchService _prefetchService = UserDataPrefetchService();
  final GoogleSignInService _googleSignIn = GoogleSignInService();

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
          // A Google sign-up that has reached the username screen is
          // *expected* to have no document yet. Leave the account alone: the
          // user is still deciding, and neither the poll below nor the sign-out
          // it ends in is wanted here.
          //
          // The same is true after the app is killed and relaunched mid-signup,
          // where the in-memory flag is gone but the Firebase session is not.
          // A Google-authenticated account with no password and no profile can
          // only be an unfinished sign-up, so recognising it here lets the user
          // pick up where they left off instead of silently losing the account.
          if (_isUnfinishedGoogleSignUp(firebaseUser)) {
            _googleProfileSetupPending = true;
            _googleProfileSetupUid = firebaseUser.uid;
            _session.currentUser = null;
            return null;
          }

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

      // Setup FCM for new user.
      //
      // Deliberately not awaited. On a fresh install this is what triggers the
      // OS notification permission prompt, and `setupForUser` doesn't return
      // until the user answers it and the token registration round-trips —
      // ~37s on a first run. Awaiting it held `isLoading` true that whole time,
      // so no frame was drawn, so the post-frame callback that shows the
      // registration success dialog never ran. The account was created and the
      // verification email sent, but the user sat on the registration form
      // instead of advancing to home. Nothing below depends on the result.
      unawaited(_fcmService.setupForUser(freshUser.uid).catchError((e) {}));

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

      // Clear the native Google session as well. Firebase signing out does
      // not touch it, and a lingering cached account makes the next sign-in
      // skip the picker — so a user who signed out to switch accounts gets
      // dropped straight back into the one they were leaving.
      await _googleSignIn.signOut();

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

  /// True while [deleteAccount] is running.
  ///
  /// Deletion removes the Firestore document *before* the auth user, so for a
  /// moment a deleting account looks exactly like an unfinished Google sign-up:
  /// a Google-authenticated user with no profile. Without this flag the
  /// resume-setup detection below would grab it and route the user to the
  /// username screen halfway through deleting their account.
  bool _deletionInProgress = false;

  Future<void> deleteAccount() async {
    _deletionInProgress = true;
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
    } finally {
      _deletionInProgress = false;
    }
  }

  /// Sends a verification email via our Cloud Function, which uses our own
  /// SMTP server (Google Workspace) to deliver a branded email. This bypasses
  /// Firebase's email-template / action-URL settings entirely.
  ///
  /// The Cloud Function calls the Admin SDK's generateEmailVerificationLink,
  /// extracts the oobCode + apiKey, builds a URL pointing at our custom
  /// auth-action.html page (hosted on the web domain), and sends the email.
  /// [returnTo] is where the user lands after tapping "Continue" on the
  /// `/email-verified` screen. Registration leaves it null so a brand-new
  /// user ends up on the home screen; the Account Settings resend passes
  /// `/settings/account` to put the user back where they started.
  Future<void> sendEmailVerification({String? returnTo}) async {
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
          .replace(
            queryParameters: returnTo == null ? null : {'returnTo': returnTo},
          )
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

  // ---- Google Sign-In ------------------------------------------------------

  /// True between a Google sign-in that found no Maypole profile and the user
  /// either choosing a username or abandoning the flow.
  ///
  /// The [user] stream treats "Firebase user exists but the Firestore document
  /// does not" as an orphaned account and signs out after a grace period. That
  /// is exactly the state a half-finished Google sign-up is in, and the user
  /// is sitting on the username screen thinking. This flag suppresses that
  /// clean-up for the one case where the missing document is expected.
  bool _googleProfileSetupPending = false;

  /// The uid the pending setup belongs to, so a stale flag can never suppress
  /// clean-up for a *different* account.
  String? _googleProfileSetupUid;

  bool get isGoogleProfileSetupPending => _googleProfileSetupPending;

  /// Signs in with Google and reports whether a Maypole profile already exists.
  ///
  /// Deliberately does **not** create the user document for a first-time
  /// account: Maypole requires a username that Google cannot supply, so the
  /// caller routes the user to [GoogleUsernameScreen] and calls
  /// [completeGoogleProfile] once they have picked one. Until then the account
  /// exists in Firebase Auth but not in Firestore, which is the state
  /// [_googleProfileSetupPending] protects.
  Future<GoogleSignInResult> signInWithGoogle() async {
    final credential = await _googleSignIn.signIn();
    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in returned no user.',
      );
    }

    final docSnapshot =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (docSnapshot.exists) {
      _googleProfileSetupPending = false;
      _googleProfileSetupUid = null;

      _session.currentUser =
          DomainUser.fromMap(docSnapshot.data() as Map<String, dynamic>);

      // A Google account's email is verified by Google, so mirror that rather
      // than leaving the badge stale from before the account was linked.
      if (firebaseUser.emailVerified) {
        try {
          await _updateEmailVerificationStatus(true);
        } catch (_) {
          // Cosmetic — never block sign-in on it.
        }
      }

      try {
        await _fcmService.setupForUser(firebaseUser.uid);
      } catch (e) {}

      _prefetchService.prefetchUserData(firebaseUser.uid).catchError((e) {});

      return GoogleSignInResult.signedIn(uid: firebaseUser.uid);
    }

    _googleProfileSetupPending = true;
    _googleProfileSetupUid = firebaseUser.uid;

    return GoogleSignInResult.needsUsername(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      suggestedUsername: StringUtils.suggestUsername(
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
      ),
      photoUrl: firebaseUser.photoURL ?? '',
    );
  }

  /// Creates the Firestore profile for a Google account once the user has
  /// chosen [username], completing the sign-up.
  ///
  /// Mirrors the tail of [registerWithEmailAndPassword], minus everything
  /// specific to passwords and email verification — Google has already
  /// verified the address.
  Future<void> completeGoogleProfile(String username) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Google sign-in session was lost. Please sign in again.',
      );
    }

    if (!await isUsernameAvailable(username)) {
      throw FirebaseAuthException(
        code: 'username-taken',
        message: 'Username is already taken',
      );
    }

    await firebaseUser.updateDisplayName(username);
    await firebaseUser.reload();

    final user = DomainUser(
      username: username,
      email: firebaseUser.email ?? '',
      firebaseID: firebaseUser.uid,
      profilePictureUrl: firebaseUser.photoURL ?? '',
      // Google has verified the address; recording it here keeps Account
      // Settings from offering a pointless "resend verification email".
      emailVerified: firebaseUser.emailVerified,
    );

    await _applyWrite(
      _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap()),
    );
    _session.currentUser = user;

    await _applyWrite(
      _firestore.collection('usernames').doc(username.toLowerCase()).set({
        'taken': true,
        'owner': firebaseUser.uid,
      }),
    );

    // Only lift the guard once the document is committed — the [user] stream
    // may be mid-flight and would otherwise still see a missing document.
    _googleProfileSetupPending = false;
    _googleProfileSetupUid = null;

    // Not awaited: on a fresh install this triggers the OS notification
    // prompt, which does not return until the user answers it. See the note in
    // [registerWithEmailAndPassword].
    unawaited(_fcmService.setupForUser(firebaseUser.uid).catchError((e) {}));

    _prefetchService.prefetchUserData(firebaseUser.uid).catchError((e) {});
  }

  /// How long to wait for the server to acknowledge a profile write before
  /// letting the user move on.
  ///
  /// Long enough that a real rejection — permission denied, a failed rule —
  /// still surfaces as an error, since those come back promptly.
  static const _writeAckTimeout = Duration(seconds: 5);

  /// Awaits [write] without letting a slow network strand the user.
  ///
  /// Firestore applies a write to the local cache immediately but only
  /// completes its future once the *server* acknowledges it. Awaiting that
  /// outright turns a brief connectivity blip into an indefinite spinner: the
  /// document already exists locally, the [user] stream has already emitted it,
  /// and Firestore retries the write in the background — across app restarts.
  /// That is exactly how a signed-up account could appear created and working
  /// on relaunch while the screen that created it hung forever.
  Future<void> _applyWrite(Future<void> write) {
    // A rejection arriving after the timeout would otherwise be an unhandled
    // async error, since nothing is listening to the original future by then.
    unawaited(write.catchError((Object _) {}));

    return write.timeout(_writeAckTimeout, onTimeout: () {});
  }

  /// Unwinds a Google sign-up the user walked away from.
  ///
  /// Leaving the Firebase Auth account in place would strand it: it owns the
  /// email address, so a later email/password registration with that address
  /// fails, yet it has no profile and cannot be used to sign in. Deleting is
  /// the honest outcome — the user never finished creating an account.
  ///
  /// If deletion fails (a revoked token, no network) signing out is an
  /// acceptable fallback: the account still has no Firestore document, so the
  /// next Google sign-in lands back on the username screen rather than in a
  /// broken session.
  Future<void> abandonGoogleProfileSetup() async {
    final firebaseUser = _firebaseAuth.currentUser;

    _googleProfileSetupPending = false;
    _googleProfileSetupUid = null;

    if (firebaseUser == null) {
      await _googleSignIn.signOut();
      return;
    }

    try {
      await _googleSignIn.signOut();
      await firebaseUser.delete();
      _session.currentUser = null;
    } catch (_) {
      await signOut();
    }
  }

  /// Whether [firebaseUser] is a Google sign-up that never chose a username.
  ///
  /// Only called when the profile document is known to be missing. Requiring
  /// Google *and* the absence of a password provider keeps this from claiming
  /// an ordinary email/password account whose document failed to write — that
  /// case still belongs to the orphan handling below, which can recover it.
  bool _isUnfinishedGoogleSignUp(User firebaseUser) {
    if (_deletionInProgress) return false;

    if (_googleProfileSetupPending &&
        _googleProfileSetupUid == firebaseUser.uid) {
      return true;
    }

    final providers =
        firebaseUser.providerData.map((info) => info.providerId).toSet();

    return providers.contains(GoogleAuthProvider.PROVIDER_ID) &&
        !providers.contains(EmailAuthProvider.PROVIDER_ID);
  }

  /// Rebuilds the pending-setup details from the current Firebase session.
  ///
  /// Used to restore the username screen after a relaunch, when the in-memory
  /// state that normally carries them is gone. Returns null if there is no
  /// unfinished sign-up to resume.
  GoogleSignInResult? resumePendingGoogleProfile() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null || !_googleProfileSetupPending) return null;
    if (_googleProfileSetupUid != firebaseUser.uid) return null;

    return GoogleSignInResult.needsUsername(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      suggestedUsername: StringUtils.suggestUsername(
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
      ),
      photoUrl: firebaseUser.photoURL ?? '',
    );
  }

  /// The sign-in methods currently attached to the signed-in account.
  ///
  /// Used by Account Settings to tell a Google-only user why there is no
  /// password to change.
  Set<String> get currentUserProviderIds {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const <String>{};
    return user.providerData.map((info) => info.providerId).toSet();
  }

  /// Whether the signed-in user has a password they could change or reset.
  ///
  /// False for an account created purely through Google, which has no password
  /// credential at all.
  bool get hasPasswordProvider =>
      currentUserProviderIds.contains(EmailAuthProvider.PROVIDER_ID);

  /// Whether the signed-in user got here through Google.
  bool get hasGoogleProvider =>
      currentUserProviderIds.contains(GoogleAuthProvider.PROVIDER_ID);

  /// Adds a password to an account that only has Google, so the user gains a
  /// second way in.
  ///
  /// Firebase treats this as linking an email/password credential rather than
  /// as a password change, which is why [changePassword] cannot be used: there
  /// is no current password to re-authenticate with.
  Future<void> setPasswordForGoogleAccount(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    await user.linkWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: newPassword),
    );
  }

}
