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
  JSObject? _map;

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

    event.callMethod(
      'addListener'.toJS,
      map,
      'click'.toJS,
      ((JSObject e) {
        final placeId = e.getProperty<JSAny?>('placeId'.toJS);
        final latLng = e.getProperty<JSObject?>('latLng'.toJS);
        if (latLng == null) {
          return;
        }

        final lat = latLng.callMethod<JSNumber?>('lat'.toJS)?.toDartDouble;
        final lng = latLng.callMethod<JSNumber?>('lng'.toJS)?.toDartDouble;
        if (lat == null || lng == null) return;

        if (placeId != null) {
          e.callMethod('stop'.toJS);
          marker.callMethod('setVisible'.toJS, true.toJS);
          marker.callMethod('setPosition'.toJS, latLng);

          widget.onPlaceSelected({
            'placeId': placeId.toString(),
            'latitude': lat,
            'longitude': lng,
          });
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

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
