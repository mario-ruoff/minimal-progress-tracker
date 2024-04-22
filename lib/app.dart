import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/user_profile.dart';
import 'package:minimal_progress_tracker/screens/exercise_list.dart';
import 'package:minimal_progress_tracker/screens/statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/local_storage_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.titles});

  final List<String> titles;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _localStorage = LocalStorageService();
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
    _handleAuthChange();
  }

  // Load data depending on user sign in status
  void _handleAuthChange() {
    print("Checking for auth change");
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      signedIn = user != null;
      // Start app signed in or change to signed in state
      if (signedIn) {
        print("User signed in");
        // If user doesnt already have local data
        if (_names.isEmpty) {
          // _loadData();
        }
        // If user already has local data
        else {}
      }
      // Start app signed out or change to signed out state
      else {
        print("User signed out");
        // _clearData();
        _loadData();
      }
    });
  }

  // Load data from shared preferences or firestore
  Future<void> _loadData() async {
    signedIn = FirebaseAuth.instance.currentUser != null;

    // Load local shared preferences data if no user is signed in
    if (!signedIn) {
      final (names, descriptions, valueHistories) = await _localStorage.loadData();
      setState(() {
        _names = names;
        _descriptions = descriptions;
        _valueHistories = valueHistories;
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

  // Clear data variables
  void _clearData() {
    setState(() {
      _names = [];
      _descriptions = [];
      _valueHistories = [];
    });
  }

  // Update local preferences
  // Future<void> _updatePreferences() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   // setState(() {
  //   // if (FirebaseAuth.instance.currentUser == null) {
  //   //   // Get the data from shared preferences
  //   //   _names = prefs.getStringList('names') ?? [];
  //   //   _descriptions = prefs.getStringList('descriptions') ?? [];
  //   //   _valueHistories = getHistoriesMapList(prefs.getStringList('valueHistories') ?? []);
  //   // }

  //   // // Change data
  //   // changePreferences();

  //   // if (FirebaseAuth.instance.currentUser == null) {
  //   // Save the data to shared preferences
  //   prefs.setStringList('names', _names);
  //   prefs.setStringList('descriptions', _descriptions);
  //   prefs.setStringList('valueHistories', getHistoriesStringList(_valueHistories));
  //   // }
  //   // });
  // }

  // Add new exercise
  Future<void> _addExercise() async {
    setState(() {
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _valueHistories.add({getCurrentDate(): 0});
    });

    // Update shared preferences if not signed in
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    }

    // Create new firestore exercise if sigend in
    else {
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

  // Remove exercise
  Future<void> _removeExercise(index) async {
    setState(() {
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _valueHistories.removeAt(index);
    });

    // Update shared preferences if not signed in
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    }

    // Remove firestore exercise if signed in
    else {
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

  // Update exercise
  Future<void> _updateExercise(index, newName, newDescription, newValue) async {
    // Exercise name change
    if (_names[index] != newName) {
      setState(() {
        _names[index] = newName;
      });
      if (!signedIn) {
        _localStorage.updateNames(_names);
      } else {
        exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
          exercisesSnapshot.docs[index].reference.update({'name': newName});
        });
      }
    }
    // Exercise description change
    if (_descriptions[index] != newDescription) {
      setState(() {
        _descriptions[index] = newDescription;
      });
      if (!signedIn) {
        _localStorage.updateDescriptions(_descriptions);
      } else {
        exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
          exercisesSnapshot.docs[index].reference.update({'description': newDescription});
        });
      }
    }
    // Exercise value change
    if (newValue != null) {
      setState(() {
        _valueHistories[index][getCurrentDate()] = newValue;
      });
      if (!signedIn) {
        _localStorage.updateValueHistories(_valueHistories);
      } else {
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
  }

  // Reorder exercise
  void _reorderExercise(oldIndex, newIndex) async {
    // Change indices to more intuitive values
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final nameItem = _names.removeAt(oldIndex);
      _names.insert(newIndex, nameItem);
      final descriptionItem = _descriptions.removeAt(oldIndex);
      _descriptions.insert(newIndex, descriptionItem);
      final valueItem = _valueHistories.removeAt(oldIndex);
      _valueHistories.insert(newIndex, valueItem);
    });

    // Update shared preferences if not signed in
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    }

    // Change order indices in firestore
    else {
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
