import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/message.dart';
import '../../domain/thread.dart';

class ThreadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  Future<Thread?> getPlaceChatThreadById(String threadId) async {
    final placeChatThreadDoc =
        await _firestore.collection('PlaceChatThreads').doc(threadId).get();
    if (placeChatThreadDoc.exists) {
      return Thread.fromMap(placeChatThreadDoc.data()!);
    }
    return null;
  }

  Future<Thread?> getDMThreadById(String threadId) async {
    final dmThreadDoc =
        await _firestore.collection('DMThreads').doc(threadId).get();
    if (dmThreadDoc.exists) {
      return Thread.fromMap(dmThreadDoc.data()!);
    }
    return null;
  }

  Stream<List<Message>> getMessages(String threadId) {
    return _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data()))
            .toList());
  }

  Future<List<Message>> getMoreMessages(String threadId, Message lastMessage) async {
    final snapshot = await _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
  }

  Future<void> sendMessage(
      String threadId, String body, String sender) async {
    final message = PlaceChatMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      taggedUser: '', // This needs to be implemented based on your app's logic
    );
    await _firestore
        .collection('PlaceChatThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<Message>> getDmMessages(String threadId) {
    return _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data()))
            .toList());
  }

  Future<List<Message>> getMoreDmMessages(String threadId, Message lastMessage) async {
    final snapshot = await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
  }

  Future<void> sendDmMessage(String threadId, String body, String sender, String recipient) async {
    final message = DirectMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      recipient: recipient,
    );
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }
}
