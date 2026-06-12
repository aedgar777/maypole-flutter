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
    # NOTE: CORS headers are intentionally NOT set here. Every function that
    # returns json_response is decorated with `@https_fn.on_request(cors=...)`,
    # which already injects the Access-Control-Allow-* headers. Adding them here
    # too produces duplicate `Access-Control-Allow-Origin` headers on the
    # response, which browsers reject as a CORS error (breaking web clients while
    # mobile, which doesn't enforce CORS, keeps working).
    return https_fn.Response(
        json.dumps(data),
        status=status,
        headers={
            'Content-Type': 'application/json',
        },
    )
