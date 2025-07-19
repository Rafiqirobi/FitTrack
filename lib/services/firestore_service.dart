import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/models/completed_workout_model.dart';
import 'package:FitTrack/models/workout_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save completed workout
  Future<void> saveWorkoutCompletion({
    required Workout workoutDetails,
    required int finalDurationMinutes,
    required int finalCaloriesBurned,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: User not logged in. Cannot save workout completion.');
      return;
    }

    final completedWorkout = CompletedWorkout(
      id: '',
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
      print('Workout completion recorded for user ${user.uid}');
    } catch (e) {
      print('Failed to save workout: $e');
      rethrow;
    }
  }

  // Fetch all available workouts (static template)
  Stream<List<Workout>> getWorkouts() {
    return _db.collection('workouts').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Workout.fromMap(doc.data(), id: doc.id))
          .toList(),
    );
  }

  // ✅ NEW: Fetch completed workouts for the current user
  Stream<List<CompletedWorkout>> getCompletedWorkoutsForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('completed_workouts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CompletedWorkout.fromMap(doc.data(), id: doc.id);
      }).toList();
    });
  }
}
