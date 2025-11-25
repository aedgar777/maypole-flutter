# Cloud Functions for Firebase for Python
# Deploy with `firebase deploy --only functions`

from firebase_functions import https_fn, options
from firebase_admin import initialize_app
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
