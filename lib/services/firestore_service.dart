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

  // Method to remove a workout from favorites
  Future<void> removeFavoriteWorkout(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in.");
    }

    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(workoutId)
        .delete();
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
    print('🎯 FirestoreService: Starting saveWorkoutCompletion...'); // Debug log
    
    final userId = getCurrentUserId();
    if (userId == null) {
      print('❌ FirestoreService: User not logged in!'); // Debug log
      throw Exception("User not logged in. Cannot save workout completion.");
    }

    print('🎯 FirestoreService: User ID: $userId'); // Debug log
    print('🎯 FirestoreService: Workout name: ${completedWorkout.workoutName}'); // Debug log

    // Reference the 'completedWorkouts' subcollection under the user's document
    final completedWorkoutsCollection = _db
        .collection('users')
        .doc(userId)
        .collection('completedWorkouts');

    print('🎯 FirestoreService: About to save to Firestore...'); // Debug log
    
    // Add the completed workout to Firestore. Firestore will automatically generate an ID.
    await completedWorkoutsCollection.add(completedWorkout.toMap());
    
    print('✅ FirestoreService: Successfully saved workout to Firestore!'); // Debug log
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

  // ✅ ADD FAVORITES METHODS ✅
  
  // Method to toggle workout favorite status
  Future<void> toggleWorkoutFavorite(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception("User not logged in. Cannot toggle favorite status.");
    }

    final favoriteDoc = _db.collection('user_favorites').doc('${userId}_$workoutId');
    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {
      // Remove from favorites
      await favoriteDoc.delete();
      print('Workout removed from favorites');
    } else {
      // Add to favorites
      await favoriteDoc.set({
        'userId': userId,
        'workoutId': workoutId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Workout added to favorites');
    }
  }

  // Method to check if a workout is favorited
  Future<bool> isWorkoutFavorited(String workoutId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      return false;
    }

    final favoriteDoc = _db.collection('user_favorites').doc('${userId}_$workoutId');
    final docSnapshot = await favoriteDoc.get();
    return docSnapshot.exists;
  }

  // Method to get favorite workouts for current user
  Stream<List<Workout>> getFavoriteWorkoutsForCurrentUser() {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    // Get all favorite workout IDs for the current user
    return _db
        .collection('user_favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((favoritesSnapshot) async {
      if (favoritesSnapshot.docs.isEmpty) {
        return <Workout>[];
      }

      // Extract workout IDs from favorites
      final workoutIds = favoritesSnapshot.docs
          .map((doc) => doc.data()['workoutId'] as String)
          .toList();

      // Fetch workout details from the main workouts collection
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
}