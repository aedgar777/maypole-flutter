import 'package:flutter/material.dart';

/// Dialog explaining location-based features after system permission is granted
class LocationFeaturesDialog extends StatelessWidget {
  final VoidCallback onEnableAll;
  final VoidCallback onNoThanks;

  const LocationFeaturesDialog({
    super.key,
    required this.onEnableAll,
    required this.onNoThanks,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Location Features'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Now that you\'ve granted location permission, would you like to enable this privacy-respecting feature?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            
            // Combined Location Feature
            _buildFeatureItem(
              context,
              icon: Icons.pin_drop,
              title: 'Show When You\'re at a Location',
              description: 'When enabled, a pin icon appears next to your username on messages sent from within 100m of a place. You\'ll also only be able to post pictures when you\'re actually at the location. This helps ensure authenticity and prevents spam.',
            ),
            
            const SizedBox(height: 20),
            
            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your exact location is never shared. Only whether you\'re near a place is used.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'You can change these settings anytime in Preferences.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onNoThanks,
          child: const Text('No Thanks'),
        ),
        FilledButton(
          onPressed: onEnableAll,
          child: const Text('Enable'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
