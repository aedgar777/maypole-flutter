import 'package:flutter/material.dart';

/// A widget that displays a message with @ mentions highlighted
class MessageWithMentions extends StatelessWidget {
  final String sender;
  final String body;

  const MessageWithMentions({
    super.key,
    required this.sender,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final mentions = _parseMentions(body);
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$sender: ',
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          ...mentions,
        ],
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
