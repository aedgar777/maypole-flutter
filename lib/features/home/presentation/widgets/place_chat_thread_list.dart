import 'package:flutter/material.dart';
import 'package:maypole/features/placechat/domain/place_chat_thread.dart';

class PlaceChatThreadList extends StatelessWidget {
  final List<PlaceChatThreadMetaData> threads;

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

