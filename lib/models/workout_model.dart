// lib/models/workout_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp if used

class Workout {
  final String id;
  final String name;
  final String description;
  final int duration; // Total estimated duration in minutes
  final int calories; // Estimated calories burned
  final String category;
  final int restTime; // <--- ADD THIS PROPERTY (rest time in seconds between steps)
  final List<Map<String, dynamic>> steps; // <--- ADD THIS PROPERTY (list of workout steps)
  final String? imageUrl; // Optional main image URL

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.calories,
    required this.category,
    required this.restTime, // Add to constructor
    required this.steps,    // Add to constructor
    this.imageUrl,
  });

  // Factory constructor to create a Workout object from a Firestore map
  factory Workout.fromMap(Map<String, dynamic> data, {required String id}) {
    return Workout(
      id: id,
      name: data['name'] ?? 'Untitled Workout',
      description: data['description'] ?? 'No description provided.',
      duration: data['duration'] as int? ?? 0, // Ensure type safety
      calories: data['calories'] as int? ?? 0,   // Ensure type safety
      category: data['category'] ?? 'General',
      restTime: data['restTime'] as int? ?? 0, // <--- IMPORTANT: Ensure restTime is read and cast to int
      // Ensure steps is a List of maps. Firestore often gives List<dynamic>.
      // We explicitly map it to List<Map<String, dynamic>>
      steps: (data['steps'] as List<dynamic>?)
              ?.map((step) => Map<String, dynamic>.from(step))
              .toList() ??
          [],
      imageUrl: data['imageUrl'],
    );
  }

  // Method to convert Workout object to a map for Firestore (useful for saving/updating)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'duration': duration,
      'calories': calories,
      'category': category,
      'restTime': restTime,
      'steps': steps,
      'imageUrl': imageUrl,
      // 'isFavorite': isFavorite, // If you track favorite status in the model
    };
  }
}