import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maypole/features/directmessages/domain/dm_thread.dart';

import '../domain/direct_message.dart';

class DMThreadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  Future<DMThread?> getDMThreadById(String threadId) async {
    final dmThreadDoc =
        await _firestore.collection('DMThreads').doc(threadId).get();
    if (dmThreadDoc.exists) {
      return DMThread.fromMap(dmThreadDoc.data()!);
    }
    return null;
  }

  Stream<List<DirectMessage>> getDmMessages(String threadId) {
    return _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DirectMessage.fromMap(doc.data()))
            .toList());
  }

  Future<List<DirectMessage>> getMoreDmMessages(String threadId, DirectMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => DirectMessage.fromMap(doc.data())).toList();
  }

  Future<void> sendDmMessage(String threadId, String body, String sender, String recipient) async {
    final message = DirectMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      recipient: '',
    );
    await _firestore
        .collection('DMThreads')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }
}
