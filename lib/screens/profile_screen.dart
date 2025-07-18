import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../helpers/session_manager.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Name
                  Text(
                    'Fitness Enthusiast',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Email
                  Text(
                    'user@fittrack.com',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('7', 'Workouts', context),
                      _buildStatItem('14', 'Days Active', context),
                      _buildStatItem('245', 'Minutes', context),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Profile Options
            _buildSection('Settings', [
              _buildTile(Icons.person_outline, 'Edit Profile', () {}, context),
              _buildTile(Icons.notifications_outlined, 'Notifications', () {}, context),
              _buildTile(Icons.privacy_tip_outlined, 'Privacy', () {}, context),
            ], context),

            SizedBox(height: 20),

            _buildSection('Support', [
              _buildTile(Icons.help_outline, 'Help & Support', () {}, context),
              _buildTile(Icons.feedback_outlined, 'Send Feedback', () {}, context),
              _buildTile(Icons.info_outline, 'About FitTrack', () {}, context),
            ], context),

            SizedBox(height: 30),

            // Logout Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: Icon(Icons.logout),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await AuthService().signOut();
                              await SessionManager.logout();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (_) => false,
                              );
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label, BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String label, VoidCallback onTap, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
