from firebase_admin import auth, firestore
from firebase_functions import firestore_fn

# Import shared to ensure Firebase Admin is initialized before triggers run.
import shared  # noqa: F401


@firestore_fn.on_document_updated(
    document="users/{userId}",
    max_instances=10
)
def on_account_deletion_requested(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggered when a user document is updated with deletionRequested=true.

    Handles:
    1. Deletes notifications subcollection
    2. Deletes username reservation
    3. Deletes Firebase Auth account
    4. Deletes user document
    """
    before = event.data.before.to_dict() if event.data.before else {}
    after = event.data.after.to_dict() if event.data.after else {}

    if not after.get('deletionRequested', False) or before.get('deletionRequested', False):
        return

    user_id = event.params['userId']
    username = after.get('username')

    print(f"🗑️ Account deletion requested for user: {user_id} (username: {username})", flush=True)

    try:
        db = firestore.client()
        user_ref = db.collection('users').document(user_id)

        try:
            notifications_ref = user_ref.collection('notifications')
            notifications = notifications_ref.stream()

            deleted_count = 0
            batch = db.batch()
            batch_count = 0

            for notification in notifications:
                batch.delete(notification.reference)
                batch_count += 1
                deleted_count += 1

                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0

            if batch_count > 0:
                batch.commit()

            print(f"✓ Deleted {deleted_count} notifications for user {user_id}", flush=True)
        except Exception as e:
            print(f"⚠️ Error deleting notifications: {str(e)}", flush=True)

        if username:
            try:
                username_ref = db.collection('usernames').document(username.lower())
                username_ref.delete()
                print(f"✓ Deleted username reservation for {username}", flush=True)
            except Exception as e:
                print(f"⚠️ Error deleting username reservation: {str(e)}", flush=True)

        try:
            auth.delete_user(user_id)
            print(f"✓ Deleted auth account for {user_id}", flush=True)
        except auth.UserNotFoundError:
            print(f"⚠️ Auth account {user_id} already deleted", flush=True)
        except Exception as e:
            print(f"⚠️ Error deleting auth account: {str(e)}", flush=True)

        user_ref.delete()
        print(f"✓ Deleted user document for {user_id}", flush=True)
        print(f"✅ Successfully completed account deletion for user {user_id}", flush=True)

    except Exception as e:
        print(f"❌ Error in account deletion for {user_id}: {str(e)}", flush=True)
        try:
            db = firestore.client()
            db.collection('deletion_failures').add({
                'userId': user_id,
                'username': username,
                'error': str(e),
                'timestamp': firestore.SERVER_TIMESTAMP,
            })
            print("📝 Logged deletion failure for manual review", flush=True)
        except Exception as log_error:
            print(f"❌ Could not log deletion failure: {str(log_error)}", flush=True)
