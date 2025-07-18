import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedWorkoutData() async {
  print('Starting Firebase workout data seeding...');
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final CollectionReference workoutsCollection = firestore.collection('workouts');
  // Check if any workout data already exists to prevent re-seeding on every app restart
  final QuerySnapshot existingWorkouts = await workoutsCollection.limit(1).get();

  if (existingWorkouts.docs.isNotEmpty) {
    print('Workout data already exists. Skipping seeding.');
    return;
  }

final workoutsData = [
  {
    "name": "Bicep Curl",
    "category": "arms",
    "text": "An isolation exercise targeting the biceps.", // Changed from description to text
    "imageUrl": "lib/assets/arm.jpeg", // Local asset path
    "calories": 80, // Added calories
    "restTime": 30, // Added rest time
    "steps": [
      {
        "step": 1,
        "text": "Hold dumbbells at your sides with palms facing forward.",
        "reps": 12,
        "sets": 3,
        "duration": null // Null for rep-based exercises
      },
      {
        "step": 2,
        "text": "Curl the dumbbells up towards your shoulders while keeping elbows still.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Tricep Dip",
    "category": "arms",
    "text": "Bodyweight movement that targets the triceps.",
    "imageUrl": "lib/assets/arm.jpeg", // Local asset path
    "calories": 90,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Place hands on a bench or elevated surface behind you, fingers facing forward.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower your body by bending your elbows until your triceps are parallel to the floor, then push back up.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Hammer Curl",
    "category": "arms",
    "text": "Variation of bicep curl with palms facing in.",
    "imageUrl": "lib/assets/arm.jpeg", // Local asset path
    "calories": 85,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Hold dumbbells with palms facing your body (neutral grip).",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Curl the dumbbells up while maintaining the neutral grip.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Push-Up",
    "category": "chest",
    "text": "Classic bodyweight chest exercise.",
    "imageUrl": "lib/assets/chest.jpeg", // Local asset path
    "calories": 110,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Place hands slightly wider than shoulders in a plank position, keeping your body straight.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower your chest towards the floor by bending your elbows, then push back up to the starting position.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Chest Fly",
    "category": "chest",
    "text": "Targets pectoral muscles using dumbbells.",
    "imageUrl": "lib/assets/chest.jpeg", // Local asset path
    "calories": 100,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Lie on a flat bench, hold dumbbells above your chest with a slight bend in your elbows.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower your arms out wide to your sides, feeling a stretch in your chest, then bring them back together.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Incline Press",
    "category": "chest",
    "text": "Focuses on upper chest muscles.",
    "imageUrl": "lib/assets/chest.jpeg", // Local asset path
    "calories": 105,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Sit on an incline bench, holding dumbbells at chest level with palms facing forward.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Press the dumbbells upward and together until your arms are fully extended.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Crunches",
    "category": "abs",
    "text": "Strengthens upper abdominal muscles.",
    "imageUrl": "lib/assets/abs.jpeg", // Local asset path
    "calories": 70,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Lie on your back with knees bent and feet flat on the floor, hands lightly behind your head.",
        "reps": 20,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lift your shoulders off the floor, squeezing your abs, then slowly lower back down.",
        "reps": 20,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Plank",
    "category": "abs",
    "text": "Core stabilization exercise.",
    "imageUrl": "lib/assets/abs.jpeg", // Local asset path
    "calories": 60,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Hold a forearm plank position with your body in a straight line from head to heels.",
        "reps": 0,
        "sets": 3,
        "duration": 60 // Duration-based
      }
    ]
  },
  {
    "name": "Leg Raises",
    "category": "abs",
    "text": "Targets lower abdominal region.",
    "imageUrl": "lib/assets/abs.jpeg", // Local asset path
    "calories": 75,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Lie flat on your back, keep legs straight and lift them upward together until perpendicular to the floor.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower your legs slowly without letting them touch the floor, then repeat.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Squats",
    "category": "leg", // Changed from "legs" to "leg" for consistency with asset naming
    "text": "Fundamental lower-body movement.",
    "imageUrl": "lib/assets/leg.jpeg", // Local asset path
    "calories": 130,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Stand with feet shoulder-width apart, lower your hips as if sitting in a chair, keeping your back straight.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Lunges",
    "category": "leg", // Changed from "legs" to "leg"
    "text": "Works glutes, quads, and hamstrings.",
    "imageUrl": "lib/assets/leg.jpeg", // Local asset path
    "calories": 120,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Step forward with one leg and lower your body until both knees are bent at a 90-degree angle.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Calf Raises",
    "category": "leg", // Changed from "legs" to "leg"
    "text": "Targets calf muscles.",
    "imageUrl": "lib/assets/leg.jpeg", // Local asset path
    "calories": 50,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Stand tall and slowly raise your heels off the ground, engaging your calf muscles.",
        "reps": 20,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Deadlift",
    "category": "back",
    "text": "Full-body move focusing on posterior chain.",
    "imageUrl": "lib/assets/back.jpeg", // Local asset path
    "calories": 150,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Hinge at your hips and knees to lift a barbell or dumbbells from the ground, keeping your back straight.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Pull-Up",
    "category": "back",
    "text": "Bodyweight exercise for back and biceps.",
    "imageUrl": "lib/assets/back.jpeg", // Local asset path
    "calories": 140,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Hang from a pull-up bar with an overhand grip, pull your chest towards the bar.",
        "reps": 8,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Bent Over Row",
    "category": "back",
    "text": "Targets upper and mid-back muscles.",
    "imageUrl": "lib/assets/back.jpeg", // Local asset path
    "calories": 135,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Hinge forward at your hips, keeping your back straight, and row a barbell or dumbbells to your torso.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  // Removed duplicate "Bodyweight Squats" and "Lunges" and "Wall Sit" with "difficulty" field,
  // as the request implies a single workout entry per unique exercise name/category combo for simplicity.
  // If you need difficulty levels, we'll need to adjust how workouts are fetched/filtered.
];

  for (final workout in workoutsData) {
    final docRef = workoutsCollection.doc(); // Firestore will auto-generate a unique ID
    batch.set(docRef, workout);
  }


  

  await batch.commit();
  print('✅ Seeded 15 flat workouts with updated keys and durations.');
}