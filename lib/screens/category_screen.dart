import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final Map<String, String> categories = {
    'Abs': '🔥 Abs Workouts',
    'Legs': '🏋️ Legs Workouts',
    'Chest': '💪 Chest Workouts',
    'Arms': '🦾 Arms Workouts',
    'Back': '🧱 Back Workouts',
    'Shoulders': '🧍 Shoulders Workouts',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise Categories')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: categories.entries.map((entry) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/workouts',
                arguments: entry.key,
              );
            },
            child: Card(
              color: Colors.green.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
