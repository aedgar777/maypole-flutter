import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Debug screen to check profile pictures in Firestore
/// Run this to see which users have profile pictures
class DebugProfilePicturesScreen extends StatelessWidget {
  const DebugProfilePicturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug: Profile Pictures')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final username = userData['username'] ?? 'Unknown';
              final profilePictureUrl = userData['profilePictureUrl'] ?? '';
              final hasProfilePic = profilePictureUrl.isNotEmpty;

              return ListTile(
                leading: Icon(
                  hasProfilePic ? Icons.check_circle : Icons.cancel,
                  color: hasProfilePic ? Colors.green : Colors.red,
                ),
                title: Text(username),
                subtitle: Text(
                  hasProfilePic 
                      ? 'Has profile picture\n${profilePictureUrl.substring(0, 50)}...'
                      : 'NO PROFILE PICTURE',
                  style: TextStyle(
                    color: hasProfilePic ? Colors.green : Colors.red,
                  ),
                ),
                isThreeLine: hasProfilePic,
              );
            },
          );
        },
      ),
    );
  }
}
