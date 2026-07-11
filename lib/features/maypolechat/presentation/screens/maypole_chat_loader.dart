import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/maypole.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/maypole_resolver_service.dart';
import '../../../maypolesearch/data/services/maypole_search_service.dart';
import 'maypole_chat_screen.dart';

/// Loader widget that fetches place details when navigating via deep link.
///
/// This widget:
/// 1. First checks Firestore for existing maypole metadata
/// 2. If not found, fetches from Google Places API
/// 3. Creates/updates Firestore document with place details
/// 4. Then shows the MaypoleChatScreen with the fetched data
class MaypoleChatLoader extends ConsumerStatefulWidget {
  final String threadId;
  final String? locationSlug;
  final String? placeSlug;

  const MaypoleChatLoader({
    super.key,
    required this.threadId,
    this.locationSlug,
    this.placeSlug,
  });

  @override
  ConsumerState<MaypoleChatLoader> createState() => _MaypoleChatLoaderState();
}

class _MaypoleChatLoaderState extends ConsumerState<MaypoleChatLoader> {
  final _resolverService = MaypoleResolverService();
  final _searchService = MaypoleSearchService();

  String? _resolvedThreadId;
  String? _placeName;
  String? _address;
  double? _latitude;
  double? _longitude;
  String? _placeType;
  String? _googlePlaceId;
  String? _locationSlug;
  String? _placeSlug;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlaceDetails();
  }

  Future<void> _fetchPlaceDetails() async {
    try {
      debugPrint('🔍 Fetching place details for threadId: ${widget.threadId}');

      // Step 1: Check Firestore for existing maypole metadata
      var maypoleDoc = await FirebaseFirestore.instance
          .collection('maypoles')
          .doc(widget.threadId)
          .get();

      if (!maypoleDoc.exists) {
        final aliasDoc = await FirebaseFirestore.instance
            .collection('placeIdAliases')
            .doc(widget.threadId)
            .get();
        final aliasMaypoleId = aliasDoc.data()?['maypoleId'] as String?;
        if (aliasMaypoleId != null && aliasMaypoleId.isNotEmpty) {
          maypoleDoc = await FirebaseFirestore.instance
              .collection('maypoles')
              .doc(aliasMaypoleId)
              .get();
        }
      }

      if (maypoleDoc.exists && maypoleDoc.data() != null) {
        final data = maypoleDoc.data()!;
        final metadata = MaypoleMetaData.fromMap(data);
        debugPrint('✅ Found maypole in Firestore');

        if (metadata.locationSlug == null || metadata.placeSlug == null) {
          debugPrint(
            'ℹ️ Maypole metadata is missing semantic slugs; using computed slugs without client-side backfill.',
          );
        }

        setState(() {
          _resolvedThreadId = metadata.id.isNotEmpty
              ? metadata.id
              : maypoleDoc.id;
          _placeName = metadata.name;
          _address = metadata.address;
          _latitude = metadata.latitude;
          _longitude = metadata.longitude;
          _placeType = metadata.placeType;
          _googlePlaceId = metadata.googlePlaceId;
          _locationSlug = metadata.effectiveLocationSlug;
          _placeSlug = metadata.effectivePlaceSlug;
          _isLoading = false;
        });

        // If we have the name, we're done
        if (_placeName != null && _placeName!.isNotEmpty) {
          return;
        }
      }

      // Step 2: Resolve stale Google IDs / semantic links through the canonical resolver.
      debugPrint('📍 Resolving maypole through canonical resolver...');
      try {
        final resolvedMaypole = await _resolverService.resolvePlace(
          googlePlaceId: widget.threadId,
          locationSlug: widget.locationSlug,
          placeSlug: widget.placeSlug,
        );

        if (resolvedMaypole.maypoleId != widget.threadId && mounted) {
          debugPrint(
            '🔁 Resolved stale place ID ${widget.threadId} to canonical maypole ${resolvedMaypole.maypoleId}',
          );
        }

        setState(() {
          _resolvedThreadId = resolvedMaypole.maypoleId;
          _placeName = resolvedMaypole.name;
          _address = resolvedMaypole.address;
          _latitude = resolvedMaypole.latitude;
          _longitude = resolvedMaypole.longitude;
          _placeType = resolvedMaypole.placeType;
          _googlePlaceId = resolvedMaypole.googlePlaceId;
          _locationSlug = resolvedMaypole.locationSlug;
          _placeSlug = resolvedMaypole.placeSlug;
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('⚠️ Canonical resolver failed: $e');
        if (kIsWeb) {
          setState(() {
            _placeName = 'Unknown Place';
            _error =
                'Could not resolve this shared place link. The place ID may be stale or no longer available.';
            _isLoading = false;
          });
          return;
        }
      }

      // Step 3: Fetch from Google Places API as a direct fallback for legacy mobile clients.
      debugPrint('📍 Fetching from Google Places API...');
      final placeDetails = await _searchService.getPlaceDetails(
        widget.threadId,
      );

      if (placeDetails != null) {
        debugPrint('✅ Got place details from Google Places API');

        // Extract place information
        final displayName = placeDetails['displayName'];
        final placeName = displayName is Map
            ? (displayName['text'] as String?) ?? 'Unknown Place'
            : 'Unknown Place';

        final formattedAddress = placeDetails['formattedAddress'] as String?;

        final location = placeDetails['location'] as Map<String, dynamic>?;
        final latitude = (location?['latitude'] as num?)?.toDouble();
        final longitude = (location?['longitude'] as num?)?.toDouble();

        // Step 3: Create/update Firestore document
        final metaData = MaypoleMetaData(
          id: widget.threadId,
          name: placeName,
          address: formattedAddress ?? '',
          latitude: latitude,
          longitude: longitude,
          googlePlaceId: widget.threadId,
          googlePlaceIdAliases: [widget.threadId],
          locationSlug: widget.locationSlug,
          placeSlug: widget.placeSlug,
        );

        await FirebaseFirestore.instance
            .collection('maypoles')
            .doc(widget.threadId)
            .set(metaData.toMap(), SetOptions(merge: true));

        debugPrint('✅ Updated Firestore with place details');

        setState(() {
          _resolvedThreadId = widget.threadId;
          _placeName = placeName;
          _address = formattedAddress;
          _latitude = latitude;
          _longitude = longitude;
          _googlePlaceId = widget.threadId;
          _locationSlug = metaData.effectiveLocationSlug;
          _placeSlug = metaData.effectivePlaceSlug;
          _isLoading = false;
        });
      } else {
        // Failed to fetch from API
        setState(() {
          _placeName = 'Unknown Place';
          _error = 'Could not fetch place details';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching place details: $e');
      setState(() {
        _placeName = 'Unknown Place';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _withDeepLinkBackHandling(
        context,
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading place details...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null && _placeName == 'Unknown Place') {
      return _withDeepLinkBackHandling(
        context,
        Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load place details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchPlaceDetails();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navigate to the actual chat screen with the fetched details.
    // MaypoleChatScreen wraps its own Scaffold in a PopScope that handles the
    // deep-link back behavior, so no extra handling is needed here.
    return MaypoleChatScreen(
      threadId: _resolvedThreadId ?? widget.threadId,
      maypoleName: _placeName ?? 'Unknown Place',
      address: _address,
      latitude: _latitude,
      longitude: _longitude,
      placeType: _placeType,
      googlePlaceId: _googlePlaceId,
      locationSlug: _locationSlug,
      placeSlug: _placeSlug,
    );
  }

  /// Wraps a deep-link entry screen so the Android system back button routes to
  /// the home/chat list instead of exiting the app when there is no in-app
  /// navigation history to pop.
  Widget _withDeepLinkBackHandling(BuildContext context, Widget child) {
    // Allow native back/swipe-back when there is in-app history to pop; only
    // intercept when this screen is the deep-link root (nothing to pop) so we
    // route into the app instead of exiting it.
    final canPop = GoRouter.of(context).canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        GoRouter.of(context).go('/home');
      },
      child: child,
    );
  }
}
