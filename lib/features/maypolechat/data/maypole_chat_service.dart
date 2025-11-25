import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
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

  Future<List<MaypoleMessage>> getMoreMessages(
      String threadId, MaypoleMessage lastMessage) async {
    final snapshot = await _firestore
        .collection('maypoles')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([lastMessage.timestamp])
        .limit(_messageLimit)
        .get();

    return snapshot.docs
        .map((doc) => MaypoleMessage.fromMap(doc.data()))
        .toList();
  }

  Future<void> sendMessage(
    String threadId,
    String maypoleName,
    String body,
    DomainUser sender,
  ) async {
    final now = DateTime.now();
    final message = MaypoleMessage(
      sender: sender.username,
      timestamp: now,
      body: body,
      taggedUser:
          '', // TODO This needs to be implemented based on your app's user tagging logic
    );

    final maypoleRef = _firestore.collection('maypoles').doc(threadId);
    final messageRef = maypoleRef.collection('messages').doc();

    final batch = _firestore.batch();

    // "Upsert" the maypole document: create if it doesn't exist, update if it does
    batch.set(
        maypoleRef,
        {
          'id': threadId,
          'name': maypoleName,
        },
        SetOptions(merge: true));

    // Add the new message to the subcollection
    batch.set(messageRef, message.toMap());

    // Check if user already has this maypole in their list (using local data)
    if (!sender.maypoleChatThreads.any((element) => element.id == threadId)) {
      final maypoleMetaData = MaypoleMetaData(
        id: threadId,
        name: maypoleName,
      );
      final userRef = _firestore.collection('users').doc(sender.firebaseID);
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    }

    await batch.commit();
  }

  Future<void> sendMaypoleMessage(String threadId, String maypoleName,
      String body, DomainUser sender) async {
    final now = DateTime.now();
    final message = MaypoleMessage(
      sender: sender.username,
      timestamp: now,
      body: body,
      taggedUser:
      '', // TODO This needs to be implemented based on your app's user tagging logic
    );

    final maypoleRef = _firestore.collection('maypoles').doc(threadId);
    final messageRef = maypoleRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(
        maypoleRef,
        {
          'id': threadId,
          'name': maypoleName,
        },
        SetOptions(merge: true));
    batch.set(messageRef, message.toMap());

    // Check if user already has this maypole in their list (using local data)
    if (!sender.maypoleChatThreads.any((element) => element.id == threadId)) {
      final maypoleMetaData =
      MaypoleMetaData(id: threadId, name: maypoleName);
      final userRef = _firestore.collection('users').doc(sender.firebaseID);
      batch.update(userRef, {
        'maypoleChatThreads': FieldValue.arrayUnion([maypoleMetaData.toMap()])
      });
    }

    await batch.commit();
  }
}
