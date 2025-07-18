import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/features/identity/data/domain_user.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSession _session = AppSession();

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  Future<bool> isUsernameAvailable(String username) async {
    try {
      print('Checking username: $username');

      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      print('Query completed. Found ${result.docs.length} documents');
      return result.docs.isEmpty;
    } catch (e) {
      print('Username check failed: $e');
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

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _firebaseAuth.signInWithCredential(credential);

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
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      _session.currentUser = null;
    } catch (e) {
      rethrow;
    }
  }
}