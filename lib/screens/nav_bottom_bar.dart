import 'package:flutter/material.dart';
import 'package:FitTrack/screens/home_screen.dart';
import 'package:FitTrack/screens/profile_screen.dart';
import 'package:FitTrack/screens/browse_screen.dart';
import 'package:FitTrack/screens/stats_screen.dart';
import 'package:FitTrack/screens/run_history_screen.dart';
import 'package:FitTrack/widgets/running_active_banner.dart'; // Running active indicator
// Note: Removed dependency on AnimatedBottomBarItem since the design is now custom built.

class NavBottomBar extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const NavBottomBar({super.key, required this.onToggleTheme});

  @override
  State<NavBottomBar> createState() => _NavBottomBarState();
}

class _NavBottomBarState extends State<NavBottomBar> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to navigate to the GPS screen
  void _navigateToGpsScreen() {
    Navigator.of(context).pushNamed('/gpsInterface');
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onToggleTheme: widget.onToggleTheme),
      BrowseScreen(onToggleTheme: widget.onToggleTheme),
      const RunHistoryScreen(),
      StatsScreen(onToggleTheme: widget.onToggleTheme),
      ProfileScreen(onToggleTheme: widget.onToggleTheme),
    ];
  }

  // --- NEW Custom Navigation Item Builder Method to mimic the image design ---
  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    // Unselected color uses the theme's unselected color for consistency
    final color = Theme.of(context).unselectedWidgetColor;
    
    // Icon and label color is the primary color if selected, or the unselected color otherwise
    final itemColor = isSelected ? primaryColor : color;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        // Use a fixed height and center alignment to create a consistent tap area
        child: Container(
          height: 55, 
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: itemColor,
                size: 22,
              ),
              
              // Label
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 10,
                  color: itemColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),

              // Selection Indicator (Small Pill/Dot - located *under* the label, matching the image)
              Container(
                width: isSelected ? 15 : 0, // Make it a small pill length
                height: isSelected ? 3 : 0,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(top: 2), // Small gap above the indicator
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // --- FAB (Central Item) ---
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToGpsScreen,
        tooltip: 'Start GPS Tracking',
        child: const Icon(Icons.location_on_rounded, size: 30),
      ),
      // Position the FAB centrally above the custom bottom bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --------------------------

      body: Column(
        children: [
          // 🏃 Running Active Banner (appears at top when running)
          RunningActiveBanner(
            onTap: _navigateToGpsScreen, // Return to GPS screen when tapped
          ),
          
          // Main page content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),

      // --- Custom Bottom Bar Implementation using BottomAppBar for FAB docking ---
      bottomNavigationBar: Container(
        // Retain the margin for the floating effect
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          // Use BottomAppBar for the shape cut-out required by the centerDocked FAB
          child: BottomAppBar(
            elevation: 0, // Elevation handled by the outer Container's shadow
            color: Colors.transparent, // Color handled by the outer Container
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0, // Increased margin to make the FAB float lower relative to the bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Item 0: Home
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', primaryColor),
                
                // Item 1: Browse (Search)
                _buildNavItem(1, Icons.search_outlined, Icons.search, 'Browse', primaryColor),

                // Spacer for the FAB (Note: the CircularNotchedRectangle handles most of the space)
                const SizedBox(width: 20), 

                // Item 2: Run History (Trophy/Medal)
                _buildNavItem(2, Icons.history_outlined, Icons.history, 'History', primaryColor),
                
                // Item 3: Stats (Bar Chart)
                _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats', primaryColor),
                
                // Item 4: Profile (Person)
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile', primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}