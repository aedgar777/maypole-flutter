import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A hover-aware list tile that shows a 3-dot menu button on the right when hovered.
/// Only shows the 3-dot menu on web/wide screen.
class HoverListTile extends StatefulWidget {
  final Widget leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final VoidCallback onMenuTap;
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

  bool get _isWideScreen {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 || kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: widget.leading,
      title: widget.title,
      subtitle: widget.subtitle,
      tileColor: widget.tileColor,
      onTap: widget.onTap,
      trailing: _isWideScreen
          ? AnimatedOpacity(
              opacity: _isHovered ? 0.6 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: widget.onMenuTap,
                child: Container(
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
            )
          : null,
    );

    if (!_isWideScreen) {
      return tile;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: tile,
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
