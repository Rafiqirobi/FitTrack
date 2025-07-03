import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String workoutTitle = ModalRoute.of(context)!.settings.arguments as String;
    final Color neonGreen = Color(0xFFCCFF00);
    final Color darkBg = Color(0xFF121212);
    final Color cardBg = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text(workoutTitle),
        backgroundColor: darkBg,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonGreen),
        titleTextStyle: TextStyle(color: neonGreen, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Workout image placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.fitness_center, color: neonGreen, size: 64),
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Description',
              style: TextStyle(
                color: neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This is a detailed description of the $workoutTitle workout. It includes instructions, tips, and benefits to help you perform it effectively.',
              style: TextStyle(color: Colors.grey[400]),
            ),

            SizedBox(height: 24),

            Text(
              'Steps',
              style: TextStyle(
                color: neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),

            // Steps list
            Expanded(
              child: ListView(
                children: [
                  _buildStepCard('Warm up for 5 minutes', neonGreen, cardBg),
                  _buildStepCard('Perform exercise with correct form', neonGreen, cardBg),
                  _buildStepCard('Rest between sets', neonGreen, cardBg),
                  _buildStepCard('Cool down and stretch', neonGreen, cardBg),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String text, Color neonGreen, Color cardBg) {
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: neonGreen),
        title: Text(
          text,
          style: TextStyle(color: Colors.grey[300]),
        ),
      ),
    );
  }
}
