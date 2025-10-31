import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_session.dart';

import '../../../chat/presentation/viewmodels/place_chat_viewmodel.dart';
import '../providers/chat_providers.dart';

class PlaceChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const PlaceChatScreen({super.key, required this.threadId});

  @override
  _PlaceChatScreenState createState() => _PlaceChatScreenState();
}

class _PlaceChatScreenState extends ConsumerState<PlaceChatScreen> {
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
        ref
            .read(placeChatViewModelProvider(widget.threadId).notifier)
            .loadMoreMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue =
        ref.watch(placeChatViewModelProvider(widget.threadId));
    final currentUser = AppSession().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Place Chat')),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: '${message.sender}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: message.body),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          if (currentUser != null) _buildMessageInput(currentUser.username),
        ],
      ),
    );
  }

  Widget _buildMessageInput(String sender) {
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
                ref
                    .read(placeChatViewModelProvider(widget.threadId).notifier)
                    .sendPlaceMessage(_messageController.text, sender);
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
