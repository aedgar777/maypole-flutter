import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_theme.dart' as app_theme;
import 'package:maypole/l10n/generated/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        leading: AppConfig.isWideScreen ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If there's no navigation stack (e.g., web deep link),
              // navigate to settings
              context.go('/settings');
            }
          },
        ),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Maypole',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime
                  .now()
                  .year}',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              'Introduction',
              'Welcome to Maypole. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
            ),

            _buildSection(
              context,
              'Information We Collect',
              'We collect information that you provide directly to us when you:\n\n'
                  '• Create an account (email address, username, password)\n'
                  '• Upload a profile picture\n'
                  '• Send messages through the app\n'
                  '• Interact with other users\n\n'
                  'We also automatically collect certain information when you use the app:\n\n'
                  '• Device information (device type, operating system)\n'
                  '• Usage data (features accessed, time spent in app)\n'
                  '• Log data (IP address, access times, app crashes)',
            ),

            _buildSection(
              context,
              'Location Information',
              'With your explicit permission, we may collect and use your device\'s location data for the following optional feature:\n\n'
                  '• "Show When at Location": When enabled, this feature allows you to show others that you were physically present at a location when sending messages. Your approximate location coordinates are stored with your messages only when you have this feature enabled and are within 100 meters of a place.\n\n'
                  'Important details about location data:\n\n'
                  '• Location permission is entirely optional - you can use Maypole without it\n'
                  '• We only collect location data when you have explicitly enabled "Show When at Location" in Preferences\n'
                  '• Your exact coordinates are never shared publicly - we only store whether you were within 100 meters of a specific place\n'
                  '• Location data is only used to determine proximity to places and display a location indicator badge\n'
                  '• You can disable this feature at any time in app Preferences\n'
                  '• When disabled, no location data is collected or stored\n'
                  '• Previously stored location data associated with your messages remains until those messages are deleted',
            ),

            _buildSection(
              context,
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Create and manage your account\n'
                  '• Enable you to communicate with other users\n'
                  '• Verify proximity to locations (when "Show When at Location" is enabled)\n'
                  '• Display location indicator badges on messages (when enabled)\n'
                  '• Send you technical notices and support messages\n'
                  '• Respond to your comments and questions\n'
                  '• Monitor and analyze trends, usage, and activities\n'
                  '• Detect, prevent, and address technical issues and security threats',
            ),

            _buildSection(
              context,
              'Third-Party Services',
              'We use the following third-party services:\n\n'
                  '• Firebase Authentication: For user authentication and account management\n'
                  '• Firebase Cloud Firestore: For storing user data and messages\n'
                  '• Firebase Cloud Storage: For storing user-uploaded images\n'
                  '• Google AdMob (planned): For displaying advertisements\n\n'
                  'These services may collect information used to identify you. We recommend reviewing their privacy policies:\n\n'
                  '• Google Privacy Policy: https://policies.google.com/privacy\n'
                  '• Firebase Privacy Policy: https://firebase.google.com/support/privacy',
            ),

            _buildSection(
              context,
              'Data Sharing and Disclosure',
              'We do NOT sell or share your personal information with third parties for their marketing purposes.\n\n'
                  'We may share your information only in the following circumstances:\n\n'
                  '• With your consent or at your direction\n'
                  '• With service providers who perform services on our behalf (e.g., Firebase, Google AdMob)\n'
                  '• To comply with legal obligations or respond to lawful requests\n'
                  '• To protect the rights, property, and safety of Maypole, our users, or others',
            ),

            _buildSection(
              context,
              'Advertising',
              'We plan to integrate Google AdMob to display advertisements in the app. AdMob may collect and use data about your device and app usage to provide personalized ads. You can learn more about how Google uses data at:\n\n'
                  'https://policies.google.com/technologies/partner-sites\n\n'
                  'You may opt out of personalized advertising through your device settings.',
            ),

            _buildSection(
              context,
              'Data Security',
              'We implement appropriate technical and organizational security measures to protect your personal information. However, please note that no method of transmission over the internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your information, we cannot guarantee its absolute security.',
            ),

            _buildSection(
              context,
              'Data Retention',
              'We retain your personal information for as long as necessary to provide you with our services and as described in this Privacy Policy. When you delete your account, we will delete your personal information, except where we are required to retain it for legal compliance or legitimate business purposes.',
            ),

            _buildSection(
              context,
              'Your Rights',
              'Depending on your location, you may have certain rights regarding your personal information, including:\n\n'
                  '• The right to access your personal information\n'
                  '• The right to correct inaccurate information\n'
                  '• The right to delete your account and associated data\n'
                  '• The right to object to or restrict certain processing\n'
                  '• The right to data portability\n\n'
                  'To exercise these rights, please contact us using the information below.',
            ),

            _buildSectionWithLink(
              context,
              'Children\'s Privacy',
              'Our service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us so we can delete such information.\n\n'
                  'For more information about our commitment to child safety, please review our ',
              'Child Safety Standards',
              '/child-safety-standards',
            ),

            _buildSection(
              context,
              'International Data Transfers',
              'Your information may be transferred to and maintained on servers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ. By using Maypole, you consent to the transfer of your information to these locations.',
            ),

            _buildSection(
              context,
              'Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),

            _buildSection(
              context,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us through the Help & Feedback section in the app settings.',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme
                .of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithLink(
    BuildContext context,
    String title,
    String contentBefore,
    String linkText,
    String linkRoute,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
              children: [
                TextSpan(text: contentBefore),
                TextSpan(
                  text: linkText,
                  style: const TextStyle(
                    color: app_theme.skyBlue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      context.push(linkRoute);
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
}
