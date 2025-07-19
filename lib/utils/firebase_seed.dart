import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedWorkoutData() async {
  print('Starting Firebase workout data seeding...');
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final CollectionReference workoutsCollection = firestore.collection('workouts');
  
  // Get all existing workouts to check which ones we need to add
  final QuerySnapshot existingWorkouts = await workoutsCollection.get();
  final Set<String> existingWorkoutNames = existingWorkouts.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .map((data) => '${data['name']}_${data['category']}')
      .toSet();

  print('Found ${existingWorkouts.docs.length} existing workouts.');

final workoutsData = [
  {
    "name": "Bicep Curl",
    "category": "arms",
    "description": "An isolation exercise targeting the biceps.", // Changed from text to description
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
    "description": "Bodyweight movement that targets the triceps.",
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
    "description": "Variation of bicep curl with palms facing in.",
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
    "description": "Classic bodyweight chest exercise.",
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
  
  // 🏋️ STRENGTH CATEGORY WORKOUTS
  {
    "name": "Barbell Bench Press",
    "category": "strength",
    "text": "Compound movement for chest, shoulders, and triceps.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 180,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Lie on bench, grip barbell wider than shoulders, lower to chest with control.",
        "reps": 8,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Press the bar up explosively, fully extending arms at the top.",
        "reps": 8,
        "sets": 4,
        "duration": null
      }
    ]
  },
  {
    "name": "Barbell Squat",
    "category": "strength",
    "text": "King of lower body exercises, works entire leg and core.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 200,
    "restTime": 120,
    "steps": [
      {
        "step": 1,
        "text": "Position barbell on upper back, feet shoulder-width apart.",
        "reps": 6,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Descend by sitting back and down, keep chest up, drive through heels to stand.",
        "reps": 6,
        "sets": 4,
        "duration": null
      }
    ]
  },
  {
    "name": "Overhead Press",
    "category": "strength",
    "text": "Builds shoulder and core strength.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 160,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Hold barbell at shoulder height, feet hip-width apart.",
        "reps": 8,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Press bar straight overhead, lock out arms, lower with control.",
        "reps": 8,
        "sets": 4,
        "duration": null
      }
    ]
  },
  {
    "name": "Romanian Deadlift",
    "category": "strength",
    "text": "Targets hamstrings, glutes, and lower back.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 190,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Hold barbell with overhand grip, feet hip-width apart.",
        "reps": 10,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Hinge at hips, lower bar by pushing hips back, keep back straight.",
        "reps": 10,
        "sets": 4,
        "duration": null
      }
    ]
  },
  {
    "name": "Weighted Dips",
    "category": "strength",
    "text": "Advanced tricep and chest builder.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 170,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Support body on parallel bars, add weight with belt or vest.",
        "reps": 8,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower body until shoulders below elbows, press back up strongly.",
        "reps": 8,
        "sets": 4,
        "duration": null
      }
    ]
  },

  // 🧘 YOGA CATEGORY WORKOUTS
  {
    "name": "Sun Salutation A",
    "category": "yoga",
    "text": "Classic flowing sequence to warm up the entire body.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 60,
    "restTime": 15,
    "steps": [
      {
        "step": 1,
        "text": "Mountain Pose - Stand tall, palms together at heart center.",
        "reps": 0,
        "sets": 1,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Upward Salute - Sweep arms up overhead, slight backbend.",
        "reps": 0,
        "sets": 1,
        "duration": 30
      },
      {
        "step": 3,
        "text": "Forward Fold - Hinge at hips, fold forward, let arms hang.",
        "reps": 0,
        "sets": 1,
        "duration": 30
      },
      {
        "step": 4,
        "text": "Chaturanga - Lower from plank to low push-up position.",
        "reps": 0,
        "sets": 1,
        "duration": 30
      },
      {
        "step": 5,
        "text": "Upward Dog - Open chest, press hands down, lift thighs.",
        "reps": 0,
        "sets": 1,
        "duration": 30
      },
      {
        "step": 6,
        "text": "Downward Dog - Tuck toes, lift hips up and back.",
        "reps": 0,
        "sets": 1,
        "duration": 60
      }
    ]
  },
  {
    "name": "Warrior Flow",
    "category": "yoga",
    "text": "Strengthening sequence for legs and core balance.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 80,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Warrior I - Lunge position, arms overhead, square hips forward.",
        "reps": 0,
        "sets": 2,
        "duration": 45
      },
      {
        "step": 2,
        "text": "Warrior II - Open hips and torso sideways, arms parallel to ground.",
        "reps": 0,
        "sets": 2,
        "duration": 45
      },
      {
        "step": 3,
        "text": "Side Angle - Lower front forearm to thigh, reach top arm over ear.",
        "reps": 0,
        "sets": 2,
        "duration": 45
      }
    ]
  },
  {
    "name": "Backbend Flow",
    "category": "yoga",
    "text": "Heart opening sequence for spine flexibility.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 70,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Cobra Pose - Lie prone, press palms down, lift chest.",
        "reps": 0,
        "sets": 3,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Camel Pose - Kneel, reach back to heels, open chest skyward.",
        "reps": 0,
        "sets": 2,
        "duration": 30
      },
      {
        "step": 3,
        "text": "Bridge Pose - Lie on back, lift hips, press feet down.",
        "reps": 0,
        "sets": 3,
        "duration": 45
      }
    ]
  },
  {
    "name": "Hip Opening Flow",
    "category": "yoga",
    "text": "Releases tension in hips and improves flexibility.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 65,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Pigeon Pose - Bring one knee forward, extend other leg back.",
        "reps": 0,
        "sets": 2,
        "duration": 60
      },
      {
        "step": 2,
        "text": "Figure 4 Stretch - Lie on back, ankle on opposite knee.",
        "reps": 0,
        "sets": 2,
        "duration": 45
      },
      {
        "step": 3,
        "text": "Happy Baby - Lie on back, hold outsides of feet, rock gently.",
        "reps": 0,
        "sets": 1,
        "duration": 60
      }
    ]
  },
  {
    "name": "Core Yoga Flow",
    "category": "yoga",
    "text": "Strengthening flow focusing on abdominal muscles.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 90,
    "restTime": 25,
    "steps": [
      {
        "step": 1,
        "text": "Boat Pose - Sit, lift legs and arms, balance on sit bones.",
        "reps": 0,
        "sets": 3,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Hollow Body Hold - Lie on back, lift shoulders and legs.",
        "reps": 0,
        "sets": 3,
        "duration": 30
      },
      {
        "step": 3,
        "text": "Side Plank - Support body on one arm, stack feet.",
        "reps": 0,
        "sets": 2,
        "duration": 30
      }
    ]
  },

  // 🏃 CARDIO CATEGORY WORKOUTS
  {
    "name": "Running Intervals",
    "category": "cardio",
    "text": "High-intensity running with recovery periods.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 300,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Warm up with 5 minutes easy jogging or walking.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      },
      {
        "step": 2,
        "text": "Sprint at 80-90% effort for 30 seconds.",
        "reps": 0,
        "sets": 8,
        "duration": 30
      },
      {
        "step": 3,
        "text": "Recover with light jogging for 90 seconds between sprints.",
        "reps": 0,
        "sets": 8,
        "duration": 90
      },
      {
        "step": 4,
        "text": "Cool down with 5 minutes easy walking.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      }
    ]
  },
  {
    "name": "Cycling Endurance",
    "category": "cardio",
    "text": "Steady-state cycling for cardiovascular fitness.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 400,
    "restTime": 0,
    "steps": [
      {
        "step": 1,
        "text": "Warm up with 5 minutes easy pedaling.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      },
      {
        "step": 2,
        "text": "Maintain moderate intensity (65-75% max heart rate).",
        "reps": 0,
        "sets": 1,
        "duration": 1800
      },
      {
        "step": 3,
        "text": "Cool down with 5 minutes easy pedaling.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      }
    ]
  },
  {
    "name": "Rowing Workout",
    "category": "cardio",
    "text": "Full-body cardio using rowing machine or boat.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 350,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Warm up with 5 minutes easy rowing.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      },
      {
        "step": 2,
        "text": "Row 500m at moderate-high intensity.",
        "reps": 0,
        "sets": 4,
        "duration": 120
      },
      {
        "step": 3,
        "text": "Rest 2 minutes between each 500m interval.",
        "reps": 0,
        "sets": 4,
        "duration": 120
      }
    ]
  },
  {
    "name": "Stair Climbing",
    "category": "cardio",
    "text": "Vertical cardio challenge for legs and lungs.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 250,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Climb stairs at moderate pace for 2 minutes.",
        "reps": 0,
        "sets": 6,
        "duration": 120
      },
      {
        "step": 2,
        "text": "Walk down slowly for recovery.",
        "reps": 0,
        "sets": 6,
        "duration": 60
      }
    ]
  },
  {
    "name": "Swimming Laps",
    "category": "cardio",
    "text": "Low-impact full-body cardiovascular exercise.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 380,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Warm up with 200m easy freestyle swimming.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      },
      {
        "step": 2,
        "text": "Swim 100m freestyle at moderate pace.",
        "reps": 0,
        "sets": 6,
        "duration": 90
      },
      {
        "step": 3,
        "text": "Rest 30 seconds between each 100m set.",
        "reps": 0,
        "sets": 6,
        "duration": 30
      }
    ]
  },

  // 💥 HIIT CATEGORY WORKOUTS
  {
    "name": "Tabata Burpees",
    "category": "hiit",
    "text": "4-minute high-intensity burpee protocol.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 150,
    "restTime": 10,
    "steps": [
      {
        "step": 1,
        "text": "Perform burpees at maximum intensity for 20 seconds.",
        "reps": 0,
        "sets": 8,
        "duration": 20
      },
      {
        "step": 2,
        "text": "Rest for 10 seconds between each round.",
        "reps": 0,
        "sets": 8,
        "duration": 10
      }
    ]
  },
  {
    "name": "Mountain Climber HIIT",
    "category": "hiit",
    "text": "Explosive core and cardio combination.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 200,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Mountain climbers at maximum speed for 30 seconds.",
        "reps": 0,
        "sets": 6,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Rest 30 seconds between rounds.",
        "reps": 0,
        "sets": 6,
        "duration": 30
      }
    ]
  },
  {
    "name": "Sprint Circuit",
    "category": "hiit",
    "text": "Mixed high-intensity bodyweight movements.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 220,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Jump squats - explosive power for 45 seconds.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      },
      {
        "step": 2,
        "text": "Push-ups - chest and arms for 45 seconds.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      },
      {
        "step": 3,
        "text": "High knees running in place for 45 seconds.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      },
      {
        "step": 4,
        "text": "Rest 45 seconds between each complete circuit.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      }
    ]
  },
  {
    "name": "Kettlebell Swings HIIT",
    "category": "hiit",
    "text": "Explosive hip hinge movement for power and cardio.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 180,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Kettlebell swings - explosive hip drive for 40 seconds.",
        "reps": 0,
        "sets": 6,
        "duration": 40
      },
      {
        "step": 2,
        "text": "Rest 20 seconds between rounds.",
        "reps": 0,
        "sets": 6,
        "duration": 20
      }
    ]
  },
  {
    "name": "Battle Ropes HIIT",
    "category": "hiit",
    "text": "Upper body and core intensive cardio blaster.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 190,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Alternating waves - rapid arm movement for 30 seconds.",
        "reps": 0,
        "sets": 8,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Rest 30 seconds between rounds.",
        "reps": 0,
        "sets": 8,
        "duration": 30
      }
    ]
  },

  // 💪 ADDITIONAL ARMS WORKOUTS (to reach 8 total)
  {
    "name": "Overhead Tricep Extension",
    "category": "arms",
    "description": "Isolation exercise for tricep strength and size.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 85,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Hold dumbbell overhead with both hands, keep elbows close to head.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower weight behind head by bending elbows, then extend back up.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Preacher Curl",
    "category": "arms",
    "description": "Seated bicep exercise using preacher bench for isolation.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 75,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Sit at preacher bench, rest arms on pad, hold barbell with underhand grip.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Curl weight up focusing on bicep contraction, lower slowly.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Diamond Push-Ups",
    "category": "arms",
    "description": "Bodyweight exercise targeting triceps with diamond hand position.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 100,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Get in push-up position with hands forming diamond shape under chest.",
        "reps": 8,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower chest to hands, push back up emphasizing tricep engagement.",
        "reps": 8,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "21s Bicep Curl",
    "category": "arms",
    "description": "Advanced bicep training with partial and full range reps.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 95,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "7 reps bottom half: curl from bottom to halfway point.",
        "reps": 7,
        "sets": 1,
        "duration": null
      },
      {
        "step": 2,
        "text": "7 reps top half: curl from halfway to top.",
        "reps": 7,
        "sets": 1,
        "duration": null
      },
      {
        "step": 3,
        "text": "7 reps full range: complete full curl movement.",
        "reps": 7,
        "sets": 1,
        "duration": null
      }
    ]
  },
  {
    "name": "Close-Grip Push-Up",
    "category": "arms",
    "description": "Push-up variation with hands closer together for tricep focus.",
    "imageUrl": "lib/assets/arm.jpeg",
    "calories": 90,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Position hands shoulder-width apart or closer in push-up position.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower body keeping elbows close to sides, push back up.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },

  // 💪 ADDITIONAL CHEST WORKOUTS (to reach 8 total)
  {
    "name": "Decline Bench Press",
    "category": "chest",
    "description": "Targets lower chest muscles with decline angle.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 120,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Lie on decline bench, grip barbell wider than shoulders.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower bar to lower chest, press up explosively.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Dumbbell Pullover",
    "category": "chest",
    "description": "Chest and lat exercise performed lying on bench.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 95,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Lie on bench, hold dumbbell with both hands overhead.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower weight behind head in arc motion, pull back over chest.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Cable Crossover",
    "category": "chest",
    "description": "Cable exercise for chest isolation and definition.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 110,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Stand between cable machine, grab high pulleys with slight forward lean.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Bring hands together in arc motion, squeeze chest at bottom.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Wide-Grip Push-Up",
    "category": "chest",
    "description": "Push-up variation with wider hand placement for chest emphasis.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 105,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Position hands wider than shoulders in push-up position.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower chest toward ground, push back up focusing on chest.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Chest Dips",
    "category": "chest",
    "description": "Dip variation with forward lean to target chest muscles.",
    "imageUrl": "lib/assets/chest.jpeg",
    "calories": 115,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Support body on parallel bars, lean slightly forward.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower body until shoulders below elbows, press back up.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },

  // 💪 ADDITIONAL ABS WORKOUTS (to reach 8 total)
  {
    "name": "Russian Twists",
    "category": "abs",
    "description": "Rotational core exercise for obliques and abs.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 80,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Sit with knees bent, lean back slightly, lift feet off ground.",
        "reps": 20,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Rotate torso side to side, touching ground beside hips.",
        "reps": 20,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Mountain Climbers",
    "category": "abs",
    "description": "Dynamic core exercise combining cardio and strength.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 120,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Start in plank position, rapidly alternate bringing knees to chest.",
        "reps": 30,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Dead Bug",
    "category": "abs",
    "description": "Core stability exercise performed lying on back.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 65,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Lie on back, arms up, knees bent at 90 degrees.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower opposite arm and leg slowly, return to start.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Bicycle Crunches",
    "category": "abs",
    "description": "Dynamic crunch variation targeting obliques.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 85,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Lie on back, hands behind head, bring opposite elbow to knee.",
        "reps": 20,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Alternate sides in cycling motion, keep core engaged.",
        "reps": 20,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Hollow Body Hold",
    "category": "abs",
    "description": "Isometric core exercise for total abdominal strength.",
    "imageUrl": "lib/assets/abs.jpeg",
    "calories": 70,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Lie on back, press lower back to ground, lift shoulders and legs.",
        "reps": 0,
        "sets": 3,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Hold position creating hollow shape with body.",
        "reps": 0,
        "sets": 3,
        "duration": 30
      }
    ]
  },

  // 🦵 ADDITIONAL LEG WORKOUTS (to reach 8 total)
  {
    "name": "Bulgarian Split Squats",
    "category": "leg",
    "description": "Single-leg squat variation using rear foot elevation.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 140,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Stand 2 feet in front of bench, place rear foot on bench.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lower into lunge until front thigh parallel to ground.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Walking Lunges",
    "category": "leg",
    "description": "Dynamic lunge variation moving forward with each rep.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 130,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Step forward into lunge, push off front foot to next lunge.",
        "reps": 20,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Continue walking forward, alternating legs with each step.",
        "reps": 20,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Wall Sit",
    "category": "leg",
    "description": "Isometric exercise holding squat position against wall.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 90,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Lean back against wall, slide down until thighs parallel to ground.",
        "reps": 0,
        "sets": 3,
        "duration": 45
      },
      {
        "step": 2,
        "text": "Hold position keeping back flat against wall.",
        "reps": 0,
        "sets": 3,
        "duration": 45
      }
    ]
  },
  {
    "name": "Single-Leg Deadlift",
    "category": "leg",
    "description": "Unilateral deadlift for balance and posterior chain strength.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 125,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Stand on one leg, hold dumbbell in opposite hand.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Hinge at hip, lower weight while lifting rear leg for balance.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Jump Squats",
    "category": "leg",
    "description": "Explosive squat variation for power and cardiovascular benefits.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 150,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Perform squat, then explode up jumping as high as possible.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Land softly, immediately descend into next squat.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },

  // 🔙 ADDITIONAL BACK WORKOUTS (to reach 8 total)
  {
    "name": "Lat Pulldown",
    "category": "back",
    "description": "Cable exercise targeting latissimus dorsi muscles.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 125,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "Sit at lat pulldown machine, grab bar wider than shoulders.",
        "reps": 12,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Pull bar down to upper chest, squeeze shoulder blades.",
        "reps": 12,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Renegade Rows",
    "category": "back",
    "description": "Plank position rowing exercise for back and core.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 130,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Start in plank position holding dumbbells.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Row one dumbbell to ribs while maintaining plank.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "T-Bar Row",
    "category": "back",
    "description": "Compound rowing movement using T-bar or landmine setup.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 140,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Straddle T-bar, bend at hips and knees, grab handles.",
        "reps": 10,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Row weight to lower chest, squeeze shoulder blades.",
        "reps": 10,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Face Pulls",
    "category": "back",
    "description": "Cable exercise for rear deltoids and upper back.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 80,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Set cable at face height, grab rope with overhand grip.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Pull rope to face, separate ends toward ears.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },
  {
    "name": "Superman",
    "category": "back",
    "description": "Bodyweight exercise for lower back and glute strength.",
    "imageUrl": "lib/assets/back.jpeg",
    "calories": 70,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Lie face down, extend arms overhead and legs straight.",
        "reps": 15,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Lift chest and legs off ground simultaneously, hold briefly.",
        "reps": 15,
        "sets": 3,
        "duration": null
      }
    ]
  },

  // 💪 ADDITIONAL STRENGTH WORKOUTS (to reach 8 total)
  {
    "name": "Farmers Walk",
    "category": "strength",
    "description": "Functional strength exercise carrying heavy weights.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 200,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Pick up heavy dumbbells or farmers walk handles.",
        "reps": 0,
        "sets": 3,
        "duration": 60
      },
      {
        "step": 2,
        "text": "Walk forward maintaining upright posture for distance/time.",
        "reps": 0,
        "sets": 3,
        "duration": 60
      }
    ]
  },
  {
    "name": "Clean and Press",
    "category": "strength",
    "description": "Olympic lift variation combining clean and overhead press.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 220,
    "restTime": 120,
    "steps": [
      {
        "step": 1,
        "text": "Clean barbell from floor to shoulders in one explosive movement.",
        "reps": 5,
        "sets": 4,
        "duration": null
      },
      {
        "step": 2,
        "text": "Press barbell overhead to full lockout.",
        "reps": 5,
        "sets": 4,
        "duration": null
      }
    ]
  },
  {
    "name": "Turkish Get-Up",
    "category": "strength",
    "description": "Complex full-body movement from lying to standing.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 150,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Lie on back holding weight overhead, perform complex movement to standing.",
        "reps": 5,
        "sets": 3,
        "duration": null
      },
      {
        "step": 2,
        "text": "Reverse movement to return to lying position.",
        "reps": 5,
        "sets": 3,
        "duration": null
      }
    ]
  },

  // 🧘 ADDITIONAL YOGA WORKOUTS (to reach 8 total)
  {
    "name": "Power Yoga Flow",
    "category": "yoga",
    "description": "Dynamic flowing sequence for strength and flexibility.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 100,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Flow through Chaturanga, Upward Dog, Downward Dog sequence.",
        "reps": 0,
        "sets": 5,
        "duration": 45
      },
      {
        "step": 2,
        "text": "Add warrior poses and balance poses between flows.",
        "reps": 0,
        "sets": 5,
        "duration": 45
      }
    ]
  },
  {
    "name": "Restorative Yoga",
    "category": "yoga",
    "description": "Gentle poses for relaxation and stress relief.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 40,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Child's Pose - Kneel and sit back on heels, arms extended forward.",
        "reps": 0,
        "sets": 1,
        "duration": 120
      },
      {
        "step": 2,
        "text": "Legs up the wall - Lie on back with legs up against wall.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      }
    ]
  },
  {
    "name": "Balance Flow",
    "category": "yoga",
    "description": "Challenging poses focusing on stability and concentration.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 75,
    "restTime": 20,
    "steps": [
      {
        "step": 1,
        "text": "Tree Pose - Stand on one leg, place other foot on inner thigh.",
        "reps": 0,
        "sets": 2,
        "duration": 60
      },
      {
        "step": 2,
        "text": "Eagle Pose - Wrap one leg around the other, arms intertwined.",
        "reps": 0,
        "sets": 2,
        "duration": 45
      }
    ]
  },

  // 🏃 ADDITIONAL CARDIO WORKOUTS (to reach 8 total)
  {
    "name": "Elliptical Training",
    "category": "cardio",
    "description": "Low-impact cardio using elliptical machine.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 320,
    "restTime": 0,
    "steps": [
      {
        "step": 1,
        "text": "Warm up for 5 minutes at easy pace.",
        "reps": 0,
        "sets": 1,
        "duration": 300
      },
      {
        "step": 2,
        "text": "Maintain moderate intensity for 20-30 minutes.",
        "reps": 0,
        "sets": 1,
        "duration": 1500
      }
    ]
  },
  {
    "name": "Jump Rope",
    "category": "cardio",
    "description": "High-intensity cardio using jump rope.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 280,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "Jump rope for 2 minutes at steady pace.",
        "reps": 0,
        "sets": 6,
        "duration": 120
      },
      {
        "step": 2,
        "text": "Rest 30 seconds between rounds.",
        "reps": 0,
        "sets": 6,
        "duration": 30
      }
    ]
  },
  {
    "name": "Boxing Cardio",
    "category": "cardio",
    "description": "High-energy boxing movements for cardio fitness.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 350,
    "restTime": 60,
    "steps": [
      {
        "step": 1,
        "text": "Shadowbox with jabs, crosses, hooks for 3 minutes.",
        "reps": 0,
        "sets": 5,
        "duration": 180
      },
      {
        "step": 2,
        "text": "Rest 1 minute between rounds.",
        "reps": 0,
        "sets": 5,
        "duration": 60
      }
    ]
  },

  // 💥 ADDITIONAL HIIT WORKOUTS (to reach 8 total)
  {
    "name": "Bodyweight HIIT Circuit",
    "category": "hiit",
    "description": "No equipment needed high-intensity circuit.",
    "imageUrl": "lib/assets/all.jpeg",
    "calories": 200,
    "restTime": 30,
    "steps": [
      {
        "step": 1,
        "text": "30 seconds each: jumping jacks, burpees, mountain climbers, squat jumps.",
        "reps": 0,
        "sets": 4,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Rest 30 seconds between exercises.",
        "reps": 0,
        "sets": 4,
        "duration": 30
      }
    ]
  },
  {
    "name": "Treadmill HIIT",
    "category": "hiit",
    "description": "High-intensity intervals on treadmill.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 250,
    "restTime": 90,
    "steps": [
      {
        "step": 1,
        "text": "Sprint at high speed for 30 seconds.",
        "reps": 0,
        "sets": 8,
        "duration": 30
      },
      {
        "step": 2,
        "text": "Walk or light jog for 90 seconds recovery.",
        "reps": 0,
        "sets": 8,
        "duration": 90
      }
    ]
  },
  {
    "name": "Plyometric HIIT",
    "category": "hiit",
    "description": "Explosive jumping movements for power and cardio.",
    "imageUrl": "lib/assets/leg.jpeg",
    "calories": 240,
    "restTime": 45,
    "steps": [
      {
        "step": 1,
        "text": "45 seconds each: box jumps, broad jumps, lateral bounds.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      },
      {
        "step": 2,
        "text": "Rest 45 seconds between exercises.",
        "reps": 0,
        "sets": 4,
        "duration": 45
      }
    ]
  },
  
  // Removed duplicate "Bodyweight Squats" and "Lunges" and "Wall Sit" with "difficulty" field,
  // as the request implies a single workout entry per unique exercise name/category combo for simplicity.
  // If you need difficulty levels, we'll need to adjust how workouts are fetched/filtered.
];

  int newWorkoutsAdded = 0;
  for (final workout in workoutsData) {
    final workoutKey = '${workout['name']}_${workout['category']}';
    if (!existingWorkoutNames.contains(workoutKey)) {
      final docRef = workoutsCollection.doc(); // Firestore will auto-generate a unique ID
      batch.set(docRef, workout);
      newWorkoutsAdded++;
    }
  }

  if (newWorkoutsAdded > 0) {
    await batch.commit();
    print('✅ Added $newWorkoutsAdded new workouts. Total categories now include strength, yoga, cardio, and HIIT.');
  } else {
    print('✅ All workout data already exists. No new workouts added.');
  }
}