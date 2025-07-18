import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedWorkout {
  final String id; // Unique ID for this completed workout record, usually set by Firestore.
  final String userId; // The ID of the user who completed the workout (from Firebase Auth).
  final String workoutId; // The ID of the original Workout model that this completion refers to.
  final String workoutName; // The name of the workout at the time of completion.
  final int actualDurationMinutes; // The actual duration the user spent on this workout (e.g., in minutes).
  final int actualCaloriesBurned; // The actual estimated calories burned by the user during this session.
  final DateTime timestamp; // The exact timestamp when the workout was completed.
  final String workoutCategory; // The category of the workout at the time of completion (e.g., 'Cardio', 'Strength').

  CompletedWorkout({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.actualDurationMinutes,
    required this.actualCaloriesBurned,
    required this.timestamp,
    required this.workoutCategory,
  });

  // Factory constructor to create a CompletedWorkout object from a Firestore document map.
  factory CompletedWorkout.fromMap(Map<String, dynamic> data, {required String id}) {
    return CompletedWorkout(
      id: id, // The document ID from Firestore
      userId: data['userId'] as String? ?? '', // Provide default empty string for null safety
      workoutId: data['workoutId'] as String? ?? '',
      workoutName: data['workoutName'] as String? ?? 'Unknown Workout', // Default name
      actualDurationMinutes: data['actualDurationMinutes'] as int? ?? 0,
      actualCaloriesBurned: data['actualCaloriesBurned'] as int? ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(), // Default to now if null
      workoutCategory: data['workoutCategory'] as String? ?? 'Uncategorized', // Default category
    );
  }

  // Method to convert a CompletedWorkout object into a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'actualDurationMinutes': actualDurationMinutes,
      'actualCaloriesBurned': actualCaloriesBurned,
      'timestamp': Timestamp.fromDate(timestamp), // Convert DateTime to Firestore Timestamp
      'workoutCategory': workoutCategory,
    };
  }
}