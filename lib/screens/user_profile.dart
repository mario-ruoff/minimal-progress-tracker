import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../services/firestore_service.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.firestore});
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
              showAuthActionSwitch: false,
              headerBuilder: (context, constraints, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Profile',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      Text('You can securely save your training progress to the cloud by signing in.',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              },
              footerBuilder: (context, action) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              });
        }
        return ProfileScreen(
          showDeleteConfirmationDialog: true,
          appBar: AppBar(
            title: Text('User Profile', style: Theme.of(context).textTheme.headlineMedium),
          ),
          actions: [
            SignedOutAction((context) {
              Navigator.of(context).pop();
            }),
          ],
          providers: const [],
          children: [
            const SizedBox(height: 8),
            const Divider(),
            Text('Your data is securely stored in the cloud.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
