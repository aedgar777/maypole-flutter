import 'package:flutter/material.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';


class DMThreadList extends StatelessWidget {
  final List<DMThreadMetaData> threads;

  const DMThreadList({super.key, required this.threads});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return ListTile(
          title: Text(thread.partnerName),
          subtitle: Text(
            DateTimeUtils.formatThreadTimestamp(thread.lastMessageTime),
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}
