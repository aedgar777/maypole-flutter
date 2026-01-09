import 'package:flutter/material.dart';

/// A scaffold that adapts between mobile and desktop layouts.
///
/// On mobile (narrow screens), shows only the navigation panel or content panel.
/// On desktop (wide screens), shows both panels side-by-side like Discord.
class AdaptiveScaffold extends StatelessWidget {
  /// The navigation panel (typically a list of chats/channels)
  final Widget navigationPanel;

  /// The content panel (typically the selected chat/conversation)
  final Widget? contentPanel;

  /// The breakpoint width at which to switch between mobile and desktop layouts
  final double breakpoint;

  /// The width of the navigation panel on desktop
  final double navigationWidth;

  const AdaptiveScaffold({
    super.key,
    required this.navigationPanel,
    this.contentPanel,
    this.breakpoint = 600,
    this.navigationWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide screen: show side-by-side layout
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            children: [
              // Navigation panel with fixed width
              SizedBox(width: navigationWidth, child: navigationPanel),
              // Vertical divider
              const VerticalDivider(width: 1, thickness: 1),
              // Content panel takes remaining space
              Expanded(child: contentPanel ?? const _EmptyContentPanel()),
            ],
          );
        }

        // Narrow screen: show only navigation panel
        // (content panel is shown in a separate route)
        return navigationPanel;
      },
    );
  }
}

/// Empty state shown when no chat is selected on wide screens
class _EmptyContentPanel extends StatelessWidget {
  const _EmptyContentPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
