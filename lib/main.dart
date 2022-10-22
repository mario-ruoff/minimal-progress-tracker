import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Progress Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Minimal Progress Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _data = <int>[];
  var _editMode = false;

  void _addExercise() {
    setState(() {
      final nextValue = _data.isNotEmpty ? _data[_data.length - 1] + 1 : 1;
      _data.add(nextValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _editMode = !_editMode;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: _data.length,
          itemBuilder: (context, index) {
            final value = _data[index];
            return Card(
                child: ListTile(
              leading: const FlutterLogo(size: 42.0),
              title: Text('$value'),
              subtitle: const Text('Here is a second line'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                IconButton(
                  icon: Icon(_editMode ? Icons.delete : Icons.more_vert),
                  onPressed: _editMode
                      ? () {
                          setState(() {
                            _data.removeAt(index);
                          });
                        }
                      : null,
                )
              ]),
            ));
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}
