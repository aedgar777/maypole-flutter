import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/services/location_provider.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maypole/core/ads/widgets/web_ad_widget.dart';
import 'package:maypole/core/ads/ad_config.dart';
import '../../data/models/autocomplete_response.dart';
import '../../data/services/maypole_search_service_provider.dart';
import '../../maypole_search_providers.dart';

class MaypoleSearchScreen extends ConsumerStatefulWidget {
  final ValueChanged<PlacePrediction>? onPlaceSelected;
  final VoidCallback? onCloseRequested;
  final bool embedded;

  const MaypoleSearchScreen({
    super.key,
    this.onPlaceSelected,
    this.onCloseRequested,
    this.embedded = false,
  });

  @override
  ConsumerState<MaypoleSearchScreen> createState() => _MaypoleSearchScreenState();
}

class _MaypoleSearchScreenState extends ConsumerState<MaypoleSearchScreen> {
  static const Duration _mapWarmCacheTtl = Duration(hours: 6);
  static const double _selectionSheetOffset = 280;
  static const double _mobilePoiTapHitSlopPixels = 44;
  static DateTime? _mapWarmCacheExpiry;
  static LatLng? _cachedCameraTarget;
  static double? _cachedCameraZoom;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  GoogleMapController? _mapController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isMapLoaded = false;
  CameraPosition? _latestCameraPosition;

  bool get _hasWarmMapCache {
    final expiry = _mapWarmCacheExpiry;
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  CameraPosition _buildInitialCameraPosition(AsyncValue<Position?> currentPosition) {
    final cachedTarget = _cachedCameraTarget;
    final cachedZoom = _cachedCameraZoom;
    if (_hasWarmMapCache && cachedTarget != null) {
      return CameraPosition(
        target: cachedTarget,
        zoom: cachedZoom ?? 14.0,
      );
    }

    return CameraPosition(
      target: currentPosition.whenData((pos) {
        if (pos != null) {
          return LatLng(pos.latitude, pos.longitude);
        }
        return const LatLng(37.7749, -122.4194);
      }).value ?? const LatLng(37.7749, -122.4194),
      zoom: 14.0,
    );
  }

  void _refreshMapWarmCacheFromCamera() {
    final camera = _latestCameraPosition;
    if (camera == null) return;

    _cachedCameraTarget = camera.target;
    _cachedCameraZoom = camera.zoom;
    _mapWarmCacheExpiry = DateTime.now().add(_mapWarmCacheTtl);
  }

  @override
  void initState() {
    super.initState();
    _isMapLoaded = _hasWarmMapCache;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _refreshMapWarmCacheFromCamera();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && ref.read(selectedPlaceProvider) != null) {
      ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(maypoleSearchViewModelProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentPosition = ref.watch(currentPositionProvider);
    final hasLocationPermission = ref.watch(hasLocationPermissionProvider);

    return Scaffold(
      backgroundColor: darkPurple,
      appBar: null,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              final shouldUseWarmCache = _hasWarmMapCache;

              if (shouldUseWarmCache) {
                if (mounted && !_isMapLoaded) {
                  setState(() {
                    _isMapLoaded = true;
                  });
                }
                return;
              }

              Position? position;

              final currentPosFromProvider = currentPosition.hasValue ? currentPosition.value : null;

              if (currentPosFromProvider != null) {
                position = currentPosFromProvider;
              } else {
                final locationService = ref.read(locationServiceProvider);
                final permission = await locationService.checkPermission();

                if (permission == LocationPermission.denied) {
                  await locationService.requestPermission();
                }

                position = await locationService.getCurrentPosition();
              }

              if (position != null && mounted) {
                await controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(position.latitude, position.longitude),
                      zoom: 14.0,
                    ),
                  ),
                );
              }

              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                setState(() {
                  _isMapLoaded = true;
                });
              }
            },
            onCameraMove: (position) {
              _latestCameraPosition = position;
            },
            onCameraIdle: () {
              _refreshMapWarmCacheFromCamera();
            },
            initialCameraPosition: _buildInitialCameraPosition(currentPosition),
            style: darkGoogleMapStyle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onTap: _onMapTapped,
            onLongPress: _onMapLongPressed,
            zoomControlsEnabled: false,
          ),

          Column(
            children: [
              if (!AppConfig.isWideScreen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: MediaQuery.of(context).padding.top + (kToolbarHeight / 2),
                  color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                      ? darkPurple.withValues(alpha: 0.9)
                      : Colors.transparent,
                ),
              if (!kIsWeb && !AppConfig.isWideScreen)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                        ? darkPurple.withValues(alpha: 0.9)
                        : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
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
                              ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
                            },
                            child: const Icon(Icons.clear),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

              if (kIsWeb && AdConfig.webAdsEnabled)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    color: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty)
                        ? darkPurple.withValues(alpha: 0.9)
                        : Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black87,
                              ],
                            ),
                          ),
                          child: WebHorizontalBannerAd(
                            adSlot: AdConfig.adsterraLeaderboardSlot,
                            adKey: AdConfig.adsterraLeaderboardKey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
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
                                  ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                  ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
                                },
                                child: const Icon(Icons.clear),
                              )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: AnimatedOpacity(
                  opacity: (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_searchFocusNode.hasFocus && _searchController.text.isEmpty,
                    child: GestureDetector(
                      onTap: () {
                        if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
                        }
                      },
                      child: Container(
                        color: darkPurple.withValues(alpha: 0.9),
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

          if (!_isMapLoaded)
            Container(
              color: darkPurple,
              child: const Center(
                child: CircularProgressIndicator(
                  color: skyBlue,
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: selectedPlace != null ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selectedPlace != null ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: selectedPlace == null,
                  child: selectedPlace != null
                      ? _buildBottomSheet(selectedPlace.placeDetails, selectedPlace.location)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
            Positioned(
              top: MediaQuery.of(context).padding.top + (kToolbarHeight / 2) + 8,
              left: 8,
              child: Material(
                color: darkPurple.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (widget.embedded && widget.onCloseRequested != null) {
                      widget.onCloseRequested!();
                      return;
                    }
                    context.pop();
                  },
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

          Positioned(
            bottom: selectedPlace != null ? _selectionSheetOffset : 24,
            right: 24,
            child: Material(
              color: (hasLocationPermission.value == true)
                  ? skyBlue
                  : Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _handleLocationButtonTap(hasLocationPermission.value == true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
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
            await _fetchPlaceDetailsAndReturn(prediction);
          },
        );
      },
    );
  }

  Future<void> _fetchPlaceDetailsAndReturn(PlacePrediction prediction) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final searchService = ref.read(maypoleSearchServiceProvider);
      final placeDetails = await searchService.getPlaceDetails(prediction.placeId);

      if (!mounted) return;

      Navigator.pop(context);

      if (placeDetails != null) {
        final location = placeDetails['location'] as Map<String, dynamic>?;
        final latitude = location?['latitude'] as double?;
        final longitude = location?['longitude'] as double?;

        String? placeType = placeDetails['primaryType'] as String?;

        if (placeType == null || placeType.isEmpty) {
          final types = placeDetails['types'] as List<dynamic>?;

          if (types != null && types.isNotEmpty) {
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
                break;
              }
            }
          }
        }

        final updatedPrediction = prediction.copyWith(
          latitude: latitude,
          longitude: longitude,
          placeType: placeType,
        );

        if (mounted) {
          if (widget.embedded && widget.onPlaceSelected != null) {
            widget.onPlaceSelected!(updatedPrediction);
          } else {
            context.pop(updatedPrediction);
          }
        }
      } else {
        if (mounted) {
          if (widget.embedded && widget.onPlaceSelected != null) {
            widget.onPlaceSelected!(prediction);
          } else {
            context.pop(prediction);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
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
      _showLocationPermissionDialog();
      return;
    }

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
                  if (permission == LocationPermission.deniedForever) {
                    await locationService.openAppSettings();
                  }
                }
              } else {
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
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        return;
      }

      final target = LatLng(position.latitude, position.longitude);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: target,
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e);
      }
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    debugPrint('MaypoleSearchScreen: _onMapTapped at ${position.latitude}, ${position.longitude}');
    if (_searchFocusNode.hasFocus || _searchController.text.trim().isNotEmpty) {
      debugPrint('MaypoleSearchScreen: Tapped ignored (focus: ${_searchFocusNode.hasFocus}, text: "${_searchController.text}")');
      return;
    }

    final controller = _mapController;
    if (controller == null) {
      debugPrint('MaypoleSearchScreen: Tapped ignored because map controller is not ready.');
      return;
    }

    final details = await _findVisiblePoiAtTap(position, controller);

    debugPrint('MaypoleSearchScreen: visible POI lookup returned: ${details != null ? 'data' : 'null'}');

    if (!mounted) return;

    if (details != null) {
      final location = details['location'] as Map<String, dynamic>?;
      final lat = location?['latitude'] as double? ?? position.latitude;
      final lng = location?['longitude'] as double? ?? position.longitude;

      ref.read(maypoleSearchViewModelProvider.notifier).setSelectedPlace(
            placeDetails: details,
            location: LatLng(lat, lng),
          );
      return;
    }

    debugPrint('MaypoleSearchScreen: No visible POI found at tap. Clearing selected place.');
    ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
  }

  Future<Map<String, dynamic>?> _findVisiblePoiAtTap(
    LatLng tapPosition,
    GoogleMapController controller,
  ) async {
    try {
      final searchService = ref.read(maypoleSearchServiceProvider);
      final candidates = await searchService.searchNearbyPlaces(
        tapPosition.latitude,
        tapPosition.longitude,
        radiusMeters: 75,
        maxResultCount: 10,
      );

      if (candidates.isEmpty) {
        return null;
      }

      final visibleRegion = await controller.getVisibleRegion();
      final tapScreenCoordinate = await controller.getScreenCoordinate(tapPosition);

      Map<String, dynamic>? bestCandidate;
      var bestScreenDistance = double.infinity;

      for (final candidate in candidates) {
        final placeId = candidate['id'] as String?;
        final displayName = candidate['displayName']?['text'] as String?;
        final location = candidate['location'] as Map<String, dynamic>?;
        final placeLat = location?['latitude'] as double?;
        final placeLng = location?['longitude'] as double?;

        if (placeId == null || placeId.isEmpty || displayName == null || displayName.trim().isEmpty) {
          continue;
        }

        if (placeLat == null || placeLng == null) {
          continue;
        }

        final placePosition = LatLng(placeLat, placeLng);
        if (!visibleRegion.contains(placePosition)) {
          continue;
        }

        final placeScreenCoordinate = await controller.getScreenCoordinate(placePosition);
        final screenDistance = math.sqrt(
          math.pow(placeScreenCoordinate.x - tapScreenCoordinate.x, 2) +
              math.pow(placeScreenCoordinate.y - tapScreenCoordinate.y, 2),
        );

        if (screenDistance <= _mobilePoiTapHitSlopPixels && screenDistance < bestScreenDistance) {
          bestCandidate = candidate;
          bestScreenDistance = screenDistance;
        }
      }

      if (bestCandidate != null) {
        debugPrint(
          'MaypoleSearchScreen: Best visible POI: ${bestCandidate['displayName']?['text']} '
          'at ${bestScreenDistance.toStringAsFixed(1)}px from tap',
        );
      }

      return bestCandidate;
    } catch (e) {
      debugPrint('MaypoleSearchScreen: Visible POI lookup failed: $e');
      return null;
    }
  }

  void _onMapLongPressed(LatLng position) {
    if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
      return;
    }

    // Allow users to select generic locations (no specific POI) via long press
    ref.read(maypoleSearchViewModelProvider.notifier).setSelectedPlace(
          placeDetails: {
            'isGeneric': true,
            'displayName': {'text': 'Selected Location'},
          },
          location: position,
        );
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

    String? placeType;
    if (!isGeneric) {
      placeType = placeDetails['primaryType'] as String?;

      if (placeType == null || placeType.isEmpty) {
        final types = placeDetails['types'] as List<dynamic>?;
        if (types != null && types.isNotEmpty) {
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
              break;
            }
          }
        }
      }
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
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
    final prediction = PlacePrediction(
      place: placeName,
      placeId: placeId,
      placeName: placeName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeType: placeType,
    );

    if (widget.embedded && widget.onPlaceSelected != null) {
      widget.onPlaceSelected!(prediction);
      return;
    }

    context.pop(prediction);
  }
}
