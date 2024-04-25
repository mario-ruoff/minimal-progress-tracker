import 'package:flutter/material.dart';
import 'dart:math';

class ExerciseList extends StatefulWidget {
  const ExerciseList(
      {super.key,
      required this.editMode,
      required this.names,
      required this.descriptions,
      required this.valueHistories,
      required this.exerciseDialog,
      required this.confirmRemoveDialog,
      required this.updateExercise,
      required this.reorderExercise});

  final bool editMode;
  final List<String> names;
  final List<String> descriptions;
  final List<Map<DateTime, int>> valueHistories;
  final Function(BuildContext, int, String, String, bool) exerciseDialog;
  final Function(int) confirmRemoveDialog;
  final Function(int, String, String, int) updateExercise;
  final Function(int, int) reorderExercise;

  @override
  State<ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  final lowerValueLimit = 0;
  final upperValueLimit = 999;

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
              key: Key('$index'),
              child: ListTile(
                leading: widget.editMode
                    ? ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle))
                    : null,
                title: Text(exercise),
                subtitle: Text(description),
                trailing: widget.editMode
                    ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.drive_file_rename_outline),
                          tooltip: 'Rename exercise',
                          onPressed: widget.editMode
                              ? () {
                                  setState(() {
                                    widget.exerciseDialog(context, index, exercise, description, false);
                                  });
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete exercise',
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
                        InkWell(
                            customBorder: const CircleBorder(),
                            onTap: value <= lowerValueLimit
                                ? null
                                : () {
                                    widget.updateExercise(index, exercise, description, value - 1);
                                  },
                            onLongPress: value <= lowerValueLimit + 9
                                ? null
                                : () {
                                    widget.updateExercise(index, exercise, description, value - 10);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.remove,
                                  color: value > lowerValueLimit ? Colors.grey.shade400 : Colors.grey.shade700),
                            )),
                        SizedBox(
                          width: 34,
                          child: Text(
                            value.toString(),
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InkWell(
                            customBorder: const CircleBorder(),
                            onTap: value >= upperValueLimit
                                ? null
                                : () {
                                    widget.updateExercise(index, exercise, description, value + 1);
                                  },
                            onLongPress: value >= upperValueLimit - 9
                                ? null
                                : () {
                                    widget.updateExercise(index, exercise, description, value + 10);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.add,
                                  color: value < upperValueLimit ? Colors.grey.shade400 : Colors.grey.shade700),
                            )),
                      ]),
              ));
        },
        onReorder: widget.reorderExercise,
        buildDefaultDragHandles: false);
  }
}
