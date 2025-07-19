import 'package:cloud_firestore/cloud_firestore.dart'; 

class Workout {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int calories;
  final String category;
  final int restTime;
  final List<Map<String, dynamic>> steps;
  final String? imageUrl;

  final Timestamp? createdAt; // ✅ Add this
  final Timestamp? updatedAt; // ✅ Add this

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.calories,
    required this.category,
    required this.restTime,
    required this.steps,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromMap(Map<String, dynamic> data, {required String id}) {
    return Workout(
      id: id,
      name: data['name'] ?? 'Untitled Workout',
      description: data['description'] ?? 'No description provided.',
      duration: data['duration'] as int? ?? 0,
      calories: data['calories'] as int? ?? 0,
      category: data['category'] ?? 'General',
      restTime: data['restTime'] as int? ?? 0,
      steps: (data['steps'] as List<dynamic>?)
              ?.map((step) => Map<String, dynamic>.from(step))
              .toList() ??
          [],
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

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
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // fallback if null
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
