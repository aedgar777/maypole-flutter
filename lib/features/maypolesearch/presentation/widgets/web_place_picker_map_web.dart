import 'dart:html' as html;
import 'dart:js_util' as js_util;
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
  final WebMapControllerReady? onControllerReady;

  const WebPlacePickerMap({
    super.key,
    required this.initialCameraPosition,
    required this.onPlaceSelected,
    this.mapStyle,
    this.onCameraMove,
    this.onMapLoaded,
    this.onControllerReady,
  });

  @override
  State<WebPlacePickerMap> createState() => _WebPlacePickerMapState();
}

class _WebPlacePickerMapState extends State<WebPlacePickerMap> {
  late final String _viewType;
  html.DivElement? _mapDiv;
  dynamic _map;

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

    final google = js_util.getProperty<dynamic>(html.window, 'google');
    final maps = google != null ? js_util.getProperty<dynamic>(google, 'maps') : null;
    if (maps == null) {
      debugPrint('❌ Google Maps JS API not available on window.google.maps');
      return;
    }

    final mapCtor = js_util.getProperty<dynamic>(maps, 'Map');
    final latLngCtor = js_util.getProperty<dynamic>(maps, 'LatLng');
    final markerCtor = js_util.getProperty<dynamic>(maps, 'Marker');
    final event = js_util.getProperty<dynamic>(maps, 'event');
    final addListener = event != null ? js_util.getProperty<dynamic>(event, 'addListener') : null;

    if (mapCtor == null || latLngCtor == null || markerCtor == null || addListener == null) {
      debugPrint('❌ Missing required Google Maps JS constructors');
      return;
    }

    final target = widget.initialCameraPosition.target;
    final center = js_util.callConstructor(latLngCtor, [target.latitude, target.longitude]);

    final mapOptions = js_util.newObject();
    js_util.setProperty(mapOptions, 'center', center);
    js_util.setProperty(mapOptions, 'zoom', widget.initialCameraPosition.zoom);
    js_util.setProperty(mapOptions, 'mapTypeId', 'roadmap');
    js_util.setProperty(mapOptions, 'disableDefaultUI', false);

    _map = js_util.callConstructor(mapCtor, [div, mapOptions]);

    if (widget.mapStyle != null && widget.mapStyle!.isNotEmpty) {
      try {
        final style = js_util.callMethod<dynamic>(js_util.getProperty(html.window, 'JSON'), 'parse', [widget.mapStyle!]);
        final styleOptions = js_util.newObject();
        js_util.setProperty(styleOptions, 'styles', style);
        js_util.callMethod(_map, 'setOptions', [styleOptions]);
      } catch (e) {
        debugPrint('⚠️ Failed to apply web map style: $e');
      }
    }

    final markerOptions = js_util.newObject();
    js_util.setProperty(markerOptions, 'map', _map);
    js_util.setProperty(markerOptions, 'visible', false);
    final marker = js_util.callConstructor(markerCtor, [markerOptions]);

    js_util.callMethod(event, 'addListener', [
      _map,
      'click',
      js_util.allowInterop((dynamic e) {
        final placeId = js_util.getProperty<dynamic>(e, 'placeId');
        final latLng = js_util.getProperty<dynamic>(e, 'latLng');
        if (latLng == null) {
          return;
        }

        final lat = js_util.callMethod<num?>(latLng, 'lat', []);
        final lng = js_util.callMethod<num?>(latLng, 'lng', []);
        if (lat == null || lng == null) return;

        if (placeId != null) {
          js_util.callMethod(e, 'stop', []);
          js_util.callMethod(marker, 'setVisible', [true]);
          js_util.callMethod(marker, 'setPosition', [latLng]);

          widget.onPlaceSelected({
            'placeId': placeId.toString(),
            'latitude': lat.toDouble(),
            'longitude': lng.toDouble(),
          });
        }
      }),
    ]);

    js_util.callMethod(event, 'addListener', [
      _map,
      'idle',
      js_util.allowInterop(() {
        final centerNow = js_util.callMethod<dynamic>(_map, 'getCenter', []);
        final zoomNow = js_util.callMethod<num?>(_map, 'getZoom', []);
        final lat = centerNow != null ? js_util.callMethod<num?>(centerNow, 'lat', []) : null;
        final lng = centerNow != null ? js_util.callMethod<num?>(centerNow, 'lng', []) : null;
        if (lat != null && lng != null && zoomNow != null) {
          widget.onCameraMove?.call(
            CameraPosition(
              target: LatLng(lat.toDouble(), lng.toDouble()),
              zoom: zoomNow.toDouble(),
            ),
          );
        }
        widget.onMapLoaded?.call();
      }),
    ]);

    widget.onControllerReady?.call(
      (LatLng target, double zoom) async {
        final nextCenter = js_util.callConstructor(latLngCtor, [target.latitude, target.longitude]);
        js_util.callMethod(_map, 'setCenter', [nextCenter]);
        js_util.callMethod(_map, 'setZoom', [zoom]);
      },
      () async {
        js_util.callMethod(marker, 'setVisible', [false]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
