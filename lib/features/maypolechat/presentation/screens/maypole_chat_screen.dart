import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/widgets/adaptive_scaffold.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/features/home/presentation/widgets/maypole_list_panel.dart';
import 'package:maypole/features/maypolesearch/data/models/autocomplete_response.dart';
import '../widgets/maypole_chat_content.dart';

/// Maypole chat screen that adapts based on authentication state.
/// - Anonymous users: View-only mode with "Join conversation" prompt
/// - Authenticated users: Full interactivity (post, tag, delete, report)
/// 
/// This screen works for both deeplinks (public sharing) and authenticated navigation.
class MaypoleChatScreen extends ConsumerWidget {
  final String threadId;
  final String maypoleName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeType;

  const MaypoleChatScreen({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.address,
    this.latitude,
    this.longitude,
    this.placeType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authStateProvider).when(
      data: (user) {
        final isAuthenticated = user != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 600;

            // Authenticated users on wide screens see the normal layout
            if (isAuthenticated && isWideScreen) {
              return Scaffold(
                body: AdaptiveScaffold(
                  navigationPanel: MaypoleListPanel(
                    user: user,
                    selectedThreadId: threadId,
                    isMaypoleThread: true,
                    onSettingsPressed: () => context.push('/settings'),
                    onAddPressed: () => _handleAddPressed(context),
                    onMaypoleThreadSelected: (id, name, addr, lat, lon) {
                      // Navigate to the regular chat screen (not preview)
                      context.go('/chat/$id', extra: {
                        'name': name,
                        'address': addr,
                        'latitude': lat,
                        'longitude': lon,
                      });
                    },
                    onDmThreadSelected: (id) {
                      context.go('/dm/$id');
                    },
                    onTabChanged: (_) {},
                  ),
                  contentPanel: MaypoleChatContent(
                    threadId: threadId,
                    maypoleName: maypoleName,
                    address: address,
                    latitude: latitude,
                    longitude: longitude,
                    placeType: placeType,
                    showAppBar: false,
                    autoFocus: true,
                    readOnly: false, // Authenticated users can interact
                  ),
                ),
              );
            }

            // All other cases: show chat content
            // Anonymous users see read-only version with join prompt
            return MaypoleChatContent(
              threadId: threadId,
              maypoleName: maypoleName,
              address: address,
              latitude: latitude,
              longitude: longitude,
              placeType: placeType,
              showAppBar: true,
              readOnly: !isAuthenticated, // Read-only for anonymous users
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error loading chat: $err'),
        ),
      ),
    );
  }

  Future<void> _handleAddPressed(BuildContext context) async {
    final Object? result = await context.push('/search');
    if (result != null && result is PlacePrediction && context.mounted) {
      final prediction = result as PlacePrediction;
      context.go('/chat/${prediction.placeId}', extra: {
        'name': prediction.placeName,
        'address': prediction.address,
        'latitude': prediction.latitude,
        'longitude': prediction.longitude,
        'placeType': prediction.placeType,
      });
    }
  }
}
