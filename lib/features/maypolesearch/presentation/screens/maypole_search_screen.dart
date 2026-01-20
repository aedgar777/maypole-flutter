import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/maypole_search_service_provider.dart';
import '../../maypole_search_providers.dart';

// Dark map style using app theme colors
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1A1A2E"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1A1A2E"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#2D2D44"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#2D2D44"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6CB4E8"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#2D2D44"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6CB4E8"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6CB4E8"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

class MaypoleSearchScreen extends ConsumerStatefulWidget {
  const MaypoleSearchScreen({super.key});

  @override
  ConsumerState<MaypoleSearchScreen> createState() => _MaypoleSearchScreenState();
}

class _MaypoleSearchScreenState extends ConsumerState<MaypoleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  GoogleMapController? _mapController;
  final FocusNode _searchFocusNode = FocusNode();
  Map<String, dynamic>? _selectedPlace;
  LatLng? _selectedLocation;
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Trigger rebuild when focus changes to update background
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(maypoleSearchViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentPosition = ref.watch(currentPositionProvider);

    return Scaffold(
      backgroundColor: darkPurple, // Dark purple background while map loads
      appBar: AppBar(
        title: Text(l10n.searchMaypoles),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: Stack(
        children: [
          // Google Map in the background - takes full screen
          GoogleMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              debugPrint('🗺️ Map created');
              // Apply dark map style
              try {
                await controller.setMapStyle(_darkMapStyle);
                debugPrint('✅ Map style applied successfully');
              } catch (e) {
                debugPrint('⚠️ Error applying map style: $e');
              }
              // Mark map as loaded after a short delay to ensure tiles are rendered
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                setState(() {
                  _isMapLoaded = true;
                });
              }
            },
            initialCameraPosition: CameraPosition(
              target: currentPosition.value != null
                  ? LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude)
                  : const LatLng(37.7749, -122.4194),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onTap: _onMapTapped,
            zoomControlsEnabled: false,
          ),

          // Overlay with search bar and results
          Column(
            children: [
              // Search bar with conditional background
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                    ? darkPurple.withOpacity(0.9) // 90% opacity when focused/has text
                    : Colors.transparent, // Transparent when unfocused and empty
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n.searchForMaypole,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: lightPurple,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: skyBlue,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Animated search results list with semi-transparent background
              Expanded(
                child: AnimatedOpacity(
                  opacity: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_searchFocusNode.hasFocus && _searchController.text.isEmpty,
                    child: Container(
                      color: darkPurple.withOpacity(0.9), // 90% opacity background
                      child: searchState.when(
                        data: (predictions) => _buildPredictionsList(predictions),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ErrorDialog.show(context, error);
                          });
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay to cover white flash while map loads
          if (!_isMapLoaded)
            Container(
              color: darkPurple,
              child: const Center(
                child: CircularProgressIndicator(
                  color: skyBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionsList(List<PlacePrediction> predictions) {
    return ListView.builder(
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return ListTile(
          title: Text(prediction.place),
          onTap: () async {
            // Fetch place details to get coordinates
            await _fetchPlaceDetailsAndReturn(prediction);
          },
        );
      },
    );
  }

  Future<void> _fetchPlaceDetailsAndReturn(PlacePrediction prediction) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch place details including coordinates
      final searchService = ref.read(maypoleSearchServiceProvider);
      final placeDetails = await searchService.getPlaceDetails(prediction.placeId);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (placeDetails != null) {
        debugPrint('🗺️ Place Details: $placeDetails');
        
        // Extract coordinates from place details
        // Google Places API v1 structure: { "location": { "latitude": X, "longitude": Y } }
        final location = placeDetails['location'] as Map<String, dynamic>?;
        final latitude = location?['latitude'] as double?;
        final longitude = location?['longitude'] as double?;

        debugPrint('📍 Extracted coordinates: lat=$latitude, lon=$longitude');

        // Return prediction with coordinates
        final updatedPrediction = prediction.copyWith(
          latitude: latitude,
          longitude: longitude,
        );
        
        debugPrint('✅ Returning prediction with coordinates: ${updatedPrediction.latitude}, ${updatedPrediction.longitude}');
        
        if (mounted) {
          context.pop(updatedPrediction);
        }
      } else {
        debugPrint('⚠️ No place details returned, using prediction without coordinates');
        // If we couldn't get details, return prediction without coordinates
        if (mounted) {
          context.pop(prediction);
        }
      }
    } catch (e) {
      debugPrint('💥 Error fetching place details: $e');
      if (!mounted) return;
      
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Show error but still return the prediction without coordinates
      ErrorDialog.show(context, e);
      
      if (mounted) {
        context.pop(prediction);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(maypoleSearchViewModelProvider.notifier)
          .searchMaypoles(_searchController.text);
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    // Don't handle map taps if search is focused
    if (_searchFocusNode.hasFocus) {
      return;
    }

    debugPrint('🗺️ Map tapped at: ${position.latitude}, ${position.longitude}');

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Reverse geocode to get place details
      final searchService = ref.read(maypoleSearchServiceProvider);
      final placeDetails = await searchService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (placeDetails != null) {
        setState(() {
          _selectedPlace = placeDetails;
          _selectedLocation = position;
        });

        // Show bottom sheet with place info
        _showPlaceBottomSheet(placeDetails, position);
      } else {
        // No place found, show a generic location option
        _showGenericLocationBottomSheet(position);
      }
    } catch (e) {
      debugPrint('💥 Error reverse geocoding: $e');
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error but still allow generic location
      ErrorDialog.show(context, e);
      _showGenericLocationBottomSheet(position);
    }
  }

  void _showPlaceBottomSheet(Map<String, dynamic> placeDetails, LatLng position) {
    final l10n = AppLocalizations.of(context)!;
    
    final displayName = placeDetails['displayName']?['text'] as String? ?? 'Unknown Place';
    final formattedAddress = placeDetails['formattedAddress'] as String? ?? '';
    final placeId = placeDetails['id'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (formattedAddress.isNotEmpty)
              Text(
                formattedAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _navigateToChat(
                    placeId: placeId,
                    placeName: displayName,
                    address: formattedAddress,
                    latitude: position.latitude,
                    longitude: position.longitude,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.chatHere,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenericLocationBottomSheet(LatLng position) {
    final l10n = AppLocalizations.of(context)!;
    
    final locationName = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected location on map',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _navigateToChat(
                    placeId: 'loc_${position.latitude}_${position.longitude}',
                    placeName: locationName,
                    address: '',
                    latitude: position.latitude,
                    longitude: position.longitude,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.chatHere,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat({
    required String placeId,
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    context.push('/chat/$placeId', extra: {
      'name': placeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
