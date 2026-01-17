import 'package:flutter/material.dart';

/// Dialog to confirm reporting content to Hive.ai for moderation
/// 
/// This dialog explains to users what will happen when they report content
/// and asks for confirmation before submitting to Hive.ai.
class ReportContentDialog extends StatelessWidget {
  final String contentType; // 'message', 'image', etc.
  final VoidCallback onConfirm;

  const ReportContentDialog({
    super.key,
    required this.contentType,
    required this.onConfirm,
  });

  /// Show the report dialog and return true if user confirmed
  static Future<bool> show(
    BuildContext context, {
    required String contentType,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReportContentDialog(
        contentType: contentType,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flag, color: Colors.red),
          SizedBox(width: 8),
          Text('Report Content'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to report this $contentType?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This content will be sent to Hive.ai for moderation review. '
            'Our moderation team will review the report and take appropriate action if needed.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please only report content that violates community guidelines or contains inappropriate material.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Report'),
        ),
      ],
    );
  }
}
