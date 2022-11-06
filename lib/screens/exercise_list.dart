import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ExerciseList extends StatefulWidget {
  const ExerciseList({super.key, this.editMode = false});

  final bool editMode;

  @override
  State<ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  List<String> _names = [];
  List<String> _descriptions = [];
  List<String> _values = [];
  String _exerciseName = '';
  String _exerciseDescription = '';
  var random = Random();

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

  Future<void> _updateValue(index, newValue) async {
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
    return Stack(children: [
      ReorderableListView.builder(
          itemCount: _names.length,
          itemBuilder: (context, index) {
            final exercise = _names[index];
            final description = _descriptions[index];
            final value = int.parse(_values[index]);
            return Card(
                key: Key(exercise + random.nextInt(10000).toString()),
                child: ListTile(
                  leading: widget.editMode
                      ? ReorderableDragStartListener(
                          index: index, child: const Icon(Icons.drag_handle))
                      : null,
                  title: Text(exercise),
                  subtitle: Text(description),
                  trailing: widget.editMode
                      ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: widget.editMode
                                ? () {
                                    setState(() {
                                      _removeExercise(index);
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
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final nameItem = _names.removeAt(oldIndex);
              _names.insert(newIndex, nameItem);
              final descriptionItem = _descriptions.removeAt(oldIndex);
              _descriptions.insert(newIndex, descriptionItem);
              final valueItem = _values.removeAt(oldIndex);
              _values.insert(newIndex, valueItem);
            });
          },
          buildDefaultDragHandles: false),
      if (!widget.editMode)
        Positioned(
          bottom: 20,
          right: 20,
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                _newExerciseDialog(context);
              },
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            ),
          ),
        ),
    ]);
  }
}
