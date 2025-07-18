// lib/main_app_shell.dart
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import your existing HomeScreen

// Create placeholder pages for your other tabs.
// You will replace these with your actual workout, progress, and profile screens.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Workouts')),
      body: const Center(child: Text('This is your Workouts Page content.')),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: const Center(child: Text('This is your Progress Page content.')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: const Center(child: Text('This is your Profile Page content.')),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  // This list holds all the main pages of your app that the bottom nav will switch between.
  final List<Widget> _pages = [
    HomeScreen(),     // Your existing HomeScreen
    const WorkoutsScreen(),  // Placeholder for Workouts page
    const ProgressScreen(),  // Placeholder for Progress page
    const ProfileScreen(),   // Placeholder for Profile page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current theme is dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors for selected items based on theme (you can adjust these)
    final Color homeColor = isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFFEDE9FE); // Primary Purple
    final Color workoutsColor = isDarkMode ? const Color(0xFFEC4899) : const Color(0xFFFCE7F3); // Pink
    final Color progressColor = isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFFFFBEB); // Orange
    final Color profileColor = isDarkMode ? const Color(0xFF2DD4BF) : const Color(0xFFE0F2F7); // Teal

    // Define text/icon color for selected items (contrasting with background)
    final Color selectedIconTextColor = isDarkMode ? Colors.black : Colors.black87; // Changed to black for light selected bg
    final Color unselectedItemColor = isDarkMode ? Colors.white54 : Colors.grey[700]!;


    return Scaffold(
      // The `AppBar` for the *currently selected page* will be provided by
      // the `_pages` widget itself (e.g., your HomeScreen already has one).
      // So, this top-level Scaffold does NOT have an AppBar.
      body: _pages[_selectedIndex], // Displays the currently selected page
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A202C) : Colors.white, // Dark background or White background
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent, // Make it transparent so the Container color shows
            elevation: 0, // Remove default elevation
            type: BottomNavigationBarType.fixed, // Use fixed type for custom styling
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: selectedIconTextColor,
            unselectedItemColor: unselectedItemColor,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            showSelectedLabels: true,
            showUnselectedLabels: false, // Show labels only for selected items, as per design

            items: <BottomNavigationBarItem>[
              _buildNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                index: 0,
                color: homeColor,
                isDarkMode: isDarkMode,
              ),
              _buildNavItem(
                icon: Icons.fitness_center_outlined, // Icon for Workouts
                selectedIcon: Icons.fitness_center,
                label: 'Browse',
                index: 1,
                color: workoutsColor,
                isDarkMode: isDarkMode,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined, // Icon for Progress
                selectedIcon: Icons.bar_chart,
                label: 'Statistics',
                index: 2,
                color: progressColor,
                isDarkMode: isDarkMode,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                index: 3,
                color: profileColor,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required Color color,
    required bool isDarkMode,
  }) {
    final bool isSelected = _selectedIndex == index;

    // Determine the text/icon color for the content *inside* the pill
    Color contentColor;
    if (isSelected) {
      // If selected, determine color based on background (color) and theme.
      // A common pattern is white text on dark background pills, and dark text on light background pills.
      // This logic tries to ensure good contrast.
      if (isDarkMode) {
        contentColor = Colors.black; // Text/icon on the colored pill in dark mode
      } else {
        contentColor = Colors.black87; // Text/icon on the colored pill in light mode
      }
    } else {
      // If unselected, use the theme's unselected color
      contentColor = isDarkMode ? Colors.white54 : Colors.grey[700]!;
    }

    return BottomNavigationBarItem(
      icon: Container(
        height: 40, // Height of the background shape
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: isSelected
            ? BoxDecoration(
                color: color, // The unique color for each selected tab
                borderRadius: BorderRadius.circular(20), // Half of height for pill shape
              )
            : null, // No background when not selected
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: contentColor, // Apply the determined content color
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: contentColor, // Apply the determined content color
                ),
              ),
            ],
          ],
        ),
      ),
      label: label, // This label is used by Flutter for accessibility and fallback, but we hide unselected.
    );
  }
}