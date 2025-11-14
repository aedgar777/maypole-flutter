import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_session.dart';
import '../../domain/dm_thread.dart';
import '../dm_providers.dart';

class DmScreen extends ConsumerStatefulWidget {
  final DMThread thread;

  const DmScreen({super.key, required this.thread});

  @override
  _DmScreenState createState() => _DmScreenState();
}

class _DmScreenState extends ConsumerState<DmScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ref.read(dmViewModelProvider(widget.thread.id).notifier).loadMoreMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(dmViewModelProvider(widget.thread.id));
    final currentUser = AppSession().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.thread.partnerProfpic),
            ),
            const SizedBox(width: 8),
            Text(widget.thread.partnerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final bool isMe = message.sender == currentUser!.username;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(4),
                      child: Text(message.body),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          if (currentUser != null)
            _buildMessageInput(currentUser.username, widget.thread.partnerId),
        ],
      ),
    );
  }

  Widget _buildMessageInput(String sender, String recipient) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Enter a message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                ref.read(dmViewModelProvider(widget.thread.id).notifier)
                    .sendDmMessage(_messageController.text, sender, recipient);
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
