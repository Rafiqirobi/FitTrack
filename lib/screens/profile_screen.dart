import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Color neonGreen = Color(0xFFCCFF00);
  final Color darkBg = Color(0xFF121212);
  final Color cardBg = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text(''),
        centerTitle: true,
        backgroundColor: darkBg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // ✅ Avatar + Name
            CircleAvatar(
              radius: 40,
              backgroundColor: neonGreen,
              child: Icon(Icons.person, size: 40, color: darkBg),
            ),
            SizedBox(height: 12),
            Text(
              'Afiq FitStudent',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'afiq@example.com',
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 32),

            // ✅ Profile Options
            _buildTile(Icons.settings, 'Settings'),
            _buildTile(Icons.help_outline, 'Help & Support'),
            _buildTile(Icons.info_outline, 'About App'),

            Spacer(),

            // ✅ Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: darkBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String label) {
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: neonGreen),
        title: Text(label, style: TextStyle(color: Colors.white)),
        trailing: Icon(Icons.arrow_forward_ios, color: neonGreen, size: 16),
        onTap: () {
          // Navigate or do something
        },
      ),
    );
  }
}
