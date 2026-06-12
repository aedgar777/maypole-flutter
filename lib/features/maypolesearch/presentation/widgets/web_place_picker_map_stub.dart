import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef WebMapControllerReady = void Function(
  Future<void> Function(LatLng target, double zoom) animateCamera,
  Future<void> Function() clearSelection,
);

class WebPlacePickerMap extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final String? mapStyle;
  final ValueChanged<Map<String, dynamic>> onPlaceSelected;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onMapLoaded;
  final VoidCallback? onMapTapped;
  final WebMapControllerReady? onControllerReady;
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
