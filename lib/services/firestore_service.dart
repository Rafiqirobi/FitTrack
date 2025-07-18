import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/models/completed_workout_model.dart'; // Adjust import path
import 'package:FitTrack/models/workout_model.dart'; // Adjust import path


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to save a completed workout record to Firestore
  Future<void> saveWorkoutCompletion({
    required Workout workoutDetails, // The original workout object template
    required int finalDurationMinutes, // The actual duration user spent in minutes
    required int finalCaloriesBurned, // The actual calories user burned
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: User not logged in. Cannot save workout completion.');
      return;
    }

    final completedWorkout = CompletedWorkout(
      id: '', // Firestore will assign this ID upon adding the document
      userId: user.uid,
      workoutId: workoutDetails.id,
      workoutName: workoutDetails.name,
      actualDurationMinutes: finalDurationMinutes,
      actualCaloriesBurned: finalCaloriesBurned,
      timestamp: DateTime.now(),
      workoutCategory: workoutDetails.category,
    );

    try {
      await _db.collection('completed_workouts').add(completedWorkout.toMap());
      print('Workout completion recorded successfully for user ${user.uid}!');
    } catch (e) {
      print('Failed to record workout completion: $e');
      rethrow; // Re-throw the error to be handled by the calling UI if necessary
    }
  }

  // Example: Function to fetch all workouts (your existing workout list)
  // This is typically used for the workout selection screen
  Stream<List<Workout>> getWorkouts() {
    return _db.collection('workouts').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Workout.fromMap(doc.data(), id: doc.id)).toList());
  }

  // You can add more Firestore-related functions here (e.g., getting user goals, specific workout details)
}