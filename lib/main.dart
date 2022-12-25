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
        primarySwatch: Colors.blue,
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
      _names = ["Pushups", "Dips", "Pullups", "Squats"];
      _descriptions = ["Raised", "Medium bar", "High bar", ""];
      _valueHistories = getHistoriesMapList([
        '{"2022-10-29 00:00:00.000":8, "2022-11-04 00:00:00.000":9, "2022-11-10 00:00:00.000":8, "2022-11-11 00:00:00.000":77}',
        '{"2022-10-29 00:00:00.000":2, "2022-10-30 00:00:00.000":2, "2022-10-31 00:00:00.000":3, "2022-11-01 00:00:00.000":4, "2022-11-05 00:00:00.000":4, "2022-11-06 00:00:00.000":5, "2022-11-08 00:00:00.000":6, "2022-11-09 00:00:00.000":7}',
        '{"2022-10-21 00:00:00.000":4, "2022-10-22 00:00:00.000":4, "2022-10-24 00:00:00.000":5, "2022-10-25 00:00:00.000":6}',
        '{"2022-10-05 00:00:00.000":11, "2022-10-22 00:00:00.000":12, "2022-10-24 00:00:00.000":10}'
      ]);
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
      // _names = prefs.getStringList('names') ?? [];
      // _descriptions = prefs.getStringList('descriptions') ?? [];
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

  Future<void> _updateExercise(index, newName, newDescription, newValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      if (_names[index] != newName) _names[index] = newName;
      if (_descriptions[index] != newDescription)
        _descriptions[index] = newDescription;
      if (newValue != null) _valueHistories[index][getCurrentDate()] = newValue;
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
    });
  }

  Future<void> _reorderExercise(oldIndex, newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final nameItem = _names.removeAt(oldIndex);
      _names.insert(newIndex, nameItem);
      final descriptionItem = _descriptions.removeAt(oldIndex);
      _descriptions.insert(newIndex, descriptionItem);
      final valueItem = _valueHistories.removeAt(oldIndex);
      _valueHistories.insert(newIndex, valueItem);
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
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

  Future<void> _exerciseDialog(context, index, name, description, isNew) async {
    setState(() {
      _exerciseName = name;
      _exerciseDescription = description;
    });
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: isNew
                  ? const Text('Add new exercise')
                  : const Text('Edit exercise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    initialValue: name,
                    decoration: const InputDecoration(
                        labelText: 'Exercise name', hintText: 'e.g. Pushups'),
                    onChanged: (value) {
                      setState(() {
                        _exerciseName = value;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: description,
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
                          isNew
                              ? _addExercise()
                              : _updateExercise(index, _exerciseName,
                                  _exerciseDescription, null);
                          Navigator.pop(context);
                        }
                      : null,
                  child: isNew ? const Text('Add') : const Text('Save'),
                ),
              ],
            );
          }));
        });
  }

  Future<void> _confirmRemoveDialog(index) async {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: const Text('Delete exercise'),
              content: const Text(
                  'Are you sure you want to delete this exercise? Your statistics will also be lost.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  onPressed: () {
                    _removeExercise(index);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete'),
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
      body: _valueHistories.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 10,
              ),
              child: Center(
                child: Text(
                  'No exercises added yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            )
          : <Widget>[
              ExerciseList(
                  editMode: _editMode,
                  names: _names,
                  descriptions: _descriptions,
                  valueHistories: _valueHistories,
                  exerciseDialog: _exerciseDialog,
                  confirmRemoveDialog: _confirmRemoveDialog,
                  updateExercise: _updateExercise,
                  reorderExercise: _reorderExercise),
              Statistics(
                  names: _names,
                  valueHistories: _valueHistories,
                  currentDate: getCurrentDate()),
            ][currentPageIndex],
      floatingActionButton: !_editMode && currentPageIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _exerciseDialog(context, 0, '', '', true);
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
