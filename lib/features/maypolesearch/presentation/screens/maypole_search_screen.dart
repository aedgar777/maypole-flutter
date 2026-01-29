import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/utils/place_geofence_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
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
  
  // Context menu state
  Map<String, dynamic>? _contextMenuPlace;
  LatLng? _contextMenuLocation;

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
    // When search bar gains focus, close any open bottom sheet
    if (_searchFocusNode.hasFocus && _contextMenuPlace != null) {
      setState(() {
        _contextMenuPlace = null;
        _contextMenuLocation = null;
      });
    }
    // Trigger rebuild when focus changes to update background
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(maypoleSearchViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentPosition = ref.watch(currentPositionProvider);
    final hasLocationPermission = ref.watch(hasLocationPermissionProvider);

    return Scaffold(
      backgroundColor: darkPurple, // Dark purple background while map loads
      // No app bar - search bar makes it redundant
      appBar: null,
      body: Stack(
        children: [
          // Google Map in the background - full screen
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
              
              // Move to user's location if permission is granted and we don't already have the position
              if (hasLocationPermission.value == true) {
                final currentPos = currentPosition.value;
                
                // Only fetch and move if we didn't already start at the user's location
                if (currentPos == null) {
                  debugPrint('📍 Permission granted, fetching user location...');
                  final locationService = ref.read(locationServiceProvider);
                  final position = await locationService.getCurrentPosition();
                  
                  if (position != null && mounted) {
                    debugPrint('✅ Moving map to user location: ${position.latitude}, ${position.longitude}');
                    await controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(position.latitude, position.longitude),
                          zoom: 14.0,
                        ),
                      ),
                    );
                  }
                } else {
                  debugPrint('✅ Map already initialized at user location: ${currentPos.latitude}, ${currentPos.longitude}');
                }
              } else {
                debugPrint('⚠️ No location permission, using default position');
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
              // Start with user's position if available, otherwise default position
              target: currentPosition.whenData((pos) {
                if (pos != null) {
                  return LatLng(pos.latitude, pos.longitude);
                }
                return const LatLng(37.7749, -122.4194); // San Francisco as fallback
              }).value ?? const LatLng(37.7749, -122.4194),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Disable default button - we'll add custom one
            mapType: MapType.normal,
            onTap: _onMapTapped,
            zoomControlsEnabled: false,
            // Note: Google Maps POI info windows will still appear
            // This is a limitation of the google_maps_flutter package
          ),

          // Overlay with search bar and results
          Column(
            children: [
              // Add safe area padding on mobile to push search bar below status bar (half distance)
              // This container gets tinted when search is active
              if (!AppConfig.isWideScreen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: MediaQuery.of(context).padding.top + (kToolbarHeight / 2),
                  color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                      ? darkPurple.withOpacity(0.9) // 90% opacity when focused/has text
                      : Colors.transparent, // Transparent when unfocused and empty
                ),
              // Search bar with conditional background and padding
              // Extra left padding on iOS to make room for back button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                    ? darkPurple.withOpacity(0.9) // 90% opacity when focused/has text
                    : Colors.transparent, // Transparent when unfocused and empty
                padding: EdgeInsets.fromLTRB(
                  (!kIsWeb && Platform.isIOS) ? 56.0 : 8.0, // Extra left padding on iOS for back button
                  8.0,
                  8.0,
                  4.0,
                ),
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
                    // When search is NOT active, ignore pointer events (allow map clicks through)
                    // When search IS active, don't ignore (block map clicks)
                    ignoring: !_searchFocusNode.hasFocus && _searchController.text.isEmpty,
                    child: GestureDetector(
                      // Absorb taps on the background to close search and prevent map clicks
                      onTap: () {
                        if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
                        }
                      },
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
          
          // Non-modal bottom sheet overlay
          if (_contextMenuPlace != null && _contextMenuLocation != null)
            _buildBottomSheet(_contextMenuPlace!, _contextMenuLocation!),
          
          // Back button for iOS (upper left - iOS standard)
          if (!kIsWeb && Platform.isIOS)
            Positioned(
              top: MediaQuery.of(context).padding.top + (kToolbarHeight / 2) + 8,
              left: 8,
              child: Material(
                color: darkPurple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          
          // Custom "My Location" button (bottom right) - placed LAST to appear on top
          Positioned(
            bottom: _contextMenuPlace != null ? 280 : 16, // Move up well above bottom sheet when showing
            right: 16,
            child: Material(
              color: (hasLocationPermission.value == true) 
                  ? skyBlue // Blue background when permission granted
                  : Colors.grey[600], // Gray when no permission
              borderRadius: BorderRadius.circular(4),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _handleLocationButtonTap(hasLocationPermission.value == true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white, // White icon
                    size: 24,
                  ),
                ),
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
        
        // Extract coordinates and place type from place details
        // Google Places API v1 structure: { "location": { "latitude": X, "longitude": Y }, "primaryType": "...", "types": [...] }
        final location = placeDetails['location'] as Map<String, dynamic>?;
        final latitude = location?['latitude'] as double?;
        final longitude = location?['longitude'] as double?;
        
        // Get place type - use primaryType if available, otherwise find best match from types array
        debugPrint('🔍 EXTRACTING PLACE TYPE:');
        debugPrint('   Raw primaryType field: ${placeDetails['primaryType']}');
        debugPrint('   primaryType exists: ${placeDetails.containsKey('primaryType')}');
        
        String? placeType = placeDetails['primaryType'] as String?;
        debugPrint('   Extracted primaryType: $placeType');
        
        if (placeType == null || placeType.isEmpty) {
          debugPrint('   ⚠️ primaryType is null/empty, checking types array...');
          final types = placeDetails['types'] as List<dynamic>?;
          debugPrint('   Raw types: $types');
          
          if (types != null && types.isNotEmpty) {
            debugPrint('   Found ${types.length} types, checking priority order...');
            // Priority order for determining range (most specific to least specific)
            const priorityOrder = [
              'sublocality_level_1',
              'sublocality',
              'locality',
              'neighborhood',
              'administrative_area_level_2',
              'administrative_area_level_1',
              'political',
              'country',
            ];
            
            for (final priority in priorityOrder) {
              if (types.contains(priority)) {
                placeType = priority;
                debugPrint('   ✅ FOUND MATCH: $placeType (from types array)');
                break;
              }
            }
            
            if (placeType == null) {
              debugPrint('   ❌ No priority type found in types array');
            }
          } else {
            debugPrint('   ❌ types array is null or empty');
          }
        } else {
          debugPrint('   ✅ Using primaryType: $placeType');
        }

        debugPrint('📍 FINAL RESULTS:');
        debugPrint('   Coordinates: lat=$latitude, lon=$longitude');
        debugPrint('   Place type: $placeType');
        debugPrint('   Will get range: ${placeType != null ? PlaceGeofenceUtils.getRadiusDescription(placeType) : "1 km (default)"}');

        // Return prediction with coordinates and place type
        final updatedPrediction = prediction.copyWith(
          latitude: latitude,
          longitude: longitude,
          placeType: placeType,
        );
        
        debugPrint('✅ Returning prediction with coordinates and type: ${updatedPrediction.latitude}, ${updatedPrediction.longitude}, ${updatedPrediction.placeType}');
        
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

  Future<void> _handleLocationButtonTap(bool hasPermission) async {
    if (!hasPermission) {
      // Show permission dialog
      _showLocationPermissionDialog();
      return;
    }
    
    // Center on location
    await _centerOnUserLocation();
  }

  void _showLocationPermissionDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationPermissionRequired),
        content: Text(l10n.locationPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final locationService = ref.read(locationServiceProvider);
              final permission = await locationService.requestPermission();
              
              if (permission == LocationPermission.denied || 
                  permission == LocationPermission.deniedForever) {
                if (mounted) {
                  // Open settings if permission is permanently denied
                  if (permission == LocationPermission.deniedForever) {
                    await locationService.openAppSettings();
                  }
                }
              } else {
                // Permission granted, refresh and center
                if (mounted) {
                  ref.invalidate(hasLocationPermissionProvider);
                  ref.invalidate(currentPositionProvider);
                  await _centerOnUserLocation();
                }
              }
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    try {
      // Force refresh the position
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      if (position != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                position.latitude,
                position.longitude,
              ),
              zoom: 16.0,
            ),
          ),
        );
        debugPrint('✅ Centered on user location: ${position.latitude}, ${position.longitude}');
      } else {
        debugPrint('⚠️ Could not get user location');
      }
    } catch (e) {
      debugPrint('💥 Error centering on location: $e');
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    // Don't handle map taps if search is focused or has text
    if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
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
          _contextMenuPlace = placeDetails;
          _contextMenuLocation = position;
        });
      } else {
        // No place found, show a generic location option
        setState(() {
          _contextMenuPlace = {'isGeneric': true};
          _contextMenuLocation = position;
        });
      }
    } catch (e) {
      debugPrint('💥 Error reverse geocoding: $e');
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error but still allow generic location
      ErrorDialog.show(context, e);
      setState(() {
        _contextMenuPlace = {'isGeneric': true};
        _contextMenuLocation = position;
      });
    }
  }

  Widget _buildBottomSheet(Map<String, dynamic> placeDetails, LatLng position) {
    final l10n = AppLocalizations.of(context)!;
    final isGeneric = placeDetails['isGeneric'] == true;
    
    final displayName = isGeneric
        ? 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})'
        : (placeDetails['displayName']?['text'] as String? ?? 'Unknown Place');
    
    final formattedAddress = isGeneric
        ? 'Selected location on map'
        : (placeDetails['formattedAddress'] as String? ?? '');
    
    final placeId = isGeneric
        ? 'loc_${position.latitude}_${position.longitude}'
        : (placeDetails['id'] as String? ?? '');
    
    // Get place type - use primaryType if available, otherwise find best match from types array
    String? placeType;
    if (!isGeneric) {
      debugPrint('🔍 EXTRACTING PLACE TYPE (reverse geocode):');
      debugPrint('   Raw primaryType field: ${placeDetails['primaryType']}');
      
      placeType = placeDetails['primaryType'] as String?;
      debugPrint('   Extracted primaryType: $placeType');
      
      if (placeType == null || placeType.isEmpty) {
        debugPrint('   ⚠️ primaryType is null/empty, checking types array...');
        final types = placeDetails['types'] as List<dynamic>?;
        debugPrint('   Raw types: $types');
        
        if (types != null && types.isNotEmpty) {
          debugPrint('   Found ${types.length} types, checking priority order...');
          // Priority order for determining range
          const priorityOrder = [
            'sublocality_level_1',
            'sublocality',
            'locality',
            'neighborhood',
            'administrative_area_level_2',
            'administrative_area_level_1',
            'political',
            'country',
          ];
          
          for (final priority in priorityOrder) {
            if (types.contains(priority)) {
              placeType = priority;
              debugPrint('   ✅ FOUND MATCH: $placeType (from types array)');
              break;
            }
          }
          
          if (placeType == null) {
            debugPrint('   ❌ No priority type found in types array');
          }
        } else {
          debugPrint('   ❌ types array is null or empty');
        }
      } else {
        debugPrint('   ✅ Using primaryType: $placeType');
      }
      
      debugPrint('📍 FINAL place type: $placeType (range: ${placeType != null ? PlaceGeofenceUtils.getRadiusDescription(placeType) : "1 km (default)"})');
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        // Absorb taps to prevent map interaction
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
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
              const SizedBox(height: 12),
              // View on Google Maps link
              InkWell(
                onTap: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View on Google Maps',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Web ad banner
              if (kIsWeb && AdConfig.webAdsEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: WebHorizontalBannerAd(adSlot: '3398941414'), // Maypole Web Banner
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _contextMenuPlace = null;
                      _contextMenuLocation = null;
                    });
                    _navigateToChat(
                      placeId: placeId,
                      placeName: displayName,
                      address: formattedAddress,
                      latitude: position.latitude,
                      longitude: position.longitude,
                      placeType: placeType,
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
      ),
    );
  }

  void _navigateToChat({
    required String placeId,
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
    String? placeType,
  }) {
    // Create a PlacePrediction and return it to the caller (home screen)
    // This allows the home screen to handle navigation consistently
    final prediction = PlacePrediction(
      place: placeName, // Use placeName as the display text (full text)
      placeId: placeId,
      placeName: placeName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeType: placeType,
    );
    
    context.pop(prediction);
  }
}
