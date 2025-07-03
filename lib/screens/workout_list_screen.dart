import 'package:flutter/material.dart';
import '../models/workout_model.dart';

class WorkoutListScreen extends StatelessWidget {
  final Map<String, List<Workout>> categoryWorkouts = {
  'Abs': [
    Workout(
      name: 'Crunches',
      imageAsset: 'assets/images/crunches.gif',
      description: 'Lie on your back and crunch up.',
      duration: 30,
    ),
    // add more...
  ],
  'Cardio': [
    Workout(
      name: 'High Knees',
      imageAsset: 'assets/images/high_knees.gif',
      description: 'Run in place with knees high.',
      duration: 45,
    ),
  ],
  // add other categories...
};


  @override
  Widget build(BuildContext context) {
    final String category = ModalRoute.of(context)!.settings.arguments as String;
    final workouts = categoryWorkouts[category] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('$category Workouts')),
      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(workouts[index].name),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/workoutDetail',
                  arguments: workouts[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
