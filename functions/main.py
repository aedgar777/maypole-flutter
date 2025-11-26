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
        fcm_token = user_data.get('fcmToken')

        if not fcm_token:
            print(f"User {user_id} has no FCM token")
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

        # Create the FCM message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=display_body,
            ),
            data=data,
            token=fcm_token,
        )

        # Send the message
        response = messaging.send(message)
        print(f"Successfully sent {notification_type} notification to {user_id}: {response}")

    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        # Don't raise - we don't want to fail the function
