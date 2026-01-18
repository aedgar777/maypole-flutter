import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_theme.dart' as app_theme;

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        leading: AppConfig.isWideScreen ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Welcome to Maypole'),
            const SizedBox(height: 8),
            _buildParagraph(
              context,
              'Maypole is a location-based social app that connects you with people in specific places. Join conversations around locations that matter to you.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Maypoles'),
            const SizedBox(height: 8),
            _buildFeature(
              context,
              Icons.place,
              'Location-Based Chats',
              'Maypoles are group chats tied to specific physical locations. Join conversations about places near you or places you care about.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.search,
              'Search for Places',
              'Tap the search icon to find maypoles near you or search for any location in the world. Join existing maypoles or create new ones.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.send,
              'Send Messages',
              'Share text messages and images with others in the maypole. Tag other users by typing @ followed by their username.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Direct Messages'),
            const SizedBox(height: 8),
            _buildFeature(
              context,
              Icons.message,
              'Private Conversations',
              'Send private messages to other Maypole users. Access your DMs from the Direct Messages tab on the home screen.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.person,
              'User Profiles',
              'Tap on any username to view their profile. From there you can send them a direct message or block them if needed.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Profile & Settings'),
            const SizedBox(height: 8),
            _buildFeature(
              context,
              Icons.photo_camera,
              'Profile Picture',
              'Update your profile picture from the Settings screen. Tap the camera icon on your avatar to choose a new photo from your gallery or take a new one.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.notifications,
              'Notifications',
              'Configure notification preferences from Account Settings. Choose to receive notifications for direct messages and when someone tags you in a conversation.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.settings,
              'Preferences',
              'Customize your app experience by adjusting location and other preferences in the Preferences menu.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.location_on,
              'Location Permissions',
              'Enabling location permissions unlocks additional features: upload images to maypoles, see your location pin when you\'re inside a maypole, and find places near you more easily.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.block,
              'Blocking Users',
              'Block users who you don\'t want to interact with. View and manage your blocked users list from Account Settings.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Privacy & Safety'),
            const SizedBox(height: 8),
            _buildSafetyNotice(context),
            const SizedBox(height: 16),
            _buildFeature(
              context,
              Icons.privacy_tip,
              'Your Privacy Matters',
              'Your location data is only used to find nearby maypoles. We never share your personal information with other users without your consent.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.delete_forever,
              'Delete Messages',
              'Long-press on any of your messages to delete them. You can also delete entire conversations from the Direct Messages screen.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.email,
              'Email Verification',
              'Verify your email address to unlock all features and ensure account security. Check your inbox for the verification email.',
            ),
            const SizedBox(height: 12),
            _buildFeature(
              context,
              Icons.shield,
              'Child Safety',
              'Maypole is committed to child safety. We have zero tolerance for content that exploits or endangers children. Learn more in our Child Safety Standards.',
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Tips & Tricks'),
            const SizedBox(height: 8),
            _buildTip(context, 'Use @ to tag other users in your messages'),
            _buildTip(context, 'Long-press messages to view more options'),
            _buildTip(context, 'Search for maypoles by address or location name'),
            _buildTip(context, 'Swipe to delete conversations in Direct Messages'),
            _buildTip(context, 'Check notification settings to stay updated'),
            const SizedBox(height: 32),
            
            _buildContactSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.report,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Report Safety Concerns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
              children: [
                const TextSpan(
                  text: 'If you encounter inappropriate content, harassment, or any behavior that violates our safety standards, please report it immediately using the in-app reporting features. For child safety concerns specifically, please review our ',
                ),
                TextSpan(
                  text: 'Child Safety Standards',
                  style: const TextStyle(
                    color: app_theme.skyBlue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.push('/child-safety-standards');
                    },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Need More Help?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you have questions or need assistance, please use the Feedback option in Settings to contact us.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
