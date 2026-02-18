/**
 * Firebase Cloud Functions for Authentication Triggers (Node.js)
 * 
 * This handles auth-specific triggers that aren't available in Python SDK
 * Uses Firebase Functions v1 API for auth triggers
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

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
