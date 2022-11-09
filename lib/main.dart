import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/exercise_list.dart';
import 'package:minimal_progress_tracker/screens/statistics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  List<Map<DateTime, int>> _valueHistories = [];
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
      _valueHistories = getHistoriesMapList(
          ['{"2022-11-08 00:00:00.000":2, "2022-11-09 00:00:00.000":3}']);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));

      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      // _valueHistories =
      //     getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
    });
  }

  Future<void> _addExercise() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _valueHistories.add({getCurrentDate(): 0});
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
    });
  }

  Future<void> _removeExercise(index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _valueHistories.removeAt(index);
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
    });
  }

  Future<void> _updateExercise(index, newValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      _valueHistories[index][getCurrentDate()] = newValue;
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
    });
  }

  List<Map<DateTime, int>> getHistoriesMapList(
      List<String> historiesStringList) {
    List<Map<DateTime, int>> returnList = [];
    for (String historyString in historiesStringList) {
      dynamic historyDict = jsonDecode(historyString);
      Map<DateTime, int> historyMap = {};
      for (String historyDate in historyDict.keys) {
        historyMap[DateTime.parse(historyDate)] = historyDict[historyDate];
      }
      returnList.add(historyMap);
    }
    return returnList;
  }

  List<String> getHistoriesStringList(
      List<Map<DateTime, int>> historiesMapList) {
    List<String> returnList = [];
    for (Map<DateTime, int> historyMap in historiesMapList) {
      String historyString = jsonEncode(
          historyMap.map((key, value) => MapEntry(key.toString(), value)));
      returnList.add(historyString);
    }
    return returnList;
  }

  DateTime getCurrentDate() {
    return DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
            valueHistories: _valueHistories,
            removeExercise: _removeExercise,
            updateExercise: _updateExercise),
        Statistics(
            names: _names,
            valueHistories: _valueHistories,
            currentDate: getCurrentDate()),
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
