import 'package:flutter/material.dart';

/// A stateful widget that animates a message item sliding in from the bottom
/// with a fade-in effect when it's new.
/// 
/// This widget is used in chat interfaces to provide visual feedback when
/// new messages arrive, creating a smooth slide-up animation with opacity transition.
///
/// Example usage:
/// ```dart
/// AnimatedMessageItem(
///   isNew: isNewMessage,
///   child: ChatBubble(...),
/// )
/// ```
class AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final bool isNew;

  const AnimatedMessageItem({
    super.key,
    required this.child,
    required this.isNew,
  });

  @override
  State<AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: widget.isNew ? 30.0 : 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: widget.isNew ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
