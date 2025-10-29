import 'package:flutter/material.dart';
import 'package:maypole_flutter/features/chat/domain/thread_metadata.dart';

class PlaceChatThreadList extends StatelessWidget {
  final List<PlaceChatThreadMetadata> threads;

  const PlaceChatThreadList({super.key, required this.threads});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return ListTile(
          title: Text(thread.name),
          subtitle: Text(thread.lastMessageTime.toString()),
        );
      },
    );
  }
}
