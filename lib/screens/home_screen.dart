import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<String> workouts = [
    'Jumping Jacks',
    'Push Ups',
    'Plank',
    'Squats',
    'Lunges',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout List'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  workouts[index],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
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
      ),
    );
  }
}
