import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String workoutName = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text(workoutName)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workoutName,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'This exercise helps improve your fitness and strength.\n\n'
              '✅ Recommended:\n- 3 sets of 10 reps\n- Or hold for 30 seconds\n\n'
              '💡 Tip: Stay hydrated and rest between sets.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
