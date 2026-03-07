import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that shows a context menu trigger based on platform:
/// - On widescreen/web: Shows a faint 3-dot menu icon on hover
/// - On mobile: Uses long press to show context menu
/// 
/// The [onMenuOpened] callback is called when the user triggers the menu.
/// The [child] widget is the content that will be wrapped.
/// 
/// For messages, set [alignment] to control where the 3-dot appears:
/// - own messages (right-aligned): use Alignment.centerLeft to show 3-dot on left
/// - partner messages (left-aligned): use Alignment.centerRight to show 3-dot on right
class AdaptiveContextMenuTrigger extends StatefulWidget {
  final Widget child;
  final VoidCallback onMenuOpened;
  final Alignment? alignment;

  const AdaptiveContextMenuTrigger({
    super.key,
    required this.child,
    required this.onMenuOpened,
    this.alignment,
  });

  @override
  State<AdaptiveContextMenuTrigger> createState() => _AdaptiveContextMenuTriggerState();
}

class _AdaptiveContextMenuTriggerState extends State<AdaptiveContextMenuTrigger> {
  bool _isHovered = false;

  bool get _isWideScreen {
    // Use a threshold to determine if we're on a wide screen
    // This should match the logic in AppConfig.isWideScreen
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 || kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    // For widescreen: show hover menu trigger
    if (_isWideScreen) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // For right-aligned messages (user/own on right side), show 3-dot on LEFT of bubble (closest to center)
            if (widget.alignment == Alignment.centerRight) ...[
              _buildMenuButton(),
              widget.child,
            ] else if (widget.alignment == Alignment.centerLeft) ...[
              // For left-aligned messages (partner on left side), show 3-dot on RIGHT of bubble (closest to center)
              widget.child,
              _buildMenuButton(),
            ] else ...[
              _buildMenuButton(),
              widget.child,
            ],
          ],
        ),
      );
    }

    // For mobile: use long press
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onMenuOpened();
      },
      child: widget.child,
    );
  }

  Widget _buildMenuButton() {
    return AnimatedOpacity(
      opacity: _isHovered ? 0.6 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: widget.onMenuOpened,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.more_vert,
            size: 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
