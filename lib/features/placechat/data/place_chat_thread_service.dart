import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maypole/features/placechat/domain/place_chat_message.dart';
import 'package:maypole/features/placechat/domain/place_chat_thread.dart';

class PlaceChatThreadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  Future<PlaceChatThread?> getPlaceChatThreadById(String threadId) async {
    final placeChatThreadDoc =
        await _firestore.collection('PlaceChatThreads').doc(threadId).get();
    if (placeChatThreadDoc.exists) {
      return PlaceChatThread.fromMap(placeChatThreadDoc.data()!);
    }
    return null;
  }

  Stream<List<PlaceChatMessage>> getMessages(String threadId) {
    return _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlaceChatMessage.fromMap(doc.data()))
            .toList());
  }

  Future<List<PlaceChatMessage>> getMoreMessages(String threadId, PlaceChatMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => PlaceChatMessage.fromMap(doc.data())).toList();
  }

  Future<void> sendMessage(
      String threadId, String body, String sender) async {
    final message = PlaceChatMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      taggedUser: '', // TODO This needs to be implemented based on your app's user tagging logic
    );
    await _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }
}
