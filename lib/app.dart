import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/user_profile.dart';
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
  late bool signedIn;
  late CollectionReference exercisesQuery;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    signedIn = FirebaseAuth.instance.currentUser != null;
    // Load local shared preferences data if no user is signed in
    if (!signedIn) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // _names = ["Pushups", "Dips", "Pullups", "Squats"];
        // _descriptions = ["Raised", "Medium bar", "High bar", ""];
        // _valueHistories = getHistoriesMapList([
        //   '{"2022-10-29 00:00:00.000":8, "2022-11-04 00:00:00.000":9, "2022-11-10 00:00:00.000":8, "2022-11-11 00:00:00.000":77}',
        //   '{"2023-10-29 00:00:00.000":2, "2023-10-30 00:00:00.000":2, "2023-10-31 00:00:00.000":3, "2023-11-01 00:00:00.000":4, "2023-11-05 00:00:00.000":4, "2023-11-06 00:00:00.000":5, "2023-11-08 00:00:00.000":6, "2023-11-09 00:00:00.000":7}',
        //   '{"2023-10-21 00:00:00.000":4, "2023-10-22 00:00:00.000":4, "2023-10-24 00:00:00.000":5, "2023-10-25 00:00:00.000":6}',
        //   '{"2023-10-05 00:00:00.000":11, "2023-10-22 00:00:00.000":12, "2023-10-24 00:00:00.000":10}'
        // ]);
        // prefs.setStringList('names', _names);
        // prefs.setStringList('descriptions', _descriptions);
        // prefs.setStringList(
        //     'valueHistories', getHistoriesStringList(_valueHistories));
        _names = prefs.getStringList('names') ?? [];
        _descriptions = prefs.getStringList('descriptions') ?? [];
        _valueHistories = getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      });
    }
    // Load firestore data if user is signed in
    else {
      // Set firestore user reference and exercises query
      final firestoreUser = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
      exercisesQuery = firestoreUser.collection('exercises');

      // Check if user already exists in firestore
      final user = await firestoreUser.get();
      if (!user.exists) {
        // If user does not exist, create user document in firestore
        firestoreUser.set({});
      } else {
        // If user exists, load exercises data from firestore
        final exercisesSnapshot = await exercisesQuery.orderBy("orderIndex").get();
        for (final exerciseSnapshot in exercisesSnapshot.docs) {
          final exercise = exerciseSnapshot.data() as Map<String, dynamic>;

          // Get value history data from firestore
          Map<DateTime, int> historyMap = {};
          final historiesSnapshot = await exerciseSnapshot.reference.collection('valueHistory').orderBy("date").get();
          for (final historySnapshot in historiesSnapshot.docs) {
            final valueHistory = historySnapshot.data();
            historyMap[valueHistory['date'].toDate()] = valueHistory['amount'];
          }

          // Add exercise data to local state
          setState(() {
            _names.add(exercise['name']);
            _descriptions.add(exercise['description']);
            _valueHistories.add(historyMap);
          });
        }
      }
    }
  }

  Future<void> _updatePreferences(Function changePreferences) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (FirebaseAuth.instance.currentUser == null) {
        // Get the data from shared preferences
        _names = prefs.getStringList('names') ?? [];
        _descriptions = prefs.getStringList('descriptions') ?? [];
        _valueHistories = getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
      }

      // Change data
      changePreferences();

      if (FirebaseAuth.instance.currentUser == null) {
        // Save the data to shared preferences
        prefs.setStringList('names', _names);
        prefs.setStringList('descriptions', _descriptions);
        prefs.setStringList('valueHistories', getHistoriesStringList(_valueHistories));
      }
    });
  }

  void _addExercise() {
    _updatePreferences(() {
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _valueHistories.add({getCurrentDate(): 0});
    });

    // Create new firestore exercise
    if (signedIn) {
      // Create new exercise document
      exercisesQuery.add({
        'name': _exerciseName,
        'description': _exerciseDescription,
        'orderIndex': _names.length,
      }).then((final exerciseRef) {
        // Create new value history document
        exerciseRef.collection('valueHistory').add({
          'date': getCurrentDate(),
          'amount': 0,
        });
      });
    }
  }

  Future<void> _removeExercise(index) async {
    _updatePreferences(() {
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _valueHistories.removeAt(index);
    });

    // Remove firestore exercise
    if (signedIn) {
      // Get exercise and delete subcollection
      final exercisesSnapshot = await exercisesQuery.orderBy('orderIndex').get();
      final exerciseSnapshot = exercisesSnapshot.docs[index];
      final historiesSnapshot = await exerciseSnapshot.reference.collection('valueHistory').get();
      for (final historySnapshot in historiesSnapshot.docs) {
        historySnapshot.reference.delete();
      }
      // Delete exercise document
      exerciseSnapshot.reference.delete();

      // Update orderIndex for remaining exercises
      for (int i = index + 1; i < exercisesSnapshot.docs.length; i++) {
        exercisesSnapshot.docs[i].reference.update({'orderIndex': i - 1});
      }
    }
  }

  void _updateExercise(index, newName, newDescription, newValue) {
    _updatePreferences(() async {
      // Exercise name change
      if (_names[index] != newName) {
        _names[index] = newName;
        if (signedIn) {
          exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
            exercisesSnapshot.docs[index].reference.update({'name': newName});
          });
        }
      }
      // Exercise description change
      if (_descriptions[index] != newDescription) {
        _descriptions[index] = newDescription;
        if (signedIn) {
          exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
            exercisesSnapshot.docs[index].reference.update({'description': newDescription});
          });
        }
      }
      // Exercise value change
      if (newValue != null) {
        _valueHistories[index][getCurrentDate()] = newValue;
        if (signedIn) {
          // Get last date of value history
          final exercisesSnapshot = await exercisesQuery.orderBy("orderIndex").get();
          final exerciseSnapshot = exercisesSnapshot.docs[index];
          final historiesSnapshot = await exerciseSnapshot.reference.collection('valueHistory').orderBy("date").get();
          DateTime lastDate = historiesSnapshot.docs.last.data()['date'].toDate();

          // If last date is today, update amount, else add new value history
          if (lastDate.year == getCurrentDate().year &&
              lastDate.month == getCurrentDate().month &&
              lastDate.day == getCurrentDate().day) {
            historiesSnapshot.docs.last.reference.update({'amount': newValue});
          } else {
            exerciseSnapshot.reference.collection('valueHistory').add({
              'date': getCurrentDate(),
              'amount': newValue,
            });
          }
        }
      }
    });
  }

  void _reorderExercise(oldIndex, newIndex) async {
    _updatePreferences(() {
      // Change indices to more intuitive values
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
    if (signedIn) {
      // Set exercise oldIndex to newIndex
      final exercisesSnapshot = await exercisesQuery.orderBy('orderIndex').get();
      exercisesSnapshot.docs[oldIndex].reference.update({'orderIndex': newIndex});

      // Action for moving exercise up
      if (newIndex > oldIndex) {
        for (int i = oldIndex + 1; i < newIndex; i++) {
          exercisesSnapshot.docs[i].reference.update({'orderIndex': i - 1});
        }
      }
      // Action for moving exercise down
      else {
        for (int i = newIndex; i < oldIndex; i++) {
          exercisesSnapshot.docs[i].reference.update({'orderIndex': i + 1});
        }
      }
    }
  }

  List<Map<DateTime, int>> getHistoriesMapList(List<String> historiesStringList) {
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

  List<String> getHistoriesStringList(List<Map<DateTime, int>> historiesMapList) {
    List<String> returnList = [];
    for (Map<DateTime, int> historyMap in historiesMapList) {
      String historyString = jsonEncode(historyMap.map((key, value) => MapEntry(key.toString(), value)));
      returnList.add(historyString);
    }
    return returnList;
  }

  DateTime getCurrentDate() {
    return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
              title: isNew ? const Text('Add new exercise') : const Text('Edit exercise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Exercise name', hintText: 'e.g. Pushups'),
                    onChanged: (value) {
                      setState(() {
                        _exerciseName = value;
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Wide Grip'),
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
                          isNew ? _addExercise() : _updateExercise(index, _exerciseName, _exerciseDescription, null);
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
              content: const Text('Are you sure you want to delete this exercise? Your statistics will also be lost.'),
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
      endDrawer: const Drawer(width: 350, child: UserProfile()),
      appBar: AppBar(
        title: Text(widget.titles[_currentPageIndex]),
        actions: [
          if (_currentPageIndex == 0)
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
                return IconButton(
                  icon: !snapshot.hasData || snapshot.data!.photoURL == null
                      ? const Icon(Icons.account_circle)
                      : CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data!.photoURL ?? ''),
                          backgroundColor: Colors.transparent,
                        ),
                  tooltip: 'User Profile',
                  onPressed: () => {
                    Scaffold.of(context).openEndDrawer(),
                  },
                );
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
              Statistics(names: _names, valueHistories: _valueHistories, currentDate: getCurrentDate()),
            ][_currentPageIndex],
      floatingActionButton: !_editMode && _currentPageIndex == 0
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
