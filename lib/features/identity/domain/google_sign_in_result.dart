/// What happened when a user authenticated with Google.
///
/// Google can vouch for who someone is, but not for what Maypole calls them —
/// a username is ours to collect. So a successful Google authentication has
/// two possible endings, and the caller has to tell them apart before deciding
/// where to send the user.
enum GoogleSignInOutcome {
  /// The account already has a Maypole profile. Nothing left to do.
  signedIn,

  /// First time through: authenticated with Google, but no profile exists yet
  /// and a username still has to be chosen.
  needsUsername,
}

class GoogleSignInResult {
  final GoogleSignInOutcome outcome;
  final String uid;

  /// Empty unless [outcome] is [GoogleSignInOutcome.needsUsername].
  final String email;

  /// A pre-filled starting point for the username field, derived from the
  /// Google display name or email. May be empty if nothing usable came back.
  final String suggestedUsername;

  /// The Google profile picture, carried over so the new account starts with
  /// an avatar instead of a blank one.
  final String photoUrl;

  const GoogleSignInResult._({
    required this.outcome,
    required this.uid,
    this.email = '',
    this.suggestedUsername = '',
    this.photoUrl = '',
  });

  const GoogleSignInResult.signedIn({required String uid})
      : this._(outcome: GoogleSignInOutcome.signedIn, uid: uid);

  const GoogleSignInResult.needsUsername({
    required String uid,
    required String email,
    required String suggestedUsername,
    required String photoUrl,
  }) : this._(
          outcome: GoogleSignInOutcome.needsUsername,
          uid: uid,
          email: email,
          suggestedUsername: suggestedUsername,
          photoUrl: photoUrl,
        );

  bool get needsUsername => outcome == GoogleSignInOutcome.needsUsername;
}
