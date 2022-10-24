import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> _names = [];
  List<String> _values = [];
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _values = prefs.getStringList('values') ?? [];
    });
  }

  Future<void> _addExercise() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _values = prefs.getStringList('values') ?? [];
      _names.add('Pullups');
      _values.add('0');
      prefs.setStringList('names', _names);
      prefs.setStringList('values', _values);
    });
  }

  Future<void> _updateValue(index, newValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _values = prefs.getStringList('values') ?? [];
      _values[index] = '$newValue';
      prefs.setStringList('values', _values);
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
          itemCount: _names.length,
          itemBuilder: (context, index) {
            final exercise = _names[index];
            final value = int.parse(_values[index]);
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
                                  _names.removeAt(index);
                                  _values.removeAt(index);
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
                                _updateValue(index, value - 1);
                              },
                      ),
                      SizedBox(
                        width: 22,
                        child: Text(
                          _values[index],
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
                                _updateValue(index, value + 1);
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
