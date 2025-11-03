import 'package:flutter/material.dart';
import '../../domain/thread_metadata.dart';

class DMThreadList extends StatelessWidget {
  final List<DMThreadMetadata> threads;

  const DMThreadList({super.key, required this.threads});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return ListTile(
          title: Text(thread.partnerName),
          subtitle: Text(thread.lastMessageTime.toString()),
        );
      },
    );
  }
}
