// services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart'; // Make sure this path is correct
import '../models/completed_workout_model.dart'; // Make sure this path is correct

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Method to save a new workout
  Future<void> saveWorkout(Workout workout) async {
    // This method is for saving a 'Workout' model, typically created by an admin or user for future use.
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    final workoutCollection = _db.collection('users').doc(userId).collection('workouts');
    if (workout.id.isEmpty) {
      // Add new workout
      await workoutCollection.add(workout.toMap());
    } else {
      // Update existing workout
      await workoutCollection.doc(workout.id).set(workout.toMap());
    }
  }

  // ✅ ADD THIS NEW METHOD FOR COMPLETED WORKOUTS ✅
  Future<void> saveWorkoutCompletion(CompletedWorkout completedWorkout) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot save workout completion.");
    }

    // Reference the 'completedWorkouts' subcollection under the user's document
    final completedWorkoutsCollection = _db
        .collection('users')
        .doc(userId)
        .collection('completedWorkouts');

    // Add the completed workout to Firestore. Firestore will automatically generate an ID.
    await completedWorkoutsCollection.add(completedWorkout.toMap());
  }

  // You might also have methods to fetch workouts, fetch completed workouts, etc.
  // Example: Stream to get all completed workouts for the current user
  Stream<List<CompletedWorkout>> getCompletedWorkouts() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]); // Return an empty stream if no user
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('completedWorkouts')
        .orderBy('timestamp', descending: true) // Order by latest completed
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompletedWorkout.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  // Example: Stream to get all workouts (not completed ones)
  Stream<List<Workout>> getWorkouts() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromMap(doc.data(), id: doc.id))
            .toList());
  }
}