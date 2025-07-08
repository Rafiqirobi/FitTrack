import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../widgets/video_player_widget.dart';


class WorkoutDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workout = ModalRoute.of(context)!.settings.arguments as Workout;

    // Neon color theme
    final Color neonGreen = Color(0xFFCCFF00);
    final Color darkBg = Color(0xFF121212);
    final Color cardBg = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text(workout.name),
        backgroundColor: darkBg,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonGreen),
        titleTextStyle: TextStyle(
          color: neonGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Workout image
            Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Image
    Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(workout.imageAsset),
          fit: BoxFit.cover,
        ),
      ),
    ),

    // ✅ Optional Video Section
    if (workout.videoAsset != null) ...[
      SizedBox(height: 24),
      Text(
        'Video Demo',
        style: TextStyle(
          color: neonGreen,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 8),
      Container(
        height: 200,
        child: VideoPlayerWidget(assetPath: workout.videoAsset!),
      ),
    ],
  ],
),


            SizedBox(height: 24),

            // Description header
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
              workout.description,
              style: TextStyle(color: Colors.grey[400]),
            ),

            SizedBox(height: 16),

            // Duration
            Text(
              'Duration: ${workout.duration} seconds',
              style: TextStyle(
                color: neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 24),

            // Steps header
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
            _buildStepCard('Warm up for 5 minutes', neonGreen, cardBg),
            _buildStepCard('Perform exercise with correct form', neonGreen, cardBg),
            _buildStepCard('Rest between sets', neonGreen, cardBg),
            _buildStepCard('Cool down and stretch', neonGreen, cardBg),

            SizedBox(height: 24),

            // Start Workout button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  foregroundColor: darkBg,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.play_arrow),
                label: Text('Start Workout'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/workoutTimer',
                    arguments: workout,
                  );
                },
              ),
            ),
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
