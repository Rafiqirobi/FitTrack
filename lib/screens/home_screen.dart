import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color neonGreen = Color(0xFFCCFF00);
  final Color darkBg = Color(0xFF121212);
  final Color cardBg = Color(0xFF1E1E1E);

  bool _messageShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_messageShown) {
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null && message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        });
        _messageShown = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: darkBg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome to FitTrack!',
              style: TextStyle(
                color: neonGreen,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // Quick Start Card
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  'Quick Start Workout',
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'HIIT • 20 min',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
                trailing: Icon(Icons.play_arrow, color: neonGreen, size: 28),
                onTap: () {
                  // Go to detail screen
                  Navigator.pushNamed(
                    context,
                    '/workoutDetail',
                    arguments: 'Quick Start Workout',
                  );
                },
              ),
            ),

            SizedBox(height: 24),

            // You can add more sections here
            Text(
              'Today\'s Goal',
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
              child: Text(
                'Complete 30 minutes of exercise today!',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
