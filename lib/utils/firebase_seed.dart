import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedWorkoutData() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final rawWorkouts = [
    {
      'name': 'Push-Up Power',
      'description': 'Classic push-up routine for chest strength.',
      'category': 'Chest',
      'imageUrl': 'https://yourdomain.com/images/pushup.jpg',
      'reps': 12,
      'sets': 3,
      'duration': null,
      'steps': [
        'Warm-up arm circles',
        'Standard push-ups',
        'Incline push-ups',
        'Stretch'
      ],
    },
    {
      'name': 'Chest Plank Hold',
      'description': 'Plank variation focusing on chest stability.',
      'category': 'Chest',
      'imageUrl': 'https://yourdomain.com/images/plankchest.jpg',
      'reps': null,
      'sets': null,
      'duration': 45,
      'steps': [
        'Standard plank',
        'Side plank',
        'Rest'
      ],
    },
    // Add ALL your other workouts here unchanged...
  ];

  final List<Map<String, dynamic>> processedWorkouts = [];

  for (final workout in rawWorkouts) {
    final steps = workout['steps'] as List<dynamic>;
    final totalDuration = workout['duration'];
    final reps = workout['reps'];
    final sets = workout['sets'];

    final List<Map<String, dynamic>> detailedSteps = [];

    if (totalDuration != null) {
      // Time-based: split equally
      final int splitDuration = (totalDuration as int) ~/ steps.length;
      for (final stepName in steps) {
        detailedSteps.add({
          'name': stepName,
          'duration': splitDuration,
          'reps': null,
          'sets': null,
        });
      }
    } else if (reps != null && sets != null) {
      // Reps-based
      for (final stepName in steps) {
        detailedSteps.add({
          'name': stepName,
          'duration': null,
          'reps': reps,
          'sets': sets,
        });
      }
    } else {
      // Neither? Default steps
      for (final stepName in steps) {
        detailedSteps.add({
          'name': stepName,
          'duration': null,
          'reps': null,
          'sets': null,
        });
      }
    }

    processedWorkouts.add({
      'name': workout['name'],
      'description': workout['description'],
      'category': workout['category'],
      'imageUrl': workout['imageUrl'],
      'steps': detailedSteps,
    });
  }

  // Upload to Firestore
  final collection = firestore.collection('workouts');
  for (final workout in processedWorkouts) {
    final doc = collection.doc();
    batch.set(doc, workout);
  }

  await batch.commit();
  print('✅ Seed data uploaded with per-step reps/sets/time!');
}
