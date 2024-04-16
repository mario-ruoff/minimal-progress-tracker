import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/authentication.dart';
import 'package:minimal_progress_tracker/screens/exercise_list.dart';
import 'package:minimal_progress_tracker/screens/statistics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.titles});

  final List<String> titles;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPageIndex = 0;
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
    await FirebaseFirestore.instance.collection("users").get().then((event) {
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()}");
      }
    });

    setState(() {
      _names = ["Pushups", "Dips", "Pullups", "Squats"];
      _descriptions = ["Raised", "Medium bar", "High bar", ""];
      _valueHistories = getHistoriesMapList([
        '{"2022-10-29 00:00:00.000":8, "2022-11-04 00:00:00.000":9, "2022-11-10 00:00:00.000":8, "2022-11-11 00:00:00.000":77}',
        '{"2023-10-29 00:00:00.000":2, "2023-10-30 00:00:00.000":2, "2023-10-31 00:00:00.000":3, "2023-11-01 00:00:00.000":4, "2023-11-05 00:00:00.000":4, "2023-11-06 00:00:00.000":5, "2023-11-08 00:00:00.000":6, "2023-11-09 00:00:00.000":7}',
        '{"2023-10-21 00:00:00.000":4, "2023-10-22 00:00:00.000":4, "2023-10-24 00:00:00.000":5, "2023-10-25 00:00:00.000":6}',
        '{"2023-10-05 00:00:00.000":11, "2023-10-22 00:00:00.000":12, "2023-10-24 00:00:00.000":10}'
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

  Future<void> _updatePreferences(Function changePreferences) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Get the data from shared preferences
      _names = prefs.getStringList('names') ?? [];
      _descriptions = prefs.getStringList('descriptions') ?? [];
      _valueHistories =
          getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);

      // Change data
      changePreferences();

      // Save the data to shared preferences
      prefs.setStringList('names', _names);
      prefs.setStringList('descriptions', _descriptions);
      prefs.setStringList(
          'valueHistories', getHistoriesStringList(_valueHistories));
    });
  }

  void _addExercise() {
    _updatePreferences(() {
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _valueHistories.add({getCurrentDate(): 0});
    });
  }

  void _removeExercise(index) {
    _updatePreferences(() {
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _valueHistories.removeAt(index);
    });
  }

  void _updateExercise(index, newName, newDescription, newValue) {
    _updatePreferences(() {
      if (_names[index] != newName) _names[index] = newName;
      if (_descriptions[index] != newDescription) {
        _descriptions[index] = newDescription;
      }
      if (newValue != null) _valueHistories[index][getCurrentDate()] = newValue;
    });
  }

  void _reorderExercise(oldIndex, newIndex) {
    _updatePreferences(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final nameItem = _names.removeAt(oldIndex);
      _names.insert(newIndex, nameItem);
      final descriptionItem = _descriptions.removeAt(oldIndex);
      _descriptions.insert(newIndex, descriptionItem);
      final valueItem = _valueHistories.removeAt(oldIndex);
      _valueHistories.insert(newIndex, valueItem);
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
      endDrawer: const Drawer(width: 350, child: Authentication()),
      appBar: AppBar(
        title: Text(widget.titles[_currentPageIndex]),
        actions: _currentPageIndex != 0
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
                StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return IconButton(
                          icon: const Icon(Icons.login),
                          tooltip: 'Sign in',
                          onPressed: () => {
                            Scaffold.of(context).openEndDrawer(),
                          },
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.account_circle),
                          tooltip: 'Profile',
                          onPressed: () => {
                            Scaffold.of(context).openEndDrawer(),
                          },
                        );
                      }
                    }),
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
            ][_currentPageIndex],
      floatingActionButton: !_editMode
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
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
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
