# Cloud Functions for Firebase for Python
# Deploy with `firebase deploy --only functions`
#
# Function implementations are grouped by domain in sibling modules.
# This file intentionally re-exports the public function names Firebase deploys.

from account_deletion import on_account_deletion_requested
from notifications import send_notification
from places import places_autocomplete, resolve_maypole
from storage_optimization import optimize_profile_picture

__all__ = [
    'on_account_deletion_requested',
    'optimize_profile_picture',
    'places_autocomplete',
    'resolve_maypole',
    'send_notification',
]
