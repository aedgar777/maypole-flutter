import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A hover-aware list tile that shows a 3-dot menu button on the right when hovered.
/// Only shows the 3-dot menu on web/wide screen.
class HoverListTile extends StatefulWidget {
  final Widget leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Function(BuildContext triggerContext) onMenuTap;
  final Color? tileColor;

  const HoverListTile({
    super.key,
    required this.leading,
    this.title,
    this.subtitle,
    this.onTap,
    required this.onMenuTap,
    this.tileColor,
  });

  @override
  State<HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<HoverListTile> {
  bool _isHovered = false;

  bool get _showWebMenuButton => kIsWeb;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (triggerContext) {
        final tile = ListTile(
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          tileColor: widget.tileColor,
          onTap: widget.onTap,
          onLongPress: _showWebMenuButton
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onMenuTap(triggerContext);
                },
          trailing: _showWebMenuButton
              ? AnimatedOpacity(
                  opacity: _isHovered ? 0.6 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTap: () => widget.onMenuTap(triggerContext),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
              : null,
        );

        if (!_showWebMenuButton) {
          return tile;
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: tile,
        );
      },
    );
  }
}

/// Simple hover menu button (kept for backwards compatibility)
class HoverMenuButton extends StatelessWidget {
  final bool isHovered;
  final VoidCallback onTap;

  const HoverMenuButton({
    super.key,
    required this.isHovered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isHovered ? 0.6 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
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
