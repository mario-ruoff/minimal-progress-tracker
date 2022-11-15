import 'package:flutter/material.dart';
import 'dart:math';

class ExerciseList extends StatefulWidget {
  const ExerciseList(
      {super.key,
      required this.editMode,
      required this.names,
      required this.descriptions,
      required this.valueHistories,
      required this.confirmRemoveDialog,
      required this.updateExercise,
      required this.reorderExercise});

  final bool editMode;
  final List<String> names;
  final List<String> descriptions;
  final List<Map<DateTime, int>> valueHistories;
  final Function(int) confirmRemoveDialog;
  final Function(int, int) updateExercise;
  final Function(int, int) reorderExercise;

  @override
  State<ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  var random = Random();

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: widget.valueHistories.length,
        itemBuilder: (context, index) {
          final exercise = widget.names[index];
          final description = widget.descriptions[index];
          final value = widget.valueHistories[index].values.last;
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
                                    widget.confirmRemoveDialog(index);
                                  });
                                }
                              : null,
                        )
                      ])
                    : Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: value <= 0
                              ? null
                              : () {
                                  widget.updateExercise(index, value - 1);
                                },
                        ),
                        SizedBox(
                          width: 22,
                          child: Text(
                            "$value",
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: value >= 100
                              ? null
                              : () {
                                  widget.updateExercise(index, value + 1);
                                },
                        ),
                      ]),
              ));
        },
        onReorder: widget.reorderExercise,
        buildDefaultDragHandles: false);
  }
}
