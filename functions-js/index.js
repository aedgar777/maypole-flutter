/**
 * Firebase Cloud Functions for Authentication Triggers (Node.js)
 * 
 * This handles auth-specific triggers that aren't available in Python SDK
 * Uses Firebase Functions v1 API for auth triggers
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const { JWT } = require('google-auth-library');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ============================================================================
// SMTP transport — Gmail API via OAuth2 (service account + domain-wide delegation)
// ============================================================================
//
// We authenticate to smtp.gmail.com using XOAUTH2. The token comes from a
// Google Cloud service account that has been granted *domain-wide delegation*
// in the Google Workspace admin console, allowing it to impersonate the
// sending mailbox (e.g. info@maypole.app).
//
// Why this and not App Passwords: Google Workspace admins can no longer
// reliably enable App Passwords for their users (the setting shows
// "not available"). OAuth2 with DWD is the officially-supported path and
// is not deprecated.
//
// SECRETS
//   GMAIL_SA_KEY  — JSON key file contents for the sender service account,
//                   stored via `firebase functions:secrets:set GMAIL_SA_KEY`.
//   GMAIL_SENDER  — mailbox to send from, e.g. `info@maypole.app`. This
//                   mailbox must exist in the Workspace domain and the
//                   service account must be authorized to impersonate it.

const SENDER_ADDRESS = () => process.env.GMAIL_SENDER || 'info@maypole.app';

let _transporter = null;

async function getAccessToken() {
  const rawKey = process.env.GMAIL_SA_KEY;
  if (!rawKey) {
    throw new Error(
      'GMAIL_SA_KEY secret is not set. Run: '
      + 'firebase functions:secrets:set GMAIL_SA_KEY'
    );
  }
  const creds = JSON.parse(rawKey);
  const jwt = new JWT({
    email: creds.client_email,
    key: creds.private_key,
    scopes: ['https://mail.google.com/'],
    subject: SENDER_ADDRESS(), // impersonate this mailbox via DWD
  });
  const { access_token: accessToken } = await jwt.authorize();
  return accessToken;
}

async function getTransporter() {
  // Access tokens live for ~1h; recreate on each send for simplicity.
  const accessToken = await getAccessToken();

  _transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: {
      type: 'OAuth2',
      user: SENDER_ADDRESS(),
      accessToken,
    },
  });

  return _transporter;
}

// ============================================================================
// Custom Auth Emails (bypasses Firebase's email-template action-URL restriction)
// ============================================================================
//
// These callable functions generate Firebase action links via the Admin SDK,
// extract the oobCode and apiKey, and build links pointing at our custom
// auth-action.html page (served on the hosting domain). They then send the
// email through our own SMTP server (Google Workspace).
//
// This completely bypasses the Firebase console's email-template / action-URL
// settings — we never touch notification.sendEmail.callbackUri.

/**
 * Builds a custom action URL pointing at our auth-action.html page.
 *
 * Firebase's generated links point at the default handler
 * (…/__/auth/action?mode=…&oobCode=…&apiKey=…). We copy oobCode + apiKey
 * into a URL that points at our stylized auth-action.html instead.
 */
function buildCustomActionUrl(firebaseLink, mode, continueUrl) {
  const url = new URL(firebaseLink);
  const oobCode = url.searchParams.get('oobCode');
  const apiKey = url.searchParams.get('apiKey');

  // auth-action.html is deployed alongside the Flutter app on the hosting
  // domain. We derive the hosting origin from the client-supplied
  // continueUrl so a request initiated from dev routes back to dev, and a
  // request initiated from prod routes back to prod — no env config needed.
  let hostingOrigin;
  try {
    hostingOrigin = new URL(continueUrl).origin;
  } catch (_) {
    hostingOrigin = 'https://maypole.app';
  }

  const custom = new URL(`${hostingOrigin}/auth-action.html`);
  custom.searchParams.set('mode', mode);
  custom.searchParams.set('oobCode', oobCode);
  custom.searchParams.set('apiKey', apiKey);
  if (continueUrl) {
    custom.searchParams.set('continueUrl', continueUrl);
  }

  return custom.toString();
}

/**
 * Sends a verification email to the currently-authenticated user.
 *
 * Called by the Flutter app after registration or when the user taps
 * "resend verification" in account settings.
 *
 * The caller must be authenticated. The function reads the caller's uid
 * and email from the auth context — the client only passes the continueUrl.
 */
exports.sendCustomVerificationEmail = functions
  .runWith({ secrets: ['GMAIL_SA_KEY', 'GMAIL_SENDER'] })
  .https.onCall(async (data, context) => {
    // Verify the caller is authenticated.
    if (!context.auth || !context.auth.uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'You must be signed in to send a verification email.'
      );
    }

    const uid = context.auth.uid;
    // The client passes the environment-correct base URL. We only fall back
    // to prod if the client omitted it entirely (should never happen).
    const continueUrl = data.continueUrl || 'https://maypole.app/email-verified?returnTo=/settings/account';

    try {
      const user = await admin.auth().getUser(uid);

      if (!user.email) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'User has no email address.'
        );
      }

      if (user.emailVerified) {
        console.log(`[verify] User ${uid} already verified — skipping.`);
        return { status: 'already-verified' };
      }

      // Generate the verification link via Admin SDK. This link points at
      // Firebase's default handler; we extract oobCode + apiKey from it.
      const firebaseLink = await admin.auth().generateEmailVerificationLink(
        user.email,
        { url: continueUrl }
      );

      const customLink = buildCustomActionUrl(
        firebaseLink,
        'verifyEmail',
        continueUrl
      );

      console.log(`[verify] Sending verification email to ${user.email}`);

      const transporter = await getTransporter();
      await transporter.sendMail({
        from: `"Maypole" <${SENDER_ADDRESS()}>`,
        to: user.email,
        subject: 'Verify your email for Maypole',
        html: buildVerificationEmail(user.displayName || user.email, customLink),
      });

      console.log(`[verify] ✓ Sent to ${user.email}`);
      return { status: 'sent' };
    } catch (err) {
      console.error(`[verify] ✗ Error for user ${uid}:`, err.message);
      throw new functions.https.HttpsError('internal', err.message);
    }
  }
);

/**
 * Sends a password-reset email. Does not require authentication (the user
 * has forgotten their password and can't sign in).
 */
exports.sendCustomPasswordResetEmail = functions
  .runWith({ secrets: ['GMAIL_SA_KEY', 'GMAIL_SENDER'] })
  .https.onCall(async (data) => {
    const email = (data.email || '').trim();
    const continueUrl = data.continueUrl || 'https://maypole.app/login?passwordReset=success';

    if (!email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email is required.'
      );
    }

    try {
      // Generate the reset link via Admin SDK.
      const firebaseLink = await admin.auth().generatePasswordResetLink(
        email,
        { url: continueUrl }
      );

      const customLink = buildCustomActionUrl(
        firebaseLink,
        'resetPassword',
        continueUrl
      );

      console.log(`[reset] Sending password-reset email to ${email}`);

      const transporter = await getTransporter();
      await transporter.sendMail({
        from: `"Maypole" <${SENDER_ADDRESS()}>`,
        to: email,
        subject: 'Reset your Maypole password',
        html: buildPasswordResetEmail(email, customLink),
      });

      console.log(`[reset] ✓ Sent to ${email}`);
      return { status: 'sent' };
    } catch (err) {
      // If the user doesn't exist, we still return 'sent' to avoid leaking
      // account existence (matches Firebase's email-enumeration protection).
      if (err.code === 'auth/user-not-found') {
        console.log(`[reset] User not found (${email}) — silently OK`);
        return { status: 'sent' };
      }
      console.error(`[reset] ✗ Error for ${email}:`, err.message);
      throw new functions.https.HttpsError('internal', err.message);
    }
  }
);

// ---- Email templates --------------------------------------------------------
function brandStyles() {
  return `
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #1A1A2E; margin: 0; padding: 0; }
    .container { max-width: 480px; margin: 0 auto; padding: 40px 20px; }
    .card { background-color: #2D2D44; border-radius: 16px; padding: 40px 32px; text-align: center; }
    .logo { width: 80px; height: 80px; margin: 0 auto 24px; display: block; }
    h1 { color: #FFFFFF; font-size: 22px; font-weight: 700; margin: 0 0 12px; }
    p { color: #B8B8C8; font-size: 15px; line-height: 1.5; margin: 0 0 24px; }
    .button { display: inline-block; padding: 14px 40px; background-color: #6CB4E8; color: #1A1A2E; font-size: 16px; font-weight: 700; text-decoration: none; border-radius: 12px; }
    .footer { color: #6B6B80; font-size: 12px; margin-top: 32px; }
  `;
}

function buildVerificationEmail(name, link) {
  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"><style>${brandStyles()}</style></head>
    <body>
      <div class="container">
        <div class="card">
          <img class="logo" src="https://maypole.app/icons/ic_logo_splash.png" alt="Maypole">
          <h1>Verify your email</h1>
          <p>Hi ${escapeHtml(name)},<br>Thanks for joining Maypole! Click below to verify your email address and get started.</p>
          <a class="button" href="${escapeAttr(link)}">Verify Email</a>
          <p class="footer">If you didn't create a Maypole account, you can safely ignore this email.</p>
        </div>
      </div>
    </body>
    </html>`;
}

function buildPasswordResetEmail(email, link) {
  return `
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"><style>${brandStyles()}</style></head>
    <body>
      <div class="container">
        <div class="card">
          <img class="logo" src="https://maypole.app/icons/ic_logo_splash.png" alt="Maypole">
          <h1>Reset your password</h1>
          <p>We received a request to reset the password for<br><strong>${escapeHtml(email)}</strong>.<br>Click below to choose a new one.</p>
          <a class="button" href="${escapeAttr(link)}">Reset Password</a>
          <p class="footer">If you didn't request this, you can safely ignore this email. The link expires in 1 hour.</p>
        </div>
      </div>
    </body>
    </html>`;
}

function escapeHtml(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function escapeAttr(s) {
  return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// ============================================================================
// AdSense ads.txt serving and verification
// ============================================================================

/**
 * Serves ads.txt file for AdSense verification
 * This provides a backup method to ensure ads.txt is always accessible
 * Even if it gets removed from static hosting
 * 
 * Access: https://us-central1-maypole-flutter-ce6c3.cloudfunctions.net/serveAdsTxt
 */
exports.serveAdsTxt = functions.https.onRequest((req, res) => {
  // AdSense publisher ID
  const adsTxtContent = 'google.com, pub-9803674282352310, DIRECT, f08c47fec0942fa0';
  
  console.log('📱 Serving ads.txt from Cloud Function');
  
  res.set('Content-Type', 'text/plain');
  res.set('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
  res.status(200).send(adsTxtContent);
});

/**
 * Verifies that ads.txt is accessible from the main domain
 * This health check endpoint can be called to verify AdSense setup
 * 
 * Access: https://us-central1-maypole-flutter-ce6c3.cloudfunctions.net/verifyAdsTxt
 * 
 * Returns JSON with:
 * - accessible: boolean
 * - content: string (if accessible)
 * - error: string (if not accessible)
 * - timestamp: ISO string
 * - url: string (the URL checked)
 */
exports.verifyAdsTxt = functions.https.onRequest(async (req, res) => {
  const domain = req.query.domain || 'https://maypole.app';
  const adsTxtUrl = `${domain}/ads.txt`;
  
  console.log(`🔍 Verifying ads.txt at: ${adsTxtUrl}`);
  
  try {
    // Use native fetch (available in Node.js 18+)
    const response = await fetch(adsTxtUrl);
    const content = await response.text();
    
    const isAccessible = response.status === 200 && content.includes('google.com');
    const expectedPublisher = 'pub-9803674282352310';
    const hasCorrectPublisher = content.includes(expectedPublisher);
    
    const result = {
      accessible: isAccessible && hasCorrectPublisher,
      status: response.status,
      content: content,
      url: adsTxtUrl,
      timestamp: new Date().toISOString(),
      checks: {
        statusOk: response.status === 200,
        containsGoogle: content.includes('google.com'),
        hasPublisherId: hasCorrectPublisher,
        expectedPublisherId: expectedPublisher
      }
    };
    
    console.log(`✅ Verification result: ${result.accessible ? 'PASS' : 'FAIL'}`);
    
    res.set('Content-Type', 'application/json');
    res.status(200).json(result);
    
  } catch (error) {
    console.error(`❌ Error verifying ads.txt: ${error.message}`);
    
    res.set('Content-Type', 'application/json');
    res.status(200).json({
      accessible: false,
      error: error.message,
      url: adsTxtUrl,
      timestamp: new Date().toISOString()
    });
  }
});

// ============================================================================
// Authentication Triggers
// ============================================================================

/**
 * Triggered when a Firebase Auth user is deleted.
 * Automatically cleans up all associated Firestore data:
 * - User document in 'users' collection
 * - Username reservation in 'usernames' collection
 * - Notifications subcollection
 */
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  
  console.log(`🗑️ Auth user deleted: ${userId}`);
  
  try {
    // Get user document to retrieve username
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      console.log(`⚠️ User document ${userId} not found (may have been deleted already)`);
      return null;
    }
    
    const userData = userDoc.data();
    const username = userData?.username;
    
    if (username) {
      console.log(`Found username: ${username}`);
    }
    
    // Delete notifications subcollection
    try {
      const notificationsSnapshot = await userRef.collection('notifications').get();
      
      if (!notificationsSnapshot.empty) {
        const batch = db.batch();
        let count = 0;
        
        notificationsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
          count++;
        });
        
        await batch.commit();
        console.log(`✓ Deleted ${count} notifications for user ${userId}`);
      }
    } catch (e) {
      console.log(`⚠️ Error deleting notifications: ${e.message}`);
    }
    
    // Delete username reservation
    if (username) {
      try {
        await db.collection('usernames').doc(username.toLowerCase()).delete();
        console.log(`✓ Deleted username reservation for ${username}`);
      } catch (e) {
        console.log(`⚠️ Error deleting username reservation: ${e.message}`);
      }
    }
    
    // Delete user document
    try {
      await userRef.delete();
      console.log(`✓ Deleted user document for ${userId}`);
    } catch (e) {
      console.log(`⚠️ Error deleting user document: ${e.message}`);
    }
    
    console.log(`✅ Successfully completed cleanup for user ${userId}`);
    return null;
    
  } catch (error) {
    console.error(`❌ Error in user deletion cleanup for ${userId}:`, error);
    
    // Log to a failure collection for manual review
    try {
      await db.collection('deletion_failures').add({
        userId: userId,
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`📝 Logged deletion failure for manual review`);
    } catch (logError) {
      console.error(`❌ Could not log deletion failure: ${logError.message}`);
    }
    
    return null;
  }
});

/**
 * Alternative: Triggered when user document is updated with deletionRequested flag.
 * This handles the case where re-authentication prevents immediate auth deletion.
 */
exports.onAccountDeletionRequested = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only proceed if deletionRequested was just set to true
    if (!after.deletionRequested || before.deletionRequested) {
      return null;
    }
    
    const userId = context.params.userId;
    const username = after.username;
    
    console.log(`🗑️ Account deletion requested for user: ${userId} (username: ${username})`);
    
    try {
      // Delete Firebase Auth account first
      // (Firestore cleanup will be handled by onUserDeleted trigger)
      try {
        await admin.auth().deleteUser(userId);
        console.log(`✓ Deleted auth account for ${userId}`);
        
        // The onUserDeleted trigger will handle Firestore cleanup
        console.log(`✅ Auth deleted - onUserDeleted will handle Firestore cleanup`);
      } catch (authError) {
        if (authError.code === 'auth/user-not-found') {
          console.log(`⚠️ Auth account ${userId} already deleted - cleaning up Firestore`);
          
          // Auth already deleted, so manually clean up Firestore
          const userRef = db.collection('users').doc(userId);
          
          // Delete notifications
          const notificationsSnapshot = await userRef.collection('notifications').get();
          if (!notificationsSnapshot.empty) {
            const batch = db.batch();
            notificationsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            console.log(`✓ Deleted ${notificationsSnapshot.size} notifications`);
          }
          
          // Delete username
          if (username) {
            await db.collection('usernames').doc(username.toLowerCase()).delete();
            console.log(`✓ Deleted username reservation for ${username}`);
          }
          
          // Delete user document
          await userRef.delete();
          console.log(`✓ Deleted user document`);
        } else {
          throw authError;
        }
      }
      
      return null;
      
    } catch (error) {
      console.error(`❌ Error processing account deletion for ${userId}:`, error);
      
      // Log failure
      try {
        await db.collection('deletion_failures').add({
          userId: userId,
          username: username,
          error: error.message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (logError) {
        console.error(`❌ Could not log deletion failure: ${logError.message}`);
      }
      
      return null;
    }
  });
