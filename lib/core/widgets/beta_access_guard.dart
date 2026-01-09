import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/beta_access_provider.dart';

/// Widget that guards access to the beta web app
/// Shows appropriate message if user doesn't have beta access
class BetaAccessGuard extends ConsumerWidget {
  final Widget child;

  const BetaAccessGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requiresBetaAccess = ref.watch(requiresBetaAccessProvider);

    // If not in beta environment, show child directly
    if (!requiresBetaAccess) {
      return child;
    }

    // Watch beta access status
    final betaAccessAsync = ref.watch(betaAccessProvider);

    return betaAccessAsync.when(
      data: (result) {
        if (result.hasAccess) {
          return child;
        } else if (result.requiresAuth) {
          // User needs to log in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          // User doesn't have beta access
          return _BetaAccessDeniedScreen(reason: result.reason);
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error checking beta access',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetaAccessDeniedScreen extends StatelessWidget {
  final String reason;

  const _BetaAccessDeniedScreen({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Beta Access Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This is a beta version of Maypole, available only to enrolled testers.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        'Want to become a beta tester?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Contact us to request beta access and help shape the future of Maypole!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the production web app
                  // Update this URL to your actual production URL
                  context.go('https://maypole-flutter-ce6c3.web.app');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Go to Production App'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text('Sign in with a different account'),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Reason: $reason',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
