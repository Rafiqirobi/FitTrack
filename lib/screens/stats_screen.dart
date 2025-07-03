import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  final Color neonGreen = Color(0xFFCCFF00);
  final Color darkBg = Color(0xFF121212);
  final Color cardBg = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Workout Stats'),
        centerTitle: true,
        backgroundColor: darkBg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Weekly Summary Card
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(
                        color: neonGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '🕒 120 mins worked out',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '🔥 780 calories burned',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '✅ 4 sessions completed',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // ✅ Streak
            Text(
              'Your Streak',
              style: TextStyle(
                color: neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  return Column(
                    children: [
                      Text(
                        ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(
                        index < 4 ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: index < 4 ? neonGreen : Colors.grey,
                        size: 24,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
