
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';

import '../../domain/thread.dart';

class ThreadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Thread>> getThreads(String firebaseId) async {
    final userDoc = await _firestore.collection('Users').doc(firebaseId).get();
    final user = DomainUser.fromMap(userDoc.data()!);

    final List<Thread> threads = [];

    for (final thread in user.threads) {
      final placeChatThreadDoc =
          await _firestore.collection('PlaceChatThreads').doc(thread.id).get();
      if (placeChatThreadDoc.exists) {
        threads.add(Thread.fromMap(placeChatThreadDoc.data()!));
        continue;
      }

      final dmThreadDoc =
          await _firestore.collection('DMThreads').doc(thread.id).get();
      if (dmThreadDoc.exists) {
        threads.add(Thread.fromMap(dmThreadDoc.data()!));
      }
    }

    return threads;
  }
}
