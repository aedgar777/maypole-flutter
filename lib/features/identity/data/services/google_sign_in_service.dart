import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maypole/core/app_config.dart';

/// Raised when the user backs out of the Google account picker.
///
/// Distinguished from a genuine failure so the UI can return the user to the
/// login form silently instead of showing an error — dismissing the picker is
/// a normal thing to do, not something to apologise for.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Obtains a Google [AuthCredential] on every platform Maypole ships to.
///
/// Two mechanisms are needed, because there is no single one that behaves well
/// everywhere:
///
///   * **Web** uses `FirebaseAuth.signInWithPopup`. The `google_sign_in` web
///     implementation deliberately does not support a programmatic
///     `authenticate()` call (Google Identity Services requires its own
///     rendered button), so driving it from our own themed button is not
///     possible. The Firebase popup has no such constraint.
///   * **Android / iOS / macOS** use `google_sign_in`, which surfaces the
///     native account picker — including accounts already on the device — and
///     returns an ID token we exchange for a Firebase credential. The
///     alternative, `signInWithProvider`, works but drops the user into a web
///     view and forgets them between sessions.
class GoogleSignInService {
  final FirebaseAuth _firebaseAuth;

  GoogleSignInService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Guards [initialize], which must run exactly once per process.
  static Future<void>? _initialization;

  /// Prepares the native SDK. Safe to call repeatedly; only the first call
  /// does work. Never needed on web, where the popup flow is used instead.
  static Future<void> _ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      // Only Apple platforms take a client ID here, and it must be the *iOS*
      // one. Android has no client ID of its own — it is identified by package
      // name plus signing certificate — so handing it one is at best ignored
      // and at worst rejected.
      clientId: _isApplePlatform ? _iosClientIdOrNull : null,
      // Android needs the *web* client ID as the audience for the ID token it
      // mints, or Firebase will not accept it. Ignored on Apple platforms.
      serverClientId: _webClientIdOrNull,
    );
  }

  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static String? get _iosClientIdOrNull {
    final id = AppConfig.googleIosClientId;
    return id.isEmpty ? null : id;
  }

  static String? get _webClientIdOrNull {
    final id = AppConfig.googleWebClientId;
    return id.isEmpty ? null : id;
  }

  /// Runs the interactive Google flow and signs the resulting credential into
  /// Firebase.
  ///
  /// Throws [GoogleSignInCancelled] if the user dismissed the picker, and
  /// [FirebaseAuthException] for anything Firebase rejects.
  Future<UserCredential> signIn() async {
    if (kIsWeb) {
      return _signInOnWeb();
    }
    return _signInOnNative();
  }

  Future<UserCredential> _signInOnWeb() async {
    final provider = GoogleAuthProvider()
      // Always show the chooser. Without this, a browser signed into exactly
      // one Google account skips straight past it, which makes "wrong account"
      // mistakes impossible to recover from without leaving the app.
      ..setCustomParameters(<String, String>{'prompt': 'select_account'});

    try {
      return await _firebaseAuth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      // Closing the popup is a cancellation, not a failure.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        throw const GoogleSignInCancelled();
      }
      rethrow;
    }
  }

  Future<UserCredential> _signInOnNative() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      // Almost always a configuration problem rather than a runtime one: on
      // Android an absent ID token means the SHA-1 fingerprint of the signing
      // key is not registered against the Firebase Android app, or the web
      // client ID was not supplied as `serverClientId`.
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token. Check that this build\'s '
            'signing certificate is registered with the Firebase project and '
            'that the OAuth web client ID is configured.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _firebaseAuth.signInWithCredential(credential);
  }

  /// Clears the native SDK's cached account.
  ///
  /// Without this the next sign-in silently reuses the previous account and
  /// the picker never appears, so a user who signed out cannot switch accounts.
  /// Best-effort: a failure here must not block signing out of Firebase.
  Future<void> signOut() async {
    if (kIsWeb) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignored deliberately — see above.
    }
  }
}
