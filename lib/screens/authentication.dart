import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class Authentication extends StatelessWidget {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            subtitleBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                    'You can save your progress to the cloud by signing in.'),
              );
            },
          );
        }

        return ProfileScreen(
          appBar: AppBar(
            title: const Text('User Profile'),
          ),
          actions: [
            SignedOutAction((context) {
              Navigator.of(context).pop();
            })
          ],
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(2),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset('flutterfire_300x.png'),
              ),
            ),
          ],
        );
      },
    );
  }
}
