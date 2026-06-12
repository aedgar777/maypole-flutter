import json
import re

import requests
from firebase_admin import firestore
from firebase_functions import https_fn, options

from shared import goog_places_api_key, json_response


def _slugify(value, fallback='maypole'):
    slug = re.sub(r'[^a-z0-9]+', '-', (value or '').lower().replace('&', ' and '))
    slug = re.sub(r'^-+|-+$', '', slug)
    slug = re.sub(r'-{2,}', '-', slug)
    return slug or fallback


def _location_slug_from_address(address):
    if not address:
        return 'nearby'

    parts = [part.strip() for part in address.split(',') if part.strip()]
    city_or_area = parts[-2] if len(parts) >= 2 else parts[0]
    city_or_area = re.sub(r'\b[A-Z]{2}\b', '', city_or_area)
    city_or_area = re.sub(r'\b\d{5}(?:-\d{4})?\b', '', city_or_area).strip()
    return _slugify(city_or_area, fallback='nearby')


def _get_places_api_key(req=None):
    api_key = goog_places_api_key.value
    if not api_key and req is not None:
        api_key = req.headers.get('X-Goog-Api-Key')
    return api_key


def _fetch_place_details(place_id, api_key):
    if not place_id or not api_key:
        return None

    response = requests.get(
        f'https://places.googleapis.com/v1/places/{place_id}',
        headers={
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,primaryType,types',
        },
        timeout=10,
    )

    if response.status_code == 200:
        return response.json()

    print(
        f'Place Details failed for {place_id}: {response.status_code} {response.text}',
        flush=True,
    )
    if response.status_code in (401, 403):
        raise RuntimeError(
            'Google Places API key is not authorized for server-side Place Details requests. '
            'Check the GOOGLE_PLACES_API_KEY function secret and its API key restrictions.'
        )
    return None


def _search_place_by_text(query, api_key):
    if not query or not api_key:
        return None

    response = requests.post(
        'https://places.googleapis.com/v1/places:searchText',
        headers={
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types',
        },
        json={
            'textQuery': query,
            'maxResultCount': 1,
        },
        timeout=10,
    )

    if response.status_code == 200:
        places = response.json().get('places', [])
        return places[0] if places else None

    print(
        f'Place Text Search failed for {query}: {response.status_code} {response.text}',
        flush=True,
    )
    if response.status_code in (401, 403):
        raise RuntimeError(
            'Google Places API key is not authorized for server-side Text Search requests. '
            'Check the GOOGLE_PLACES_API_KEY function secret and its API key restrictions.'
        )
    return None


_NEARBY_INCLUDED_TYPES = [
    'restaurant',
    'cafe',
    'bar',
    'store',
    'park',
    'tourist_attraction',
    'museum',
    'lodging',
    'art_gallery',
    'gas_station',
    'pharmacy',
    'bakery',
    'bank',
    'movie_theater',
    'gym',
    'library',
    'stadium',
    'zoo',
]


def _search_nearby(latitude, longitude, radius_meters, max_result_count, api_key, included_types=None):
    response = requests.post(
        'https://places.googleapis.com/v1/places:searchNearby',
        headers={
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType,places.types',
        },
        json={
            'includedTypes': included_types or _NEARBY_INCLUDED_TYPES,
            'locationRestriction': {
                'circle': {
                    'center': {
                        'latitude': latitude,
                        'longitude': longitude,
                    },
                    'radius': radius_meters,
                }
            },
            'maxResultCount': max_result_count,
            'rankPreference': 'DISTANCE',
        },
        timeout=10,
    )

    if response.status_code == 200:
        return response.json()

    print(
        f'Nearby Search failed at ({latitude}, {longitude}): {response.status_code} {response.text}',
        flush=True,
    )
    if response.status_code in (401, 403):
        raise RuntimeError(
            'Google Places API key is not authorized for server-side Nearby Search requests. '
            'Check the GOOGLE_PLACES_API_KEY function secret and its API key restrictions.'
        )
    return None


def _place_details_to_metadata(place_details, fallback_place_id=None):
    display_name = place_details.get('displayName') or {}
    name = display_name.get('text') or 'Unknown Place'
    address = place_details.get('formattedAddress') or ''
    location = place_details.get('location') or {}
    google_place_id = place_details.get('id') or fallback_place_id

    metadata = {
        'name': name,
        'address': address,
        'googlePlaceId': google_place_id,
        'locationSlug': _location_slug_from_address(address),
        'placeSlug': _slugify(name),
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

    if google_place_id:
        metadata['googlePlaceIdAliases'] = firestore.ArrayUnion([google_place_id])
    if location.get('latitude') is not None:
        metadata['latitude'] = location.get('latitude')
    if location.get('longitude') is not None:
        metadata['longitude'] = location.get('longitude')
    if place_details.get('primaryType'):
        metadata['placeType'] = place_details.get('primaryType')
    if place_details.get('types'):
        metadata['placeTypes'] = place_details.get('types')

    return metadata


def _alias_payload(maypole_id, status='current'):
    return {
        'maypoleId': maypole_id,
        'status': status,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }


@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["get", "post", "options"],
    ),
    max_instances=10,
    secrets=[goog_places_api_key],
)
def resolve_maypole(req: https_fn.Request) -> https_fn.Response:
    """
    Resolves mutable Google Place IDs to canonical Maypole IDs.

    Collections:
    - maypoles/{maypoleId}: canonical Maypole document
    - placeIdAliases/{googlePlaceId}: mapping from old/current Google Place IDs to maypoleId
    """
    if req.method != 'POST':
        return json_response({'error': 'Method not allowed'}, status=405)

    try:
        request_data = req.get_json(silent=True) or {}
        google_place_id = request_data.get('googlePlaceId') or request_data.get('placeId')
        name = request_data.get('name') or request_data.get('placeName') or ''
        address = request_data.get('address') or ''
        location_slug = request_data.get('locationSlug') or ''
        place_slug = request_data.get('placeSlug') or ''

        if not google_place_id and not (name or address or place_slug):
            return json_response({'error': 'googlePlaceId or place context is required'}, status=400)

        db = firestore.client()
        api_key = _get_places_api_key(req)

        stale_google_place_id = google_place_id
        alias_ref = db.collection('placeIdAliases').document(google_place_id) if google_place_id else None
        alias_doc = alias_ref.get() if alias_ref else None

        if alias_doc and alias_doc.exists:
            alias_data = alias_doc.to_dict() or {}
            maypole_id = alias_data.get('maypoleId')
            maypole_doc = db.collection('maypoles').document(maypole_id).get()
            if maypole_id and maypole_doc.exists:
                data = maypole_doc.to_dict() or {}
                return json_response({
                    'maypoleId': maypole_id,
                    'googlePlaceId': data.get('googlePlaceId') or google_place_id,
                    'name': data.get('name') or name,
                    'address': data.get('address') or address,
                    'latitude': data.get('latitude'),
                    'longitude': data.get('longitude'),
                    'placeType': data.get('placeType'),
                    'locationSlug': data.get('locationSlug'),
                    'placeSlug': data.get('placeSlug'),
                    'resolvedFromAlias': True,
                })

        # Backward compatibility: existing maypoles may still be keyed by Google Place ID.
        if google_place_id:
            legacy_doc = db.collection('maypoles').document(google_place_id).get()
            if legacy_doc.exists:
                data = legacy_doc.to_dict() or {}
                metadata = {
                    'id': google_place_id,
                    'googlePlaceId': data.get('googlePlaceId') or google_place_id,
                    'googlePlaceIdAliases': firestore.ArrayUnion([google_place_id]),
                    'locationSlug': data.get('locationSlug') or _location_slug_from_address(data.get('address') or address),
                    'placeSlug': data.get('placeSlug') or _slugify(data.get('name') or name),
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                }
                legacy_doc.reference.set(metadata, merge=True)
                alias_ref.set(_alias_payload(google_place_id), merge=True)
                return json_response({
                    'maypoleId': google_place_id,
                    'googlePlaceId': metadata['googlePlaceId'],
                    'name': data.get('name') or name,
                    'address': data.get('address') or address,
                    'latitude': data.get('latitude'),
                    'longitude': data.get('longitude'),
                    'placeType': data.get('placeType'),
                    'locationSlug': metadata['locationSlug'],
                    'placeSlug': metadata['placeSlug'],
                    'resolvedLegacyDocument': True,
                })

        place_details = _fetch_place_details(google_place_id, api_key) if google_place_id else None
        if place_details is None:
            query = ' '.join(part for part in [name, address] if part).strip()
            if not query and (place_slug or location_slug):
                query = f"{place_slug.replace('-', ' ')} {location_slug.replace('-', ' ')}".strip()
            place_details = _search_place_by_text(query, api_key)

        if place_details is None:
            return json_response({'error': 'Unable to resolve place'}, status=404)

        current_google_place_id = place_details.get('id') or google_place_id
        current_alias_ref = db.collection('placeIdAliases').document(current_google_place_id)
        current_alias_doc = current_alias_ref.get()

        if current_alias_doc.exists:
            maypole_id = (current_alias_doc.to_dict() or {}).get('maypoleId')
        else:
            existing = (
                db.collection('maypoles')
                .where('googlePlaceId', '==', current_google_place_id)
                .limit(1)
                .stream()
            )
            existing_doc = next(existing, None)
            maypole_id = existing_doc.id if existing_doc else db.collection('maypoles').document().id

        metadata = _place_details_to_metadata(place_details, fallback_place_id=current_google_place_id)
        metadata['id'] = maypole_id
        maypole_ref = db.collection('maypoles').document(maypole_id)
        maypole_ref.set(metadata, merge=True)

        current_alias_ref.set(_alias_payload(maypole_id, status='current'), merge=True)
        if stale_google_place_id and stale_google_place_id != current_google_place_id:
            db.collection('placeIdAliases').document(stale_google_place_id).set(
                _alias_payload(maypole_id, status='stale'),
                merge=True,
            )
            maypole_ref.set({
                'googlePlaceIdAliases': firestore.ArrayUnion([stale_google_place_id, current_google_place_id]),
                'updatedAt': firestore.SERVER_TIMESTAMP,
            }, merge=True)

        return json_response({
            'maypoleId': maypole_id,
            'googlePlaceId': current_google_place_id,
            'name': metadata.get('name'),
            'address': metadata.get('address'),
            'latitude': metadata.get('latitude'),
            'longitude': metadata.get('longitude'),
            'placeType': metadata.get('placeType'),
            'locationSlug': metadata.get('locationSlug'),
            'placeSlug': metadata.get('placeSlug'),
            'resolvedFromStalePlaceId': stale_google_place_id != current_google_place_id,
        })
    except Exception as e:
        print(f"Error resolving maypole: {str(e)}", flush=True)
        return json_response({'error': str(e)}, status=500)


@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["get", "post", "options"],
    ),
    max_instances=10,
    secrets=[goog_places_api_key],
)
def places_autocomplete(req: https_fn.Request) -> https_fn.Response:
    """
    Proxy function for Google Places API autocomplete requests.
    This avoids CORS issues when calling from web clients.
    CORS is handled by the decorator, so no manual headers needed.
    """
    if req.method != 'POST':
        return https_fn.Response(
            json.dumps({'error': 'Method not allowed'}),
            status=405,
            headers={'Content-Type': 'application/json'}
        )

    try:
        api_key = _get_places_api_key(req)

        if not api_key:
            return https_fn.Response(
                json.dumps({'error': 'API key is required'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )

        field_mask = req.headers.get(
            'X-Goog-Field-Mask',
            'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat'
        )

        places_url = 'https://places.googleapis.com/v1/places:autocomplete'
        headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': api_key,
            'X-Goog-Field-Mask': field_mask,
        }

        request_data = req.get_json(silent=True)
        if not request_data:
            return https_fn.Response(
                json.dumps({'error': 'Request body is required'}),
                status=400,
                headers={'Content-Type': 'application/json'}
            )

        response = requests.post(
            places_url,
            headers=headers,
            json=request_data,
            timeout=10
        )

        return https_fn.Response(
            response.text,
            status=response.status_code,
            headers={'Content-Type': 'application/json'}
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=500,
            headers={'Content-Type': 'application/json'}
        )


@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["get", "post", "options"],
    ),
    max_instances=10,
    secrets=[goog_places_api_key],
)
def places_place_details(req: https_fn.Request) -> https_fn.Response:
    """
    Proxy function for Google Places API place details requests.

    Keeps the (app/IP-restricted) Places API key on the server so mobile and web
    clients never need to ship a key. The place id may be supplied via the
    `X-Place-Id` header (preferred), a `placeId` query param, or a JSON body.
    """
    if req.method not in ('GET', 'POST'):
        return json_response({'error': 'Method not allowed'}, status=405)

    try:
        api_key = _get_places_api_key(req)
        if not api_key:
            return json_response({'error': 'API key is required'}, status=400)

        place_id = req.headers.get('X-Place-Id') or req.args.get('placeId')
        if not place_id and req.method == 'POST':
            body = req.get_json(silent=True) or {}
            place_id = body.get('placeId') or body.get('placeID')

        if not place_id:
            return json_response({'error': 'placeId is required'}, status=400)

        details = _fetch_place_details(place_id, api_key)
        if details is None:
            return json_response({'error': 'Place not found'}, status=404)

        return json_response(details)
    except Exception as e:
        return json_response({'error': str(e)}, status=500)


@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins="*",
        cors_methods=["get", "post", "options"],
    ),
    max_instances=10,
    secrets=[goog_places_api_key],
)
def places_reverse_geocode(req: https_fn.Request) -> https_fn.Response:
    """
    Proxy function for Google Places API nearby search ("reverse geocode").

    Accepts a JSON body of { latitude, longitude, radiusMeters, maxResultCount }
    and returns the raw Google Nearby Search payload ({ "places": [...] }) so the
    client can perform its own distance ranking.
    """
    if req.method != 'POST':
        return json_response({'error': 'Method not allowed'}, status=405)

    try:
        api_key = _get_places_api_key(req)
        if not api_key:
            return json_response({'error': 'API key is required'}, status=400)

        body = req.get_json(silent=True) or {}
        latitude = body.get('latitude')
        longitude = body.get('longitude')
        if latitude is None or longitude is None:
            return json_response({'error': 'latitude and longitude are required'}, status=400)

        radius_meters = body.get('radiusMeters', 150)
        max_result_count = body.get('maxResultCount', 5)
        included_types = body.get('includedTypes')

        result = _search_nearby(
            latitude,
            longitude,
            radius_meters,
            max_result_count,
            api_key,
            included_types=included_types,
        )

        return json_response(result or {'places': []})
    except Exception as e:
        return json_response({'error': str(e)}, status=500)
