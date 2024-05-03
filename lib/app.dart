import 'package:flutter/material.dart';
import 'package:minimal_progress_tracker/screens/user_profile.dart';
import 'package:minimal_progress_tracker/screens/exercise_list.dart';
import 'package:minimal_progress_tracker/screens/statistics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/local_storage_service.dart';
import 'services/firestore_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.titles});

  final List<String> titles;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _localStorage = LocalStorageService();
  final _firestore = FirestoreService();
  late bool signedIn;
  bool networkImageError = false;
  int _currentPageIndex = 0;
  bool _editMode = false;
  bool _dataLoaded = false;
  List<String> _names = [];
  List<String> _descriptions = [];
  List<Map<DateTime, int>> _valueHistories = [];
  String _exerciseName = '';
  String _exerciseDescription = '';

  @override
  void initState() {
    super.initState();
    _handleAuthChange();
  }

  // Load data depending on user sign in status
  void _handleAuthChange() {
    // auth state change is also executed on app start
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      signedIn = user != null;
      if (signedIn) {
        if (_names.isEmpty) {
          // | Local -> Firestore |
          // | -     |  ?         | => load firestore data, no moving data
          _loadData();
        } else {
          if (await _firestore.isDataOnFirestore(user!.uid)) {
            // | Local -> Firestore |
            // | data  |  data      | => ask to override firestore data
            _overrideDataDialog(true);
          } else {
            // | Local -> Firestore |
            // | data  |  -         | => move local data to firestore
            await _firestore.moveData(_names, _descriptions, _valueHistories, false);
            _clearData();
            _loadData();
          }
        }
      } else {
        if (_names.isEmpty) {
          // | Local <- Firestore |
          // | ?      | -         | => load local data, no moving data
          _loadData();
        } else {
          if (await _localStorage.isDataInStorage()) {
            // | Local <- Firestore |
            // | data   | data      | => ask to override local data
            _overrideDataDialog(false);
          } else {
            // | Local <- Firestore |
            // | -      | data      | => move firestore data to local
            _localStorage.moveData(_names, _descriptions, _valueHistories);
            _clearData();
            _loadData();
          }
        }
      }
    });
  }

  // Load data from shared preferences or firestore
  Future<void> _loadData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    signedIn = authUser != null;
    List<String> names, descriptions;
    List<Map<DateTime, int>> valueHistories;

    setState(() {
      _dataLoaded = false;
    });

    // Load data from shared preferences or cached firestore
    if (!signedIn) {
      (names, descriptions, valueHistories) = await _localStorage.loadData();
    } else {
      (names, descriptions, valueHistories) = await _firestore.loadData(authUser!.uid, true);
    }
    setState(() {
      _names = names;
      _descriptions = descriptions;
      _valueHistories = valueHistories;
      _dataLoaded = true;
    });

    // If cached firestore data is loaded, load from firestore
  }

  // Clear data variables
  void _clearData() {
    setState(() {
      _names = [];
      _descriptions = [];
      _valueHistories = [];
    });
  }

  // Add new exercise
  Future<void> _addExercise() async {
    setState(() {
      _names.add(_exerciseName);
      _descriptions.add(_exerciseDescription);
      _valueHistories.add({getCurrentDate(): 0});
    });
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    } else {
      _firestore.addExercise(_exerciseName, _exerciseDescription, _names.length, getCurrentDate());
    }
  }

  // Remove exercise
  Future<void> _removeExercise(index) async {
    setState(() {
      _names.removeAt(index);
      _descriptions.removeAt(index);
      _valueHistories.removeAt(index);
    });
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    } else {
      _firestore.removeExercise(index);
    }
    // Exit edit mode if no exercises left
    if (_names.isEmpty) {
      setState(() {
        _editMode = false;
      });
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
        _firestore.updateName(index, newName);
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
        _firestore.updateDescription(index, newDescription);
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
        _firestore.updateValue(index, newValue, getCurrentDate());
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
    if (!signedIn) {
      _localStorage.updateAllPreferences(_names, _descriptions, _valueHistories);
    } else {
      _firestore.reorderExercises(oldIndex, newIndex);
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

  Future<void> _overrideDataDialog(bool toCloud) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: Text(toCloud ? 'Override Cloud Data' : 'Move Cloud Data'),
              content: Text(toCloud
                  ? 'You already have data stored in the cloud. Do you want to override it with your local data?'
                  : 'Do you want to move your cloud data back to your local storage?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    // Load data, do not override
                    _loadData();
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  onPressed: () {
                    toCloud
                        // Override cloud data with local data
                        ? _firestore.moveData(_names, _descriptions, _valueHistories, true)
                        // Override local data with cloud data
                        : _localStorage.moveData(_names, _descriptions, _valueHistories);
                    // no new data loading required, since data is already in desired state
                    Navigator.pop(context);
                  },
                  child: const Text('Override'),
                ),
              ],
            );
          }));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(width: 350, child: UserProfile(firestore: _firestore)),
      appBar: AppBar(
        title: Text(widget.titles[_currentPageIndex]),
        actions: [
          if (_currentPageIndex == 0 && _names.isNotEmpty)
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
                  icon: !snapshot.hasData
                      ? const Icon(Icons.account_circle) // User is not signed in
                      : (snapshot.data!.photoURL == null || networkImageError
                          ? CircleAvatar(
                              // User is signed in, but no profile picture
                              child: Text(snapshot.hasData ? snapshot.data!.displayName![0] : 'U'),
                            )
                          : CircleAvatar(
                              // User is signed in and has a profile picture
                              backgroundImage: NetworkImage(snapshot.data!.photoURL!),
                              onBackgroundImageError: (exception, stackTrace) => setState(() {
                                networkImageError = true;
                              }),
                            )),
                  tooltip: 'User Profile',
                  onPressed: () => {
                    Scaffold.of(context).openEndDrawer(),
                  },
                );
              }),
        ],
      ),
      body: !_dataLoaded
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading Exercises...', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : (_names.isEmpty
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
                    currentDate: getCurrentDate(),
                  ),
                ][_currentPageIndex]),
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
