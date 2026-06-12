// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'web_place_picker_map_stub.dart';

class WebPlacePickerMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final String? mapStyle;
  final ValueChanged<Map<String, dynamic>> onPlaceSelected;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onMapLoaded;
  final VoidCallback? onMapTapped;
  final WebMapControllerReady? onControllerReady;

  /// The user's current location. When non-null a blue "my location" dot is
  /// rendered on the map, matching the native `myLocationEnabled` blue dot.
  final LatLng? myLocation;

  const WebPlacePickerMap({
    super.key,
    required this.initialCameraPosition,
    required this.onPlaceSelected,
    this.mapStyle,
    this.onCameraMove,
    this.onMapLoaded,
    this.onMapTapped,
    this.onControllerReady,
    this.myLocation,
  });

  @override
  State<WebPlacePickerMap> createState() => _WebPlacePickerMapState();
}

class _WebPlacePickerMapState extends State<WebPlacePickerMap> {
  late final String _viewType;
  html.DivElement? _mapDiv;
  JSObject? _map;
  JSFunction? _latLngCtor;
  JSObject? _myLocationMarker;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-place-picker-map-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _mapDiv = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeJsMap();
      });

      return _mapDiv!;
    });
  }

  void _initializeJsMap() {
    final div = _mapDiv;
    if (div == null) return;

    final google = (html.window as JSObject).getProperty<JSObject?>('google'.toJS);
    final maps = google?.getProperty<JSObject?>('maps'.toJS);
    if (maps == null) {
      return;
    }

    final mapCtor = maps.getProperty<JSFunction?>('Map'.toJS);
    final latLngCtor = maps.getProperty<JSFunction?>('LatLng'.toJS);
    final markerCtor = maps.getProperty<JSFunction?>('Marker'.toJS);
    final eventObject = maps.getProperty<JSObject?>('event'.toJS);
    final addListener = eventObject?.getProperty<JSFunction?>('addListener'.toJS);

    if (mapCtor == null ||
        latLngCtor == null ||
        markerCtor == null ||
        eventObject == null ||
        addListener == null) {
      return;
    }
    final event = eventObject;
    _latLngCtor = latLngCtor;

    final target = widget.initialCameraPosition.target;
    final center = latLngCtor.callAsConstructor<JSObject>(
      target.latitude.toJS,
      target.longitude.toJS,
    );

    final mapOptions = <String, Object?>{
      'center': center,
      'zoom': widget.initialCameraPosition.zoom,
      'mapTypeId': 'roadmap',
      'disableDefaultUI': false,
    }.jsify() as JSObject;

    _map = mapCtor.callAsConstructor<JSObject>(div as JSObject, mapOptions);
    final map = _map!;

    // Expose the underlying JS map instance so web integration tests can drive
    // real POI tap events through the click listener wired below. Harmless in
    // production (the map already lives in the page DOM).
    (html.window as JSObject).setProperty('maypoleWebMap'.toJS, map);

    if (widget.mapStyle != null && widget.mapStyle!.isNotEmpty) {
      try {
        final json = (html.window as JSObject).getProperty<JSObject>('JSON'.toJS);
        final style = json.callMethod<JSAny>('parse'.toJS, widget.mapStyle!.toJS);
        final styleOptions = <String, Object?>{'styles': style}.jsify() as JSObject;
        map.callMethod('setOptions'.toJS, styleOptions);
      } on Exception {
        // ignore: map style JSON parse failures silently
      }
    }

    final markerOptions = <String, Object?>{
      'map': map,
      'visible': false,
    }.jsify() as JSObject;
    final marker = markerCtor.callAsConstructor<JSObject>(markerOptions);

    // Blue "my location" dot, mirroring the native `myLocationEnabled` indicator.
    final myLocationIcon = <String, Object?>{
      'path': 0, // google.maps.SymbolPath.CIRCLE
      'scale': 7,
      'fillColor': '#4285F4',
      'fillOpacity': 1,
      'strokeColor': '#FFFFFF',
      'strokeWeight': 2,
    }.jsify() as JSObject;
    final myLocationMarkerOptions = <String, Object?>{
      'map': map,
      'visible': false,
      'clickable': false,
      'zIndex': 1000,
      'icon': myLocationIcon,
    }.jsify() as JSObject;
    _myLocationMarker =
        markerCtor.callAsConstructor<JSObject>(myLocationMarkerOptions);
    _updateMyLocation();

    event.callMethod(
      'addListener'.toJS,
      map,
      'click'.toJS,
      ((JSObject e) {
        final placeId = _extractPlaceId(e.getProperty<JSAny?>('placeId'.toJS));
        final latLng = e.getProperty<JSObject?>('latLng'.toJS);
        if (latLng == null) {
          return;
        }

        final lat = latLng.callMethod<JSNumber?>('lat'.toJS)?.toDartDouble;
        final lng = latLng.callMethod<JSNumber?>('lng'.toJS)?.toDartDouble;
        if (lat == null || lng == null) return;

        if (placeId != null) {
          // Suppress Google's default POI info window so we can show our own
          // bottom sheet, matching the native (Android/iOS) behavior.
          e.callMethod('stop'.toJS);
          marker.callMethod('setVisible'.toJS, true.toJS);
          marker.callMethod('setPosition'.toJS, latLng);

          widget.onPlaceSelected({
            'placeId': placeId,
            'latitude': lat,
            'longitude': lng,
          });
        } else {
          // Plain map tap (no POI). Mirror mobile by clearing any selection.
          widget.onMapTapped?.call();
        }
      }).toJS,
    );

    event.callMethod(
      'addListener'.toJS,
      map,
      'idle'.toJS,
      (() {
        final centerNow = map.callMethod<JSObject?>('getCenter'.toJS);
        final zoomNow = map.callMethod<JSNumber?>('getZoom'.toJS)?.toDartDouble;
        final lat = centerNow?.callMethod<JSNumber?>('lat'.toJS)?.toDartDouble;
        final lng = centerNow?.callMethod<JSNumber?>('lng'.toJS)?.toDartDouble;
        if (lat != null && lng != null && zoomNow != null) {
          widget.onCameraMove?.call(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: zoomNow,
            ),
          );
        }
        widget.onMapLoaded?.call();
      }).toJS,
    );

    widget.onControllerReady?.call(
      (LatLng target, double zoom) async {
        final nextCenter = latLngCtor.callAsConstructor<JSObject>(
          target.latitude.toJS,
          target.longitude.toJS,
        );
        map.callMethod('setCenter'.toJS, nextCenter);
        map.callMethod('setZoom'.toJS, zoom.toJS);
      },
      () async {
        marker.callMethod('setVisible'.toJS, false.toJS);
      },
    );
  }

  /// Converts a Google Maps `IconMouseEvent.placeId` (a JS string when the user
  /// tapped a POI, otherwise null/undefined) into a Dart [String].
  ///
  /// The raw value is a JS string, not a Dart String, so calling `toString()`
  /// on the boxed `JSAny` does NOT yield the place id (it produces a mangled
  /// representation). We must unbox it via the JS interop conversion so that
  /// the id we forward is a valid Google Place ID that Place Details can
  /// resolve — otherwise the lookup 404s and the bottom sheet is stuck on the
  /// "Selected Place" placeholder.
  String? _extractPlaceId(JSAny? placeId) {
    if (placeId == null) return null;
    if (placeId.isA<JSString>()) {
      final id = (placeId as JSString).toDart;
      return id.isEmpty ? null : id;
    }
    final dartValue = placeId.dartify();
    final id = dartValue?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  void didUpdateWidget(covariant WebPlacePickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.myLocation != widget.myLocation) {
      _updateMyLocation();
    }
  }

  /// Positions (or hides) the blue "my location" dot. Safe to call before the
  /// JS map is ready; it no-ops until the marker has been created.
  void _updateMyLocation() {
    final marker = _myLocationMarker;
    final latLngCtor = _latLngCtor;
    if (marker == null || latLngCtor == null) return;

    final location = widget.myLocation;
    if (location == null) {
      marker.callMethod('setVisible'.toJS, false.toJS);
      return;
    }

    final position = latLngCtor.callAsConstructor<JSObject>(
      location.latitude.toJS,
      location.longitude.toJS,
    );
    marker.callMethod('setPosition'.toJS, position);
    marker.callMethod('setVisible'.toJS, true.toJS);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
