import 'package:flutter/material.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/features/maypolechat/domain/maypole.dart';

class MaypoleList extends StatelessWidget {
  final List<MaypoleMetaData> threads;

  const MaypoleList({super.key, required this.threads});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        final formattedDateTime = DateTimeUtils.formatRelativeDateTime(
          thread.lastMessageTime,
          context: context,
        );

        return ListTile(
          title: Text(thread.name),
          subtitle: Text(formattedDateTime),
        );
      },
    );
  }
}
