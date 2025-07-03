import 'package:flutter/material.dart';
import '../helpers/session_manager.dart';

class ProfileScreen extends StatelessWidget {
  final String studentName = 'Rafiqi';
  final int age = 21;
  final String email = 'rafiqi@student.edu';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            SizedBox(height: 20),
            Text(studentName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Age: $age', style: TextStyle(fontSize: 18)),
            Text(email, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 30),
            Divider(),
            ListTile(
              leading: Icon(Icons.fitness_center, color: Colors.green),
              title: Text('Total Workouts: 5'),
            ),
            ListTile(
              leading: Icon(Icons.timer, color: Colors.green),
              title: Text('Total Time: 45 mins'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Back to Home'),
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await SessionManager.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Logout'),
            )

          ],
        ),
      ),
    );
  }
}
