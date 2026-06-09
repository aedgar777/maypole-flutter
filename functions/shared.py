import json
import sys

from firebase_admin import initialize_app
from firebase_functions import https_fn
from firebase_functions.params import SecretParam

print(f"Python version: {sys.version}", flush=True)

try:
    initialize_app()
    print("Firebase Admin initialized", flush=True)
except ValueError:
    print("Firebase Admin already initialized", flush=True)

# Secrets are set via Firebase Secrets Manager, for example:
# firebase functions:secrets:set GOOGLE_PLACES_API_KEY
goog_places_api_key = SecretParam("GOOGLE_PLACES_API_KEY")
hive_access_id = SecretParam("HIVE_ACCESS_ID_KEY")
hive_api_token = SecretParam("HIVE_API_TOKEN")


def json_response(data, status=200):
    return https_fn.Response(
        json.dumps(data),
        status=status,
        headers={
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, X-Goog-Api-Key, X-Place-Id',
        },
    )
