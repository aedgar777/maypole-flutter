import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/features/identity/auth_providers.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class EmailVerifiedScreen extends ConsumerStatefulWidget {
  const EmailVerifiedScreen({super.key});

  @override
  ConsumerState<EmailVerifiedScreen> createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends ConsumerState<EmailVerifiedScreen> {
  bool _isChecking = true;
  bool _verificationSuccess = false;

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
    final l10n = AppLocalizations.of(context)!;

    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying your email...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _verificationSuccess 
                    ? Icons.check_circle_outline 
                    : Icons.info_outline,
                size: 100,
                color: _verificationSuccess ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 32),
              Text(
                _verificationSuccess 
                    ? 'Email Verified!' 
                    : 'Email Verification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _verificationSuccess
                    ? 'Your email has been successfully verified. You can now access all features of Maypole.'
                    : 'If you clicked the verification link, your email should be verified. Please sign in again to see the updated status.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
