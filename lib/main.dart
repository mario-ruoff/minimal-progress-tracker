import 'package:flutter/material.dart';

void main() {
  runApp(const ProgressTracker());
}

class ProgressTracker extends StatelessWidget {
  const ProgressTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Progress Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MainPage(title: 'Minimal Progress Tracker'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List _data = <List>[];
  bool _editMode = false;

  void _addExercise() {
    setState(() {
      _data.add(['Pullups', 0]);
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
          itemCount: _data.length,
          itemBuilder: (context, index) {
            final exercise = _data[index][0];
            final value = _data[index][1];
            return Card(
                child: ListTile(
              leading: const FlutterLogo(size: 42.0),
              title: Text('$exercise'),
              subtitle: const Text('Here is a second line'),
              trailing: _editMode
                  ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _editMode
                            ? () {
                                setState(() {
                                  _data.removeAt(index);
                                });
                              }
                            : null,
                      )
                    ])
                  : Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove),
                        disabledColor: Colors.grey.shade300,
                        onPressed: value <= 0
                            ? null
                            : () {
                                setState(() {
                                  _data[index][1] = value - 1;
                                });
                              },
                      ),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${_data[index][1]}',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        disabledColor: Colors.grey.shade300,
                        onPressed: value >= 100
                            ? null
                            : () {
                                setState(() {
                                  _data[index][1] = value + 1;
                                });
                              },
                      ),
                    ]),
            ));
          }),
      floatingActionButton: _editMode
          ? null
          : FloatingActionButton(
              onPressed: _addExercise,
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            ),
    );
  }
}
