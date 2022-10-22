// // Copyright 2018 The Flutter team. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// import 'package:english_words/english_words.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Welcome to Flutter',
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Welcome to Flutter'),
//         ),
//         body: const Center(
//           child: RandomWords(),
//         ),
//       ),
//     );
//   }
// }

// class RandomWords extends StatefulWidget {
//   const RandomWords({super.key});

//   @override
//   State<RandomWords> createState() => _RandomWordsState();
// }

// class _RandomWordsState extends State<RandomWords> {
//   final _suggestions = <WordPair>[];
//   final _saved = <WordPair>{};
//   final _biggerFont = const TextStyle(fontSize: 18);
//   @override
//   Widget build(BuildContext context) {
//     final wordPair = WordPair.random();
//     return ListView.builder(itemBuilder: (context, index) {
//       if (index >= _suggestions.length) {
//         _suggestions.addAll(generateWordPairs().take(10));
//       }
//       final alreadySaved = _saved.contains(_suggestions[index]);
//       return Card(
//         child: ListTile(
//           leading: const FlutterLogo(size: 42.0),
//           title: Text(_suggestions[index].asPascalCase),
//           subtitle: const Text('Here is a second line'),
//           trailing: Icon(
//             alreadySaved ? Icons.favorite : Icons.favorite_border,
//             color: alreadySaved ? Colors.red : null,
//             semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
//           ),
//           onTap: () {
//             setState(() {
//               if (alreadySaved) {
//                 _saved.remove(_suggestions[index]);
//               } else {
//                 _saved.add(_suggestions[index]);
//               }
//             });
//           },
//         ),
//       );
//     });
//   }
// }
