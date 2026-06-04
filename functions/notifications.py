from firebase_admin import firestore, messaging
from firebase_functions import firestore_fn

# Import shared to ensure Firebase Admin is initialized before triggers run.
import shared  # noqa: F401


@firestore_fn.on_document_created(document="users/{userId}/notifications/{notificationId}")
def send_notification(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Triggered when a new notification document is created.
    Sends a push notification to the user.
    Handles both tag notifications and DM notifications.
    """
    try:
        notification_data = event.data.to_dict()
        if not notification_data:
            print("No notification data found")
            return

        notification_type = notification_data.get('type')
        if notification_type not in ['tag', 'dm']:
            print(f"Skipping unknown notification type: {notification_type}")
            return

        user_id = event.params['userId']
        db = firestore.client()
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            print(f"User {user_id} not found")
            return

        user_data = user_doc.to_dict()

        fcm_tokens = user_data.get('fcmTokens', [])
        if not fcm_tokens:
            fcm_token = user_data.get('fcmToken')
            if fcm_token:
                fcm_tokens = [fcm_token]

        if not fcm_tokens:
            print(f"User {user_id} has no FCM tokens")
            return

        sender_name = notification_data.get('senderName', 'Someone')
        message_body = notification_data.get('messageBody', '')
        thread_id = notification_data.get('threadId', '')
        display_body = message_body[:100] + '...' if len(message_body) > 100 else message_body

        if notification_type == 'tag':
            maypole_name = notification_data.get('maypoleName', 'a maypole')
            title = f"{sender_name} tagged you in {maypole_name}"
            data = {
                'type': 'tag',
                'threadId': thread_id,
                'senderName': sender_name,
                'maypoleName': maypole_name,
            }
        else:
            title = f"New message from {sender_name}"
            data = {
                'type': 'dm',
                'threadId': thread_id,
                'senderName': sender_name,
            }

        success_count = 0
        failed_tokens = []

        for token in fcm_tokens:
            try:
                android_config = messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        tag=thread_id,
                        channel_id='dm_messages' if notification_type == 'dm' else 'tag_mentions',
                        priority='high',
                        default_sound=True,
                        default_vibrate_timings=True,
                    ),
                    collapse_key=thread_id,
                )

                apns_config = messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            thread_id=thread_id,
                            badge=1,
                            sound='default',
                            alert=messaging.ApsAlert(
                                title=title,
                                body=display_body,
                            ),
                        ),
                    ),
                )

                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=display_body,
                    ),
                    data=data,
                    android=android_config,
                    apns=apns_config,
                    token=token,
                )

                response = messaging.send(message)
                print(
                    f"Successfully sent {notification_type} notification to {user_id} "
                    f"(token: {token[:10]}...): {response}"
                )
                success_count += 1
            except messaging.UnregisteredError:
                print(f"Token {token[:10]}... is unregistered, marking for removal")
                failed_tokens.append(token)
            except Exception as e:
                print(f"Error sending to token {token[:10]}...: {str(e)}")
                failed_tokens.append(token)

        if failed_tokens:
            user_ref.update({
                'fcmTokens': firestore.ArrayRemove(failed_tokens)
            })
            print(f"Removed {len(failed_tokens)} invalid FCM tokens for user {user_id}")

        print(f"Sent notification to {success_count}/{len(fcm_tokens)} devices for user {user_id}")

    except Exception as e:
        print(f"Error sending notification: {str(e)}")
