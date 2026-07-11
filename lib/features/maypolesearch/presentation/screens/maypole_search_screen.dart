import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/services.dart';
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
import '../widgets/web_place_picker_map.dart';

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
  static DateTime? _mapWarmCacheExpiry;
  static LatLng? _cachedCameraTarget;
  static double? _cachedCameraZoom;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  GoogleMapController? _mapController;
  MethodChannel? _poiTapChannel;
  bool _isMapLoaded = false;
  CameraPosition? _latestCameraPosition;

  // Web-only map controls, populated by [WebPlacePickerMap] once its underlying
  // JS Google Map is ready. On web we render our own map (instead of the
  // google_maps_flutter_web GoogleMap) so POI taps surface their placeId and
  // suppress Google's default info window, matching native behavior.
  Future<void> Function(LatLng target, double zoom)? _webAnimateCamera;
  Future<void> Function()? _webClearSelection;

  // Whether the web map has already auto-centered on the user's location. Mobile
  // does this in onMapCreated; on web the JS map only honors initialCameraPosition
  // at construction, so we animate to the user's location once it resolves.
  bool _webDidInitialCenter = false;

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
    _poiTapChannel?.setMethodCallHandler(null);
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && ref.read(selectedPlaceProvider) != null) {
      ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
    }

    if (!_searchFocusNode.hasFocus && _searchController.text.trim().isEmpty) {
      ref.read(maypoleSearchViewModelProvider.notifier).searchMaypoles('');
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

    // When the selection is cleared (e.g. user taps "Chat here" or dismisses
    // the sheet), hide the web map's selection marker so it matches mobile.
    ref.listen(selectedPlaceProvider, (previous, next) {
      if (kIsWeb && next == null) {
        _webClearSelection?.call();
      }
    });

    // On web, recenter the map on the user's location once it resolves (matching
    // mobile, which centers in onMapCreated). No-ops if permission is denied
    // (position stays null) or the user already has a warm/cached camera.
    ref.listen(currentPositionProvider, (previous, next) {
      _maybeAutoCenterWebOnUser(next);
    });

    return Scaffold(
      backgroundColor: darkPurple,
      appBar: null,
      body: Stack(
        children: [
          _buildMap(currentPosition),

          Column(
            children: [
              if (!AppConfig.isWideScreen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: MediaQuery.of(context).padding.top +
                      ((!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                          ? kToolbarHeight
                          : kToolbarHeight / 2),
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

          // Painted before the bottom sheet so that, when a place is selected,
          // the sheet slides up and covers (hides) the button rather than the
          // button rising with it. Its position stays fixed on all platforms.
          Positioned(
            // On web the map renders Google's native controls (the round "camera
            // controls" button and, below it, the Street View "pegman"). Size and
            // place our location button to match: same 40x40 footprint as the
            // pegman, positioned directly to its left with the same gap (32px)
            // that separates the pegman from the camera-controls button above it.
            // The pegman sits 10px from the right edge, so our button's right
            // offset is 10 + 40 (pegman) + 32 (gap) = 82.
            bottom: 24,
            right: kIsWeb ? 82 : 24,
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
                  // Match the native 40x40 pegman: 24 icon + 8 padding each side
                  // on web; keep the larger touch target on mobile.
                  padding: EdgeInsets.all(kIsWeb ? 8 : 12),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
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
              top: MediaQuery.of(context).padding.top + 8,
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

        ],
      ),
    );
  }

  Widget _buildMap(AsyncValue<Position?> currentPosition) {
    if (kIsWeb) {
      // The google_maps_flutter_web GoogleMap surfaces only a LatLng on tap and
      // shows Google's default POI info window. We instead render our own JS map
      // so POI taps carry a placeId and the default info window is suppressed,
      // letting us show the same bottom sheet as mobile.
      final userPosition = currentPosition.value;
      final userLocation = userPosition != null
          ? LatLng(userPosition.latitude, userPosition.longitude)
          : null;

      return WebPlacePickerMap(
        initialCameraPosition: _buildInitialCameraPosition(currentPosition),
        mapStyle: darkGoogleMapStyle,
        myLocation: userLocation,
        onPlaceSelected: _handleWebPlaceSelected,
        onMapTapped: () {
          if (_searchFocusNode.hasFocus ||
              _searchController.text.trim().isNotEmpty) {
            return;
          }
          ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
        },
        onCameraMove: (position) {
          _latestCameraPosition = position;
        },
        onMapLoaded: () {
          _refreshMapWarmCacheFromCamera();
          if (mounted && !_isMapLoaded) {
            setState(() {
              _isMapLoaded = true;
            });
          }
        },
        onControllerReady: (animateCamera, clearSelection) {
          _webAnimateCamera = animateCamera;
          _webClearSelection = clearSelection;
          // If the user's location already resolved before the map was ready,
          // center on it now (mobile parity).
          _maybeAutoCenterWebOnUser(ref.read(currentPositionProvider));
        },
      );
    }

    return GoogleMap(
      onMapCreated: (controller) async {
        _mapController = controller;
        _connectNativePoiTapChannel(controller);
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

        final currentPosFromProvider =
            currentPosition.hasValue ? currentPosition.value : null;

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

  /// Centers the web map on the user's location the first time it resolves,
  /// mirroring mobile's behavior in onMapCreated. No-ops on mobile, when the
  /// map controller isn't ready yet, when permission is denied (position is
  /// null), when a warm camera cache should be respected, or once it has
  /// already run.
  void _maybeAutoCenterWebOnUser(AsyncValue<Position?> currentPosition) {
    if (!kIsWeb || _webDidInitialCenter || _hasWarmMapCache) return;
    final animateCamera = _webAnimateCamera;
    if (animateCamera == null) return;

    final position = currentPosition.value;
    if (position == null) return;

    _webDidInitialCenter = true;
    animateCamera(LatLng(position.latitude, position.longitude), 14.0);
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        return;
      }

      final target = LatLng(position.latitude, position.longitude);

      if (kIsWeb) {
        await _webAnimateCamera?.call(target, 16.0);
      } else if (_mapController != null) {
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

  void _onMapTapped(LatLng position) {
    debugPrint('MaypoleSearchScreen: _onMapTapped at ${position.latitude}, ${position.longitude}');
    if (_searchFocusNode.hasFocus || _searchController.text.trim().isNotEmpty) {
      debugPrint('MaypoleSearchScreen: Tapped ignored (focus: ${_searchFocusNode.hasFocus}, text: "${_searchController.text}")');
      return;
    }

    // Plain map taps are not POI taps. On Android, real Google-rendered POI
    // taps arrive through the native OnPoiClickListener bridge below.
    ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace();
  }

  void _connectNativePoiTapChannel(GoogleMapController controller) {
    _poiTapChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('app.maypole/google_maps_poi_${controller.mapId}');
    channel.setMethodCallHandler((call) async {
      if (call.method != 'poi#onTap' || !mounted) return;
      final arguments = (call.arguments as Map<Object?, Object?>).cast<String, Object?>();
      await _handleNativePoiTap(arguments);
    });
    _poiTapChannel = channel;
  }

  Future<void> _handleNativePoiTap(Map<String, Object?> poi) async {
    final placeId = poi['placeId'] as String?;
    final name = poi['name'] as String?;
    final location = (poi['location'] as Map<Object?, Object?>?)?.cast<String, Object?>();
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    debugPrint('MaypoleSearchScreen: native POI tap placeId=$placeId name=$name lat=$lat lng=$lng');
    if (placeId == null || placeId.isEmpty || lat == null || lng == null) {
      return;
    }

    await _selectPoi(placeId: placeId, name: name, lat: lat, lng: lng);
  }

  /// Handles a POI tap coming from the web map ([WebPlacePickerMap]). The web
  /// map already suppressed Google's default info window and gives us the
  /// tapped place's id and coordinates, so we route it through the same
  /// selection flow as native POI taps.
  Future<void> _handleWebPlaceSelected(Map<String, dynamic> data) async {
    final placeId = data['placeId'] as String?;
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    debugPrint('MaypoleSearchScreen: web POI tap placeId=$placeId lat=$lat lng=$lng');
    if (placeId == null || placeId.isEmpty || lat == null || lng == null) {
      return;
    }

    await _selectPoi(placeId: placeId, lat: lat, lng: lng);
  }

  /// Shared POI selection used by both the native POI bridge and the web map.
  /// Selects the place immediately using the data we already have so the bottom
  /// sheet appears instantly, then fetches richer details and merges them in
  /// without blocking the initial selection.
  Future<void> _selectPoi({
    required String placeId,
    String? name,
    required double lat,
    required double lng,
  }) async {
    if (_searchFocusNode.hasFocus || _searchController.text.trim().isNotEmpty) return;

    final immediateName = name?.trim().isNotEmpty == true ? name!.trim() : null;
    final location = LatLng(lat, lng);

    // Show the sheet immediately in a loading state while we fetch details, so
    // the user sees a spinner instead of the "Selected Place" placeholder.
    ref.read(maypoleSearchViewModelProvider.notifier).setSelectedPlace(
          placeDetails: {
            'id': placeId,
            if (immediateName != null) 'displayName': {'text': immediateName},
            'location': {'latitude': lat, 'longitude': lng},
            'isNativePoi': true,
            'isLoading': true,
          },
          location: location,
        );

    Map<String, dynamic>? fetchedDetails;
    Object? fetchError;
    try {
      fetchedDetails =
          await ref.read(maypoleSearchServiceProvider).getPlaceDetails(placeId);
    } catch (e) {
      fetchError = e;
    }

    // Abandon if the user moved on (started searching) or the selection was
    // cleared / replaced by a different place while this fetch was in flight.
    if (!mounted || _searchFocusNode.hasFocus || _searchController.text.trim().isNotEmpty) {
      return;
    }
    final current = ref.read(selectedPlaceProvider);
    if (current == null || current.placeDetails['id'] != placeId) return;

    if (fetchedDetails == null) {
      // Surface the failure in the bottom sheet instead of leaving it stuck on
      // the loading/placeholder state.
      ref.read(maypoleSearchViewModelProvider.notifier).setSelectedPlace(
            placeDetails: {
              'id': placeId,
              if (immediateName != null) 'displayName': {'text': immediateName},
              'location': {'latitude': lat, 'longitude': lng},
              'isNativePoi': true,
              'isLoading': false,
              'error': _placeDetailsErrorMessage(fetchError),
            },
            location: location,
          );
      return;
    }

    final placeDetails = {
      'id': placeId,
      if (immediateName != null) 'displayName': {'text': immediateName},
      'location': {'latitude': lat, 'longitude': lng},
      ...fetchedDetails,
      'isNativePoi': true,
      'isLoading': false,
    };
    final detailsLocation = (placeDetails['location'] as Map?)?.cast<String, Object?>();
    final selectedLat = (detailsLocation?['latitude'] as num?)?.toDouble() ?? lat;
    final selectedLng = (detailsLocation?['longitude'] as num?)?.toDouble() ?? lng;

    ref.read(maypoleSearchViewModelProvider.notifier).setSelectedPlace(
          placeDetails: placeDetails,
          location: LatLng(selectedLat, selectedLng),
        );
  }

  /// Builds a user-friendly message for a failed Place Details lookup. The
  /// service swallows network/HTTP failures and returns null, so [error] is
  /// usually null; we still inspect it when present.
  String _placeDetailsErrorMessage(Object? error) {
    final str = error?.toString() ?? '';
    if (str.contains('XMLHttpRequest') ||
        str.contains('SocketException') ||
        str.contains('Failed host lookup') ||
        str.contains('Network')) {
      return 'Network error: please check your connection and try again.';
    }
    return "We couldn't load this place's details. Please try again.";
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
    final isLoading = placeDetails['isLoading'] == true;
    final errorMessage = placeDetails['error'] as String?;

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

    final Widget sheetChild;
    if (isLoading) {
      sheetChild = _buildBottomSheetLoading();
    } else if (errorMessage != null) {
      sheetChild = _buildBottomSheetError(errorMessage);
    } else {
      sheetChild = Column(
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
              final query = isGeneric
                  ? '${position.latitude},${position.longitude}'
                  : [displayName, formattedAddress]
                      .where((part) => part.trim().isNotEmpty)
                      .join(', ');
              final queryParameters = {
                'api': '1',
                'query': query,
                if (!isGeneric && placeId.isNotEmpty) 'query_place_id': placeId,
              };
              final url = Uri.https(
                'www.google.com',
                '/maps/search/',
                queryParameters,
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
      );
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
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: sheetChild,
        ),
      ),
    );
  }

  /// Loading state shown in the bottom sheet while Place Details is being
  /// fetched, so the user sees a spinner rather than the "Selected Place"
  /// placeholder flashing in.
  Widget _buildBottomSheetLoading() {
    return Row(
      key: const ValueKey('sheet-loading'),
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Loading place details…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  /// Error state shown in the bottom sheet when Place Details could not be
  /// retrieved, with a dismiss action to clear the selection.
  Widget _buildBottomSheetError(String message) {
    return Column(
      key: const ValueKey('sheet-error'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                ref.read(maypoleSearchViewModelProvider.notifier).clearSelectedPlace(),
            child: const Text('Dismiss'),
          ),
        ),
      ],
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
