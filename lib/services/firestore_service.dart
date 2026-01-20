import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/workout_model.dart';
import '../models/completed_workout_model.dart';
import '../models/run_route_model.dart';
import '../models/workout_session.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Stream<List<WorkoutSession>> getWorkoutSessions() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    final runsStream = getRunsForCurrentUser().map((runs) => runs.map((run) => RunSession(run)).toList());
    final workoutsStream = getCompletedWorkouts().map((workouts) => workouts.map((workout) => WorkoutRecord(workout)).toList());

    return Rx.combineLatest2(runsStream, workoutsStream, (List<RunSession> runs, List<WorkoutRecord> workouts) {
      final allSessions = <WorkoutSession>[...runs, ...workouts];
      allSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allSessions;
    });
  }

  Future<void> removeFavoriteWorkout(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    await _db.collection('users').doc(userId).collection('favorites').doc(workoutId).delete();
  }

  Future<void> saveWorkout(Workout workout) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    final workoutCollection = _db.collection('users').doc(userId).collection('workouts');
    if (workout.id.isEmpty) {
      await workoutCollection.add(workout.toMap());
    } else {
      await workoutCollection.doc(workout.id).set(workout.toMap());
    }
  }

  Future<void> saveWorkoutCompletion(CompletedWorkout completedWorkout) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot save workout completion.");
    }

    final completedWorkoutsCollection = _db.collection('users').doc(userId).collection('completedWorkouts');
    await completedWorkoutsCollection.add(completedWorkout.toMap());
  }

  Stream<List<CompletedWorkout>> getCompletedWorkouts() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('completedWorkouts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CompletedWorkout.fromMap(doc.data(), id: doc.id)).toList());
  }

  Stream<List<Workout>> getWorkouts() {
    return _db.collection('workouts').snapshots().map((snapshot) => snapshot.docs.map((doc) => Workout.fromMap(doc.data(), id: doc.id)).toList());
  }

  Future<void> toggleWorkoutFavorite(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot toggle favorite status.");
    }

    final favoriteDoc = _db.collection('user_favorites').doc('${userId}_$workoutId');
    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {
      await favoriteDoc.delete();
    } else {
      await favoriteDoc.set({
        'userId': userId,
        'workoutId': workoutId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isWorkoutFavorited(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return false;
    }

    final favoriteDoc = _db.collection('user_favorites').doc('${userId}_$workoutId');
    final docSnapshot = await favoriteDoc.get();
    return docSnapshot.exists;
  }

  Stream<List<Workout>> getFavoriteWorkoutsForCurrentUser() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    return _db.collection('user_favorites').where('userId', isEqualTo: userId).snapshots().asyncMap((favoritesSnapshot) async {
      if (favoritesSnapshot.docs.isEmpty) {
        return <Workout>[];
      }

      final workoutIds = favoritesSnapshot.docs.map((doc) => doc.data()['workoutId'] as String).toList();
      final List<Workout> favoriteWorkouts = [];

      for (String workoutId in workoutIds) {
        try {
          final workoutDoc = await _db.collection('workouts').doc(workoutId).get();
          if (workoutDoc.exists) {
            final workoutData = workoutDoc.data() as Map<String, dynamic>;
            final workout = Workout.fromMap(workoutData, id: workoutDoc.id);
            favoriteWorkouts.add(workout);
          }
        } catch (e) {
          print('Error fetching workout $workoutId: $e');
        }
      }

      return favoriteWorkouts;
    });
  }

  Future<void> saveRun(RunRoute runRoute) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot save run.");
    }

    try {
      await _db.collection('users').doc(userId).collection('runs').doc(runRoute.id).set(runRoute.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RunRoute>> getRunsForCurrentUser() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(userId)
        .collection('runs')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RunRoute.fromMap(doc.data(), id: doc.id)).toList());
  }

  Future<void> deleteRun(String runId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot delete run.");
    }

    try {
      await _db.collection('users').doc(userId).collection('runs').doc(runId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot delete workout.");
    }

    try {
      await _db.collection('users').doc(userId).collection('completedWorkouts').doc(workoutId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllRuns() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot clear runs.");
    }

    try {
      final runs = await _db.collection('users').doc(userId).collection('runs').get();
      for (var doc in runs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllWorkouts() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot clear workouts.");
    }

    try {
      final workouts = await _db.collection('users').doc(userId).collection('completedWorkouts').get();
      for (var doc in workouts.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}