import 'package:cloud_firestore/cloud_firestore.dart';

// Store and retreive data from Firestore
class FirestoreService {
  late CollectionReference exercisesQuery;

  Future loadData(var userUid) async {
    // Set firestore user reference and exercises query
    final firestoreUser = FirebaseFirestore.instance.collection('users').doc(userUid);
    exercisesQuery = firestoreUser.collection('exercises');
    List<String> names = [];
    List<String> descriptions = [];
    List<Map<DateTime, int>> valueHistories = [];

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
        names.add(exercise['name']);
        descriptions.add(exercise['description']);

        // Get value history data from firestore
        Map<DateTime, int> historyMap = {};
        final historiesSnapshot = await exerciseSnapshot.reference.collection('valueHistory').orderBy("date").get();
        for (final historySnapshot in historiesSnapshot.docs) {
          final valueHistory = historySnapshot.data();
          historyMap[valueHistory['date'].toDate()] = valueHistory['amount'];
        }
        valueHistories.add(historyMap);
      }
    }
    return (names, descriptions, valueHistories);
  }

  void addExercise(String name, String description, int orderIndex, DateTime date) {
    // Create new exercise document
    exercisesQuery.add({
      'name': name,
      'description': description,
      'orderIndex': orderIndex,
    }).then((final exerciseRef) {
      // Create new value history document
      exerciseRef.collection('valueHistory').add({
        'date': date,
        'amount': 0,
      });
    });
  }

  void removeExercise(int index) async {
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

  void updateName(int index, String name) {
    exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
      exercisesSnapshot.docs[index].reference.update({'name': name});
    });
  }

  void updateDescription(int index, String description) {
    exercisesQuery.orderBy("orderIndex").get().then((final exercisesSnapshot) {
      exercisesSnapshot.docs[index].reference.update({'description': description});
    });
  }

  void updateValue(int index, int newValue, DateTime date) async {
    // Get last date of value history
    final exercisesSnapshot = await exercisesQuery.orderBy("orderIndex").get();
    final exerciseSnapshot = exercisesSnapshot.docs[index];
    final historiesSnapshot = await exerciseSnapshot.reference.collection('valueHistory').orderBy("date").get();
    DateTime lastDate = historiesSnapshot.docs.last.data()['date'].toDate();

    // If last date is today, update amount, else add new value history
    if (lastDate.year == date.year && lastDate.month == date.month && lastDate.day == date.day) {
      historiesSnapshot.docs.last.reference.update({'amount': newValue});
    } else {
      exerciseSnapshot.reference.collection('valueHistory').add({
        'date': date,
        'amount': newValue,
      });
    }
  }

  void reorderExercises(int oldIndex, int newIndex) async {
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
