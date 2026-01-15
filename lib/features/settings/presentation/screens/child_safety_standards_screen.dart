import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

class ChildSafetyStandardsScreen extends StatelessWidget {
  const ChildSafetyStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Safety Standards'),
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
              'Child Safety Standards for Maypole',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: January 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              'Our Commitment',
              'Maypole is committed to providing a safe environment for all users. We have zero tolerance for child sexual abuse and exploitation (CSAE) content on our platform. We strictly prohibit any content, behavior, or activity that exploits, harms, or endangers children.',
            ),

            _buildSection(
              context,
              'Prohibited Content and Conduct',
              'The following content and behaviors are strictly prohibited on Maypole:\n\n'
                  '• Child Sexual Abuse Material (CSAM): Any visual depiction of sexually explicit conduct involving a minor\n'
                  '• Child exploitation: Content that sexualizes or exploits children in any way\n'
                  '• Grooming behavior: Attempts to establish relationships with minors for the purpose of sexual exploitation\n'
                  '• Solicitation of minors: Any attempt to solicit sexual content or encounters with minors\n'
                  '• Distribution of CSAM: Sharing, distributing, or requesting illegal content involving minors\n'
                  '• Inappropriate contact with minors: Any interaction with minors that is sexual or inappropriate in nature\n'
                  '• Predatory behavior: Using the platform to identify, contact, or groom potential victims',
            ),

            _buildSection(
              context,
              'Age Requirements',
              'Maypole is not intended for children under the age of 13. Users must be at least 13 years old to create an account and use our services. We do not knowingly collect personal information from children under 13. If we become aware that a user is under 13, we will immediately terminate their account and delete their data.',
            ),

            _buildSection(
              context,
              'How to Report Child Safety Concerns',
              'If you encounter any content or behavior that violates our child safety standards, please report it immediately. We provide multiple ways to report concerns:\n\n'
                  '• In-app reporting: Use the "Report" option available on messages and user profiles\n'
                  '• Email: Contact us at info@maypole.app with subject line "Child Safety Concern"\n'
                  '• Help & Feedback: Use the feedback form in app settings for urgent safety concerns\n\n'
                  'When reporting, please provide:\n'
                  '• Description of the concerning content or behavior\n'
                  '• Username or profile information of the involved parties\n'
                  '• Screenshots or evidence (if safe to capture)\n'
                  '• Date and time of the incident\n\n'
                  'All reports are treated with the highest priority and investigated immediately.',
            ),

            _buildSection(
              context,
              'Our Response to Violations',
              'When we become aware of potential CSAE content or behavior, we take immediate action:\n\n'
                  '1. Immediate Review: All reports are reviewed within 24 hours, with suspected CSAM cases prioritized for immediate review\n\n'
                  '2. Content Removal: Violating content is removed immediately upon confirmation\n\n'
                  '3. Account Action: Users who violate our child safety standards face immediate and permanent account termination\n\n'
                  '4. Evidence Preservation: We preserve evidence of violations for law enforcement and reporting purposes\n\n'
                  '5. Authority Reporting: We report all confirmed CSAM and child exploitation cases to:\n'
                  '   • National Center for Missing & Exploited Children (NCMEC) CyberTipline (US)\n'
                  '   • Local and federal law enforcement agencies\n'
                  '   • International authorities as appropriate based on user location\n\n'
                  '6. Platform Ban: Violators are permanently banned and prevented from creating new accounts',
            ),

            _buildSection(
              context,
              'Cooperation with Law Enforcement',
              'Maypole cooperates fully with law enforcement agencies investigating child exploitation cases. We:\n\n'
                  '• Respond promptly to valid legal requests for information\n'
                  '• Provide necessary evidence and documentation to support investigations\n'
                  '• File reports with NCMEC\'s CyberTipline as required by law\n'
                  '• Maintain records of violations for law enforcement use\n'
                  '• Work with international authorities on cross-border cases',
            ),

            _buildSection(
              context,
              'Proactive Safety Measures',
              'Beyond responding to reports, we implement proactive measures to protect children:\n\n'
                  '• Age Verification: We enforce age requirements during account creation\n'
                  '• Content Monitoring: We monitor for patterns of concerning behavior\n'
                  '• User Education: We provide safety resources and reporting instructions throughout the app\n'
                  '• Privacy Controls: Users can block others and control who can contact them\n'
                  '• Regular Updates: We continuously improve our safety systems and policies\n'
                  '• Staff Training: Our team is trained to recognize and respond to child safety concerns',
            ),

            _buildSection(
              context,
              'User Safety Tools',
              'Maypole provides built-in safety tools for all users:\n\n'
                  '• Block Users: Prevent unwanted contact from specific users\n'
                  '• Report Function: Easy-to-use reporting for concerning content or behavior\n'
                  '• Message Deletion: Delete your own messages at any time\n'
                  '• Profile Privacy: Control what information is visible to others\n'
                  '• Account Deletion: Permanently delete your account and data at any time',
            ),

            _buildSection(
              context,
              'Contact for Child Safety Concerns',
              'For urgent child safety matters, contact us immediately:\n\n'
                  '• Email: info@maypole.app (Subject: "Child Safety Concern")\n'
                  '• Response Time: We respond to child safety reports within 24 hours\n\n'
                  'If you believe a child is in immediate danger, please contact:\n'
                  '• Local emergency services (911 in the US)\n'
                  '• National Center for Missing & Exploited Children: 1-800-THE-LOST (1-800-843-5678)\n'
                  '• FBI\'s Internet Crime Complaint Center: www.ic3.gov\n'
                  '• CyberTipline: www.cybertipline.org',
            ),

            _buildSection(
              context,
              'Transparency and Accountability',
              'We believe in transparency about our child safety efforts:\n\n'
                  '• We regularly review and update these standards\n'
                  '• We maintain compliance with applicable laws including COPPA, GDPR-K, and other child protection regulations\n'
                  '• We work with child safety organizations and experts to improve our practices\n'
                  '• We document our processes for handling child safety concerns',
            ),

            _buildSection(
              context,
              'Updates to These Standards',
              'We may update these Child Safety Standards as we enhance our safety measures or as laws and best practices evolve. Any updates will be posted on this page with an updated "Last Updated" date. Material changes will be communicated to users through in-app notifications.',
            ),

            const SizedBox(height: 24),

            Container(
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
                        Icons.warning,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Report Immediately',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you encounter any content or behavior that exploits or endangers children, please report it immediately through the in-app reporting feature or by emailing info@maypole.app. Your report could help protect a child from harm.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
