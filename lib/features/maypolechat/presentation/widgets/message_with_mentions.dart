import 'package:flutter/material.dart';
import 'package:maypole/core/app_theme.dart';

/// A widget that displays a message with @ mentions highlighted
class MessageWithMentions extends StatelessWidget {
  final String sender;
  final String body;
  final DateTime timestamp;

  const MessageWithMentions({
    super.key,
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  /// Calculate opacity based on message age
  /// - 0-1 hour: 100% opacity (alpha = 1.0)
  /// - 1-3 hours: 75% opacity (alpha = 0.75)
  /// - 3-6 hours: 50% opacity (alpha = 0.5)
  /// - 6+ hours: 25% opacity (alpha = 0.25)
  double _calculateOpacity() {
    final age = DateTime.now().difference(timestamp);
    final hoursOld = age.inMinutes / 60.0;

    if (hoursOld < 1) {
      return 1.0;
    } else if (hoursOld < 3) {
      return 0.75;
    } else if (hoursOld < 6) {
      return 0.5;
    } else {
      return 0.25;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentions = _parseMentions(body);
    final theme = Theme.of(context);
    final opacity = _calculateOpacity();

    return Opacity(
      opacity: opacity,
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$sender: ',
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                color: violet,
              ),
            ),
            ...mentions,
          ],
        ),
      ),
    );
  }

  /// Parse the message body and create TextSpans with highlighted mentions
  List<TextSpan> _parseMentions(String text) {
    final List<TextSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    int lastMatchEnd = 0;

    for (final match in mentionRegex.allMatches(text)) {
      // Add text before the mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }

      // Add the mention with highlighting
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: Colors.blue[700],
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.blue[50],
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last mention
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return spans;
  }
}
