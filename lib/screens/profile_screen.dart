import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../helpers/session_manager.dart';
import 'about_fittrack_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const ProfileScreen({super.key, this.onToggleTheme});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Loading...';
  String _email = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        setState(() {
          _email = user.email ?? 'No email';
          _username = userDoc.data()?['username'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _username = 'User';
        _email = 'No email';
      });
    }
  }

/*************  ✨ Windsurf Command ⭐  *************/
  /// Displays a confirmation dialog to clear the user's workout history.
  ///
  /// If the user confirms, deletes all documents in the `completedWorkouts`
  /// subcollection for the current user in Firestore. Shows a success or
  /// failure message upon completion. This action is irreversible.

/// *****  7763298c-3272-454d-8775-88ff2ae2088d  ******
  Future<void> _clearWorkoutHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clear Workout History',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Slightly smaller font size
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'Are you sure you want to delete all your workout history? This action cannot be undone.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final batch = FirebaseFirestore.instance.batch();
                    final snapshots = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('completedWorkouts')
                        .get();
                    
                    for (var doc in snapshots.docs) {
                      batch.delete(doc.reference);
                    }
                    
                    await batch.commit();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🗑️ Workout history cleared successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('❌ Failed to clear workout history'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
/*************  ✨ Windsurf Command ⭐  *************/
  /// Displays a dialog for editing the user's profile information.
  ///
  /// The dialog contains text fields for the user to update their username,
  /// email, and optionally, their password. The dialog adapts to the current
  /// theme (dark or light) for styling. Upon confirmation, the inputs are
  /// passed to the `_updateProfile` method. The dialog can be dismissed by
  /// either pressing the 'Cancel' button or saving the changes.

/*******  b62bcae0-00c2-48f6-8906-b95a769492ce  *******/
              child: const Text('Clear History'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final usernameController = TextEditingController(text: _username);
    final emailController = TextEditingController(text: _email);
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                    labelStyle: TextStyle(
                      color: Colors.grey[isDarkMode ? 400 : 600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                    labelStyle: TextStyle(
                      color: Colors.grey[isDarkMode ? 400 : 600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: 'New Password (optional)',
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    labelStyle: TextStyle(
                      color: Colors.grey[isDarkMode ? 400 : 600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[isDarkMode ? 600 : 300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateProfile(
                  usernameController.text,
                  emailController.text,
                  passwordController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(String newUsername, String newEmail, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update username in Firestore
        if (newUsername != _username) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'username': newUsername}, SetOptions(merge: true));
        }
        
        // Update email if changed
        if (newEmail != _email && newEmail.isNotEmpty) {
          await user.updateEmail(newEmail);
        }
        
        // Update password if provided
        if (newPassword.isNotEmpty) {
          await user.updatePassword(newPassword);
        }
        
        // Refresh data
        await _loadUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),

        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
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
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark 
                    ? Icons.light_mode 
                    : Icons.dark_mode,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: Theme.of(context).brightness == Brightness.dark 
                  ? 'Switch to Light Mode' 
                  : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
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
                        const SizedBox(height: 16),
                        
                        // Name
                        Text(
                          _username,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Email
                        Text(
                          _email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Profile Options
                  _buildSection('Settings', [
                    _buildTile(Icons.edit_outlined, 'Edit Profile', _showEditDialog, context),
                    _buildTile(Icons.notifications_outlined, 'Notifications', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationSettingsScreen(),
                        ),
                      );
                    }, context),
                  ], context),

                  const SizedBox(height: 20),

                  _buildSection('Data Management', [
                    _buildTile(Icons.delete_sweep_outlined, 'Clear Workout History', _clearWorkoutHistory, context),
                    _buildTile(Icons.info_outline, 'About FitTrack', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutFitTrackScreen(),
                        ),
                      );
                    }, context),
                  ], context),

                  const SizedBox(height: 30),

                  // Logout Button
                  SizedBox(
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
                      icon: const Icon(Icons.logout),
                      label: const Text(
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
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await AuthService().signOut();
                                    await SessionManager.logout();
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',

/*************  ✨ Windsurf Command ⭐  *************/
/// Builds a section with a title and a list of child widgets.
///
/// The section consists of a title displayed with a specific text style,
/// followed by a container that encapsulates the provided child widgets.
/// The container has a rounded border and a subtle border color.
///
/// Parameters:
/// - `title`: The title text to be displayed at the top of the section.
/// - `children`: A list of widgets that will be placed inside the container.
/// - `context`: The build context used to retrieve theme information for styling.

/*******  ae583069-1d84-4f7f-a297-2fce8eca4d22  *******/

                                      (_) => false,
                                    );
                                  },
                                  child: const Text(

                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
/*************  ✨ Windsurf Command ⭐  *************/
  /// Builds a tile widget with an icon, label, and a forward arrow, wrapped in an InkWell for tap interaction.
  ///
  /// The tile consists of an icon with a colored background, a label text, and a forward arrow. The icon and label
  /// are styled based on the current theme. The entire tile is tappable, triggering the provided onTap callback.
  ///
  /// Parameters:
  /// - `icon`: The icon to display on the left side of the tile.
  /// - `label`: The label text to display next to the icon.
  /// - `onTap`: Callback function to execute when the tile is tapped.
  /// - `context`: The build context used to obtain theme data for styling.

/*******  bb0ff7a7-7959-41dd-b016-1b85ee3315a9  *******/


/*************  ✨ Windsurf Command ⭐  *************/
  /// Builds a single tile with an icon and a label, along with a forward
  /// arrow icon on the right side of the tile.
  ///
  /// The tile is a rounded rectangle with a background color that is
  /// based on the theme's primary color. The icon is displayed on the left
  /// side with a rounded rectangle background that is also based on the
  /// theme's primary color. The label is displayed on the right side with
  /// a font size of 16 and a font weight of 500. The forward arrow icon is
  /// displayed on the right side with a size of 16 and a color of grey[400].
  ///
  /// Parameters:
  ///   - `label`: The label text to be displayed on the right side of the tile.
  ///   - `onTap`: The callback to be executed when the tile is tapped.
  ///   - `context`: The build context used to retrieve theme information for styling.

/*******  7265c093-863a-476d-9746-a2e9fc88e178  *******/                            );

                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
        const SizedBox(height: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 16),
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
