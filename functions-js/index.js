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
