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
        .snapshots()
        .map((snapshot) {
      // Sort in memory instead of using orderBy to avoid index requirement
      final workouts = snapshot.docs.map((doc) {
        return CompletedWorkout.fromMap(doc.data(), id: doc.id);
      }).toList();
      
      // Sort by timestamp descending
      workouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return workouts;
    });
  }

  // Add/Remove workout to/from favorites
  Future<void> toggleWorkoutFavorite(String workoutId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: User not logged in. Cannot toggle favorite.');
      return;
    }

    final favoriteDoc = await _db
        .collection('user_favorites')
        .where('userId', isEqualTo: user.uid)
        .where('workoutId', isEqualTo: workoutId)
        .get();

    if (favoriteDoc.docs.isEmpty) {
      // Add to favorites
      await _db.collection('user_favorites').add({
        'userId': user.uid,
        'workoutId': workoutId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Workout added to favorites');
    } else {
      // Remove from favorites
      await _db.collection('user_favorites').doc(favoriteDoc.docs.first.id).delete();
      print('Workout removed from favorites');
    }
  }

  // Check if workout is favorited by current user
  Future<bool> isWorkoutFavorited(String workoutId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final favoriteDoc = await _db
        .collection('user_favorites')
        .where('userId', isEqualTo: user.uid)
        .where('workoutId', isEqualTo: workoutId)
        .get();

    return favoriteDoc.docs.isNotEmpty;
  }

  // Get favorite workouts for current user
  Stream<List<Workout>> getFavoriteWorkoutsForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('user_favorites')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncExpand((favoriteSnapshot) async* {
      if (favoriteSnapshot.docs.isEmpty) {
        yield <Workout>[];
        return;
      }

      final workoutIds = favoriteSnapshot.docs
          .map((doc) => doc.data()['workoutId'] as String)
          .toList();

      // If we have more than 10 favorites, take the first 10 to avoid Firestore whereIn limit
      final limitedWorkoutIds = workoutIds.take(10).toList();

      if (limitedWorkoutIds.isEmpty) {
        yield <Workout>[];
        return;
      }

      // Get workout details for each favorited workout ID
      yield* _db
          .collection('workouts')
          .where(FieldPath.documentId, whereIn: limitedWorkoutIds)
          .snapshots()
          .map((workoutSnapshot) {
        return workoutSnapshot.docs.map((doc) {
          return Workout.fromMap(doc.data(), id: doc.id);
        }).toList();
      });
    });
  }
}
