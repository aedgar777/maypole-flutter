import 'package:flutter/widgets.dart';

/// Computes the `sharePositionOrigin` rectangle required by `share_plus` on
/// iPad, where the native share sheet is presented as a popover that must be
/// anchored to a source rectangle. Returning a sensible rect (rather than null)
/// avoids the `PlatformException` iPadOS throws when no origin is supplied.
///
/// Pass the [BuildContext] of the widget that triggered the share (ideally the
/// share button). Falls back to the screen centre when the render object is not
/// yet laid out.
Rect shareOriginFromContext(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  final size = MediaQuery.of(context).size;
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 0,
    height: 0,
  );
}
