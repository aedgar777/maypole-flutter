import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/features/identity/auth_providers.dart';

class EmailVerifiedScreen extends ConsumerStatefulWidget {
  final String? returnTo;

  const EmailVerifiedScreen({super.key, this.returnTo});

  @override
  ConsumerState<EmailVerifiedScreen> createState() =>
      _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends ConsumerState<EmailVerifiedScreen> {
  bool _isChecking = true;
  bool _verificationSuccess = false;

  String get _postAuthRoute {
    final returnTo = widget.returnTo;
    if (returnTo == null || returnTo.isEmpty) {
      return '/home';
    }

    final uri = Uri.tryParse(returnTo);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      return '/home';
    }

    return returnTo.startsWith('/') ? returnTo : '/$returnTo';
  }

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      // Check and update the verification status
      await ref.read(authServiceProvider).checkEmailVerificationStatus();

      if (mounted) {
        setState(() {
          _verificationSuccess = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificationSuccess = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifying your email...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Logo
            Image.asset(
              'assets/icons/ic_logo_main.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 32),
            // Success/Info Icon
            Icon(
              _verificationSuccess
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              size: 80,
              color: _verificationSuccess ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _verificationSuccess ? 'Email Verified!' : 'Email Verification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _verificationSuccess
                    ? 'Your email has been successfully verified. You can now access all features of Maypole.'
                    : 'If you clicked the verification link, your email should be verified. Please sign in again to see the updated status.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            // Action Button
            ElevatedButton(
              onPressed: () => context.go(
                _verificationSuccess
                    ? _postAuthRoute
                    : Uri(
                        path: '/login',
                        queryParameters: widget.returnTo == null
                            ? null
                            : {'returnTo': widget.returnTo},
                      ).toString(),
              ),
              child: Text(
                _verificationSuccess ? 'Continue' : 'Sign In',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
