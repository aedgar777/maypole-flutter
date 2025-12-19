# Cloud Functions for Firebase for Python
# Deploy with `firebase deploy --only functions`

from firebase_functions import https_fn, options, firestore_fn
from firebase_admin import initialize_app, firestore, messaging
import requests
import json
import os

# Initialize Firebase Admin
initialize_app()

# CORS configuration
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Goog-Api-Key, X-Goog-Field-Mask',
    'Access-Control-Max-Age': '3600',
}

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["get", "post", "options"],
    ),
    max_instances=10
)
def places_autocomplete(req: https_fn.Request) -> https_fn.Response:
    """
    Proxy function for Google Places API autocomplete requests.
    This avoids CORS issues when calling from web clients.
    """
    
    # Handle preflight OPTIONS request
    if req.method == 'OPTIONS':
        return https_fn.Response(
            status=204,
            headers=CORS_HEADERS
        )
    
    # Only allow POST requests
    if req.method != 'POST':
        return https_fn.Response(
            json.dumps({'error': 'Method not allowed'}),
            status=405,
            headers={'Content-Type': 'application/json', **CORS_HEADERS}
        )
    
    try:
        # Get API key from environment or request headers
        api_key = os.environ.get('GOOGLE_PLACES_API_KEY')
        if not api_key:
            api_key = req.headers.get('X-Goog-Api-Key')
        
        if not api_key:
            return https_fn.Response(
                json.dumps({'error': 'API key is required'}),
                status=400,
                headers={'Content-Type': 'application/json', **CORS_HEADERS}
            )
        
        # Get field mask from request headers or use default
        field_mask = req.headers.get('X-Goog-Field-Mask', 
            'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat')
        
        # Forward the request to Google Places API
        places_url = 'https://places.googleapis.com/v1/places:autocomplete'
        headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-Field-Mask': field_mask,
        }
        
        # Get request body
        request_data = req.get_json(silent=True)
        if not request_data:
            return https_fn.Response(
                json.dumps({'error': 'Request body is required'}),
                status=400,
                headers={'Content-Type': 'application/json', **CORS_HEADERS}
            )
        
        # Make request to Google Places API
        response = requests.post(
            places_url,
            headers=headers,
            json=request_data,
            timeout=10
        )
        
        # Return the response with CORS headers
        return https_fn.Response(
            response.text,
            status=response.status_code,
            headers={'Content-Type': 'application/json', **CORS_HEADERS}
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=500,
            headers={'Content-Type': 'application/json', **CORS_HEADERS}
        )


@firestore_fn.on_document_created(document="users/{userId}/notifications/{notificationId}")
def send_notification(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Triggered when a new notification document is created.
    Sends a push notification to the user.
    Handles both tag notifications and DM notifications.
    """
    try:
        # Get the notification data
        notification_data = event.data.to_dict()
        if not notification_data:
            print("No notification data found")
            return

        notification_type = notification_data.get('type')
        if notification_type not in ['tag', 'dm']:
            print(f"Skipping unknown notification type: {notification_type}")
            return

        # Get the user's FCM token
        user_id = event.params['userId']
        db = firestore.client()
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            print(f"User {user_id} not found")
            return

        user_data = user_doc.to_dict()
        
        # Support both single token (old format) and multiple tokens (new format)
        fcm_tokens = user_data.get('fcmTokens', [])
        if not fcm_tokens:
            # Fall back to old single token format
            fcm_token = user_data.get('fcmToken')
            if fcm_token:
                fcm_tokens = [fcm_token]
        
        if not fcm_tokens:
            print(f"User {user_id} has no FCM tokens")
            return

        # Prepare the notification based on type
        sender_name = notification_data.get('senderName', 'Someone')
        message_body = notification_data.get('messageBody', '')
        thread_id = notification_data.get('threadId', '')

        # Truncate message body for notification
        display_body = message_body[:100] + '...' if len(message_body) > 100 else message_body

        # Create notification title and data based on type
        if notification_type == 'tag':
            maypole_name = notification_data.get('maypoleName', 'a maypole')
            title = f"{sender_name} tagged you in {maypole_name}"
            data = {
                'type': 'tag',
                'threadId': thread_id,
                'senderName': sender_name,
                'maypoleName': maypole_name,
            }
        else:  # DM notification
            title = f"New message from {sender_name}"
            data = {
                'type': 'dm',
                'threadId': thread_id,
                'senderName': sender_name,
            }

        # Send notification to all devices
        success_count = 0
        failed_tokens = []
        
        for token in fcm_tokens:
            try:
                # Configure platform-specific options for notification grouping
                android_config = messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        # Group notifications by thread for stacking
                        tag=thread_id,  # Same tag groups notifications together
                        # Notification channel for DMs vs Tags
                        channel_id='dm_messages' if notification_type == 'dm' else 'tag_mentions',
                        # Show notification even if app is in foreground
                        priority='high',
                        # Default sound and vibration
                        default_sound=True,
                        default_vibrate_timings=True,
                    ),
                    # Collapse key for grouping (older Android versions)
                    collapse_key=thread_id,
                )
                
                # iOS configuration for notification grouping
                apns_config = messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            # Thread ID for grouping notifications
                            thread_id=thread_id,
                            # Badge increment
                            badge=1,
                            # Sound
                            sound='default',
                            # Show as alert
                            alert=messaging.ApsAlert(
                                title=title,
                                body=display_body,
                            ),
                        ),
                    ),
                )
                
                # Create the FCM message with platform-specific configs
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

                # Send the message
                response = messaging.send(message)
                print(f"Successfully sent {notification_type} notification to {user_id} (token: {token[:10]}...): {response}")
                success_count += 1
            except messaging.UnregisteredError:
                # Token is no longer valid, mark for removal
                print(f"Token {token[:10]}... is unregistered, marking for removal")
                failed_tokens.append(token)
            except Exception as e:
                print(f"Error sending to token {token[:10]}...: {str(e)}")
                failed_tokens.append(token)
        
        # Remove invalid tokens
        if failed_tokens:
            user_ref.update({
                'fcmTokens': firestore.ArrayRemove(failed_tokens)
            })
            print(f"Removed {len(failed_tokens)} invalid FCM tokens for user {user_id}")
        
        print(f"Sent notification to {success_count}/{len(fcm_tokens)} devices for user {user_id}")

    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        # Don't raise - we don't want to fail the function
