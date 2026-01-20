import 'package:flutter/material.dart';
import 'package:FitTrack/screens/home_screen.dart';
import 'package:FitTrack/screens/profile_screen.dart';
// Removed Browse screen to match 4-item bottom bar
import 'package:FitTrack/screens/stats_screen.dart';
import 'package:FitTrack/screens/workout_history_screen.dart';
import 'package:FitTrack/widgets/running_active_banner.dart'; // Running active indicator
// Note: Removed dependency on AnimatedBottomBarItem since the design is now custom built.

class NavBottomBar extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const NavBottomBar({super.key, required this.onToggleTheme});

  @override
  State<NavBottomBar> createState() => _NavBottomBarState();
}

class _NavBottomBarState extends State<NavBottomBar>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize controllers for each navigation item (now 4 items)
    _itemControllers = List.generate(
        4,
        (index) => AnimationController(
              duration: const Duration(milliseconds: 200),
              vsync: this,
            ));

    _pages = [
      HomeScreen(onToggleTheme: widget.onToggleTheme),
      const WorkoutHistoryScreen(),
      StatsScreen(onToggleTheme: widget.onToggleTheme),
      ProfileScreen(onToggleTheme: widget.onToggleTheme),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Animate the previously selected item out
      _itemControllers[_selectedIndex].reverse();

      setState(() {
        _selectedIndex = index;
      });

      // Animate the newly selected item in
      _itemControllers[index].forward();
    }
  }

  // Function to navigate to the GPS screen
  void _navigateToGpsScreen() {
    // Simply push the GPS interface - let it handle existing sessions internally
    Navigator.of(context).pushNamed('/gpsInterface');
  }

  // --- NEW Custom Navigation Item Builder Method with Modern Animations ---
  Widget _buildNavItem(int index, IconData unselectedIcon,
      IconData selectedIcon, String label, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    final itemController = _itemControllers[index];

    // Create animations for scale, color, and position
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: itemController,
      curve: Curves.elasticOut,
    ));

    final colorAnimation = ColorTween(
      begin: Theme.of(context).unselectedWidgetColor,
      end: primaryColor,
    ).animate(CurvedAnimation(
      parent: itemController,
      curve: Curves.easeInOut,
    ));

    // Initialize animation state
    if (isSelected && !itemController.isCompleted) {
      itemController.forward();
    } else if (!isSelected && itemController.isCompleted) {
      itemController.reverse();
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          height: 56, // Match container height
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedBuilder(
            animation: itemController,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation.value,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with glow effect when selected
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          isSelected ? selectedIcon : unselectedIcon,
                          color: colorAnimation.value,
                          size: 22,
                        ),
                      ),

                      const SizedBox(height: 1),

                      // Label with fade animation
                      AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          label,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontSize: 9,
                                    height: 1.0,
                                    color: colorAnimation.value,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Modern animated indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        width: isSelected ? 16 : 0,
                        height: isSelected ? 2 : 0,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 3,
                                    spreadRadius: 0.25,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
      // --- Modern FAB with Enhanced Styling ---
      floatingActionButton: Container(
        height: 60, // Reduced size to match navigation bar
        width: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToGpsScreen,
          tooltip: 'Start GPS Tracking',
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.location_on_rounded,
            size: 26, // Slightly smaller icon
            color: Colors.white,
          ),
        ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 0),
        child: Container(
          // Removed vertical margin to prevent overflow
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          height: 56, // Standard height for bottom navigation
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF1E1E1E), // Dark theme base
                      const Color(0xFF2A2A2A), // Slightly lighter dark
                    ]
                  : [
                      Colors.white, // Light theme base
                      Colors.white.withOpacity(0.95), // Slight transparency
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20), // Reduced radius
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.12),
                spreadRadius: 1,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20), // Match container radius
            // Use BottomAppBar for the shape cut-out required by the centerDocked FAB
            child: BottomAppBar(
              elevation: 0, // Elevation handled by the outer Container's shadow
              color: Colors.transparent, // Color handled by the outer Container
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0, // Reduced notch margin
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // Item 0: Home
                  _buildNavItem(0, Icons.home_outlined, Icons.home_rounded,
                      'Home', primaryColor),

                  // Item 1: History
                  _buildNavItem(1, Icons.history_outlined,
                      Icons.history_rounded, 'History', primaryColor),

                  // Spacer for the FAB
                  const SizedBox(width: 56),

                  // Item 2: Stats
                  _buildNavItem(2, Icons.bar_chart_outlined,
                      Icons.bar_chart_rounded, 'Stats', primaryColor),

                  // Item 3: Profile
                  _buildNavItem(3, Icons.person_outline, Icons.person_rounded,
                      'Profile', primaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
