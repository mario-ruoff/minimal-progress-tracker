import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/exercise_list.dart';
import 'package:minimal_progress_tracker/screens/statistics.dart';
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
        brightness: Brightness.light,
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.lightBlue,
        useMaterial3: true,
      ),
      home: const MainPage(
        titles: ["Exercise List", "Progress Statistics"],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.titles});

  final List<String> titles;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;
  bool _editMode = false;
  List<String> _names = [];
  List<String> _descriptions = [];
  List<String> _values = [];
  String _exerciseName = '';
  String _exerciseDescription = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _values = prefs.getStringList('values') ?? [];
    });
  }

  Future<void> _addExercise() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _values = prefs.getStringList('values') ?? [];
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _values.add('0');
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList('values', _values);
    });
  }

  Future<void> _removeExercise(index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _values = prefs.getStringList('values') ?? [];
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _values.removeAt(index);
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList('values', _values);
    });
  }

  Future<void> _updateExercise(index, newValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _values = prefs.getStringList('values') ?? [];
      _values[index] = '$newValue';
      prefs.setStringList('values', _values);
    });
  }

  Future<void> _newExerciseDialog(BuildContext context) async {
    setState(() {
      _exerciseName = '';
      _exerciseDescription = '';
    });
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: const Text('Add new exercise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Exercise name', hintText: 'e.g. Pushups'),
                    onChanged: (value) {
                      setState(() {
                        _exerciseName = value;
                      });
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'Description', hintText: 'e.g. Raised bar'),
                    onChanged: (value) {
                      setState(() {
                        _exerciseDescription = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  onPressed: _exerciseName.isNotEmpty
                      ? () {
                          _addExercise();
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            );
          }));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titles[currentPageIndex]),
        actions: currentPageIndex != 0
            ? null
            : [
                IconButton(
                  icon: Icon(_editMode ? Icons.done : Icons.edit),
                  tooltip: 'Edit exercises',
                  onPressed: () {
                    setState(() {
                      _editMode = !_editMode;
                    });
                  },
                ),
              ],
      ),
      body: <Widget>[
        ExerciseList(
            editMode: _editMode,
            names: _names,
            descriptions: _descriptions,
            values: _values,
            removeExercise: _removeExercise,
            updateExercise: _updateExercise),
        Statistics(names: _names, values: _values),
      ][currentPageIndex],
      floatingActionButton: !_editMode && currentPageIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _newExerciseDialog(context);
              },
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
