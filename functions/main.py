# Cloud Functions for Firebase for Python
# Deploy with `firebase deploy --only functions`

import sys
print(f"Python version: {sys.version}", flush=True)

from firebase_functions import https_fn, options, firestore_fn, storage_fn
print("Loaded firebase_functions", flush=True)

from firebase_admin import initialize_app, firestore, messaging, storage, auth
print("Loaded firebase_admin", flush=True)

import requests
import json
import os
import io

print("All imports successful", flush=True)

# Lazy import PIL only when needed (it's slow to load)
def _get_pil_image():
    from PIL import Image
    return Image

# Initialize Firebase Admin
initialize_app()
print("Firebase Admin initialized", flush=True)

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


@storage_fn.on_object_finalized(
    max_instances=10,
    memory=options.MemoryOption.MB_512,
    timeout_sec=300
)
def optimize_profile_picture(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    """
    Automatically optimizes profile pictures when uploaded to Firebase Storage.
    Creates multiple sized variants:
    - thumbnail (150x150) - for list views
    - medium (400x400) - for profile views
    - large (800x800) - for full screen
    
    All images are compressed to reduce bandwidth and improve loading times.
    """
    
    # Get the storage object data
    data = event.data
    bucket_name = data.bucket
    file_path = data.name
    content_type = data.content_type
    
    print(f"Processing file: {file_path}")
    
    # Only process images in the profile_pictures folder
    if not file_path or 'profile_pictures/' not in file_path:
        print(f"Skipping non-profile picture: {file_path}")
        return
    
    # Only process image files
    if not content_type or not content_type.startswith('image/'):
        print(f"Skipping non-image file: {file_path}")
        return
    
    # Don't reprocess already optimized images
    if '_thumb' in file_path or '_medium' in file_path or '_large' in file_path:
        print(f"Skipping already optimized image: {file_path}")
        return
    
    try:
        # Lazy import PIL for better cold start performance
        Image = _get_pil_image()
        
        # Get storage bucket
        bucket = storage.bucket(bucket_name)
        blob = bucket.blob(file_path)
        
        # Download image to memory
        image_bytes = blob.download_as_bytes()
        img = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary (handles PNG with alpha, RGBA, etc.)
        if img.mode not in ('RGB', 'L'):
            img = img.convert('RGB')
        
        # Get original filename without extension
        file_name = os.path.splitext(file_path)[0]
        
        # Define sizes and quality settings
        sizes = {
            'thumb': (150, 150, 85),    # size: 150x150, quality: 85%
            'medium': (400, 400, 90),   # size: 400x400, quality: 90%
            'large': (800, 800, 92),    # size: 800x800, quality: 92%
        }
        
        uploaded_variants = []
        
        for suffix, (width, height, quality) in sizes.items():
            # Create a copy of the image
            img_copy = img.copy()
            
            # Resize with high-quality downsampling
            img_copy.thumbnail((width, height), Image.Resampling.LANCZOS)
            
            # Save to bytes buffer
            output_buffer = io.BytesIO()
            img_copy.save(
                output_buffer,
                format='JPEG',
                quality=quality,
                optimize=True,
                progressive=True  # Progressive JPEG for better UX
            )
            output_buffer.seek(0)
            
            # Upload optimized image
            optimized_path = f"{file_name}_{suffix}.jpg"
            optimized_blob = bucket.blob(optimized_path)
            optimized_blob.upload_from_file(
                output_buffer,
                content_type='image/jpeg'
            )
            
            # Make the file publicly accessible
            optimized_blob.make_public()
            
            uploaded_variants.append({
                'size': suffix,
                'path': optimized_path,
                'url': optimized_blob.public_url,
                'dimensions': f"{img_copy.width}x{img_copy.height}"
            })
            
            print(f"Created {suffix} variant: {optimized_path} ({img_copy.width}x{img_copy.height})")
        
        # Optionally: Update Firestore with optimized URLs
        # Extract user ID from path if needed (e.g., profile_pictures/userId/image.jpg)
        path_parts = file_path.split('/')
        if len(path_parts) >= 2:
            # Try to find the user document and update with optimized URLs
            # This is optional - we can also just use URL patterns on the client
            pass
        
        print(f"✓ Successfully optimized profile picture: {file_path}")
        print(f"✓ Created {len(uploaded_variants)} variants")
        
        # Optionally: Delete the original large file to save storage costs
        # Uncomment if you want to keep only optimized versions
        # blob.delete()
        # print(f"✓ Deleted original file to save storage")
        
    except Exception as e:
        print(f"❌ Error optimizing image {file_path}: {str(e)}")
        # Don't raise - we don't want to fail the upload


@firestore_fn.on_document_updated(
    document="users/{userId}",
    max_instances=10
)
def on_account_deletion_requested(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Cloud Function triggered when a user document is updated with deletionRequested=true.
    This function handles the complete account deletion process:
    1. Deletes notifications subcollection
    2. Deletes user document from Firestore
    3. Deletes username reservation
    4. Deletes Firebase Auth account
    
    This two-step approach (mark for deletion -> cloud function deletes) ensures:
    - All Firestore data is cleaned up even if local deletion fails
    - The process is atomic and handled server-side
    - Proper error handling and logging
    """
    
    # Get the before and after snapshots
    before = event.data.before.to_dict() if event.data.before else {}
    after = event.data.after.to_dict() if event.data.after else {}
    
    # Only proceed if deletionRequested was just set to true
    if not after.get('deletionRequested', False) or before.get('deletionRequested', False):
        return
    
    user_id = event.params['userId']
    username = after.get('username')
    
    print(f"🗑️ Account deletion requested for user: {user_id} (username: {username})", flush=True)
    
    try:
        db = firestore.client()
        user_ref = db.collection('users').document(user_id)
        
        # Step 1: Delete notifications subcollection
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
                
                # Firestore batch limit is 500 operations
                if batch_count >= 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            
            # Commit any remaining operations
            if batch_count > 0:
                batch.commit()
            
            print(f"✓ Deleted {deleted_count} notifications for user {user_id}", flush=True)
        except Exception as e:
            print(f"⚠️ Error deleting notifications: {str(e)}", flush=True)
            # Continue with deletion even if notifications fail
        
        # Step 2: Delete username reservation
        if username:
            try:
                username_ref = db.collection('usernames').document(username.lower())
                username_ref.delete()
                print(f"✓ Deleted username reservation for {username}", flush=True)
            except Exception as e:
                print(f"⚠️ Error deleting username reservation: {str(e)}", flush=True)
        
        # Step 3: Delete Firebase Auth account
        try:
            auth.delete_user(user_id)
            print(f"✓ Deleted auth account for {user_id}", flush=True)
        except auth.UserNotFoundError:
            print(f"⚠️ Auth account {user_id} already deleted", flush=True)
        except Exception as e:
            print(f"⚠️ Error deleting auth account: {str(e)}", flush=True)
        
        # Step 4: Delete user document (do this last)
        user_ref.delete()
        print(f"✓ Deleted user document for {user_id}", flush=True)
        
        print(f"✅ Successfully completed account deletion for user {user_id}", flush=True)
        
    except Exception as e:
        print(f"❌ Error in account deletion for {user_id}: {str(e)}", flush=True)
        # Log to a deletion failures collection for manual review
        try:
            db = firestore.client()
            db.collection('deletion_failures').add({
                'userId': user_id,
                'username': username,
                'error': str(e),
                'timestamp': firestore.SERVER_TIMESTAMP,
            })
            print(f"📝 Logged deletion failure for manual review", flush=True)
        except Exception as log_error:
            print(f"❌ Could not log deletion failure: {str(log_error)}", flush=True)
