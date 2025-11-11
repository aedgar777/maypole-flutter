import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/maypole.dart';
import '../domain/maypole_message.dart';

class MaypoleChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _messageLimit = 100;

  Future<Maypole?> getMaypoleById(String threadId) async {
    final maypoleDoc =
        await _firestore.collection('maypoles').doc(threadId).get();
    if (maypoleDoc.exists) {
      return Maypole.fromMap(maypoleDoc.data()!);
    }
    return null;
  }

  Stream<List<MaypoleMessage>> getMessages(String threadId) {
    return _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaypoleMessage.fromMap(doc.data()))
            .toList());
  }

  Future<List<MaypoleMessage>> getMoreMessages(String threadId, MaypoleMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs.map((doc) => MaypoleMessage.fromMap(doc.data())).toList();
  }

  Future<void> sendMessage(
      String threadId, String body, String sender) async {
    final message = MaypoleMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      taggedUser: '', // TODO This needs to be implemented based on your app's user tagging logic
    );
    await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<void> sendPlaceMessage(
      String threadId, String body, String sender) async {
    final message = MaypoleMessage(
      sender: sender,
      timestamp: DateTime.now(),
      body: body,
      taggedUser: '', // TODO This needs to be implemented based on your app's user tagging logic
    );
    await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .add(message.toMap());
  }
}
