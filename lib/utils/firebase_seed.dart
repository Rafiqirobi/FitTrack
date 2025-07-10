import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedWorkoutData() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final workouts = [ 

  // Chest
  {
    'name': 'Push-Up Blast',
    'description': 'A classic chest-focused workout.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/pushup.jpg',
    'category': 'Chest',
    'steps': [
      'Warm-up with arm circles',
      'Standard push-ups 3x12',
      'Incline push-ups 3x10',
      'Decline push-ups 3x8',
      'Cool down stretch',
    ],
  },
  {
    'name': 'Dumbbell Fly',
    'description': 'Chest opener using dumbbells.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/fly.jpg',
    'category': 'Chest',
    'steps': [
      'Warm-up',
      'Flat dumbbell fly 3x12',
      'Incline dumbbell fly 3x10',
      'Push-up hold 30s',
      'Stretch',
    ],
  },
  {
    'name': 'Bench Press Routine',
    'description': 'Strengthen your chest with bench press variations.',
    'duration': 1200,
    'imageUrl': 'https://yourdomain.com/images/bench.jpg',
    'category': 'Chest',
    'steps': [
      'Warm-up',
      'Flat bench press 4x10',
      'Incline bench press 3x8',
      'Dumbbell press 3x12',
      'Stretch',
    ],
  },
  {
    'name': 'Chest Circuit',
    'description': 'Non-stop chest workout circuit.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/circuit.jpg',
    'category': 'Chest',
    'steps': [
      'Push-ups 20 reps',
      'Chest fly 15 reps',
      'Clap push-ups 10 reps',
      'Rest 60s',
      'Repeat 3 times',
    ],
  },
  {
    'name': 'Resistance Band Chest',
    'description': 'Chest workout using bands.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/band.jpg',
    'category': 'Chest',
    'steps': [
      'Band chest press 3x15',
      'Band fly 3x12',
      'Push-ups 3x10',
      'Cool down',
    ],
  },

  // Arms
  {
    'name': 'Bicep Builder',
    'description': 'Focused on building bicep strength.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/bicep.jpg',
    'category': 'Arm',
    'steps': [
      'Warm-up',
      'Bicep curls 3x12',
      'Hammer curls 3x10',
      'Reverse curls 3x8',
      'Stretch',
    ],
  },
  {
    'name': 'Tricep Tone',
    'description': 'Tricep-focused routine.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/tricep.jpg',
    'category': 'Arm',
    'steps': [
      'Warm-up',
      'Tricep dips 3x10',
      'Overhead extension 3x12',
      'Kickbacks 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'Arm Blast Circuit',
    'description': 'Non-stop circuit for arms.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/armcircuit.jpg',
    'category': 'Arm',
    'steps': [
      'Curls 15 reps',
      'Dips 12 reps',
      'Hammer curls 12 reps',
      'Rest 60s',
      'Repeat 3 times',
    ],
  },
  {
    'name': 'Resistance Band Arms',
    'description': 'Band-based arm workout.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/armband.jpg',
    'category': 'Arm',
    'steps': [
      'Band curls 3x15',
      'Band tricep extension 3x12',
      'Band rows 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'Bodyweight Arm Sculpt',
    'description': 'No equipment arm workout.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/bodyweightarm.jpg',
    'category': 'Arm',
    'steps': [
      'Push-ups 3x15',
      'Dips 3x12',
      'Diamond push-ups 3x8',
      'Stretch',
    ],
  },

  // Abs
  {
    'name': 'Core Crusher',
    'description': 'Intense core workout.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/core.jpg',
    'category': 'Abs',
    'steps': [
      'Plank 1 min',
      'Russian twists 20 reps',
      'Leg raises 15 reps',
      'Mountain climbers 30s',
      'Rest & repeat',
    ],
  },
  {
    'name': 'Ab Circuit',
    'description': 'Non-stop ab circuit.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/abcircuit.jpg',
    'category': 'Abs',
    'steps': [
      'Sit-ups 20 reps',
      'Bicycle crunches 20 reps',
      'Reverse crunches 15 reps',
      'Plank 45s',
      'Rest & repeat',
    ],
  },
  {
    'name': 'Beginner Abs',
    'description': 'Simple moves for core activation.',
    'duration': 600,
    'imageUrl': 'https://yourdomain.com/images/beginnerabs.jpg',
    'category': 'Abs',
    'steps': [
      'Crunches 15 reps',
      'Heel touches 20 reps',
      'Plank 30s',
      'Rest & repeat',
    ],
  },
  {
    'name': 'Plank Challenge',
    'description': 'Hold variations of planks.',
    'duration': 700,
    'imageUrl': 'https://yourdomain.com/images/plank.jpg',
    'category': 'Abs',
    'steps': [
      'Standard plank 1 min',
      'Side plank 30s each side',
      'Plank reach 30s',
      'Rest & repeat',
    ],
  },
  {
    'name': 'HIIT Abs',
    'description': 'High-intensity intervals for abs.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/hiitabs.jpg',
    'category': 'Abs',
    'steps': [
      'High knees 30s',
      'Plank jacks 30s',
      'Mountain climbers 30s',
      'Rest 30s',
      'Repeat 4 times',
    ],
  },

  // Legs
  {
    'name': 'Leg Day Burner',
    'description': 'Intense leg routine.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/legday.jpg',
    'category': 'Legs',
    'steps': [
      'Squats 20 reps',
      'Lunges 20 reps',
      'Jump squats 15 reps',
      'Calf raises 30 reps',
      'Rest & repeat',
    ],
  },
  {
    'name': 'Bodyweight Legs',
    'description': 'No equipment leg workout.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/bodyweightlegs.jpg',
    'category': 'Legs',
    'steps': [
      'Squats 3x15',
      'Reverse lunges 3x12',
      'Wall sit 45s',
      'Stretch',
    ],
  },
  {
    'name': 'Resistance Band Legs',
    'description': 'Bands for added leg resistance.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/bandlegs.jpg',
    'category': 'Legs',
    'steps': [
      'Band squats 3x15',
      'Band lateral walk 3x12',
      'Band leg press 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'HIIT Leg Circuit',
    'description': 'High-intensity leg intervals.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/hiitlegs.jpg',
    'category': 'Legs',
    'steps': [
      'Jump squats 20 reps',
      'Lunges 20 reps',
      'Burpees 10 reps',
      'Rest 60s',
      'Repeat 3 times',
    ],
  },
  {
    'name': 'Leg Strength Builder',
    'description': 'Classic leg strengthening.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/strengthlegs.jpg',
    'category': 'Legs',
    'steps': [
      'Squats 4x12',
      'Deadlifts 3x10',
      'Lunges 3x12',
      'Calf raises 3x20',
      'Stretch',
    ],
  },

  // Back
  {
    'name': 'Pull-up Challenge',
    'description': 'Upper back and arms focus.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/pullup.jpg',
    'category': 'Back',
    'steps': [
      'Pull-ups 3x8',
      'Chin-ups 3x8',
      'Negative pull-ups 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'Band Back Workout',
    'description': 'Bands for back strength.',
    'duration': 800,
    'imageUrl': 'https://yourdomain.com/images/bandback.jpg',
    'category': 'Back',
    'steps': [
      'Band rows 3x15',
      'Band pulldown 3x12',
      'Face pulls 3x12',
      'Stretch',
    ],
  },
  {
    'name': 'Bodyweight Back',
    'description': 'No equipment back routine.',
    'duration': 900,
    'imageUrl': 'https://yourdomain.com/images/bodyweightback.jpg',
    'category': 'Back',
    'steps': [
      'Supermans 3x15',
      'Reverse snow angels 3x12',
      'Y-T-Ws 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'Dumbbell Back Builder',
    'description': 'Using dumbbells for back gains.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/dumbbellback.jpg',
    'category': 'Back',
    'steps': [
      'Bent-over rows 3x12',
      'Single-arm rows 3x12',
      'Reverse fly 3x10',
      'Stretch',
    ],
  },
  {
    'name': 'HIIT Back Circuit',
    'description': 'Intense back-focused circuit.',
    'duration': 1000,
    'imageUrl': 'https://yourdomain.com/images/hiitback.jpg',
    'category': 'Back',
    'steps': [
      'Pull-ups 10 reps',
      'Band rows 20 reps',
      'Supermans 15 reps',
      'Rest 60s',
      'Repeat 3 times',
    ],
  },

];


  final collection = firestore.collection('workouts');

  for (var workout in workouts) {
    final doc = collection.doc();
    batch.set(doc, workout);
  }

  await batch.commit();
  print('Seed data uploaded!');
}
