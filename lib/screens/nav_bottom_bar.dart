import 'package:flutter/material.dart';
import 'package:FitTrack/screens/home_screen.dart';
import 'package:FitTrack/screens/profile_screen_cubit.dart';
// Removed Browse screen to match 4-item bottom bar
import 'package:FitTrack/screens/stats_screen_cubit.dart';
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
      StatsScreenCubit(onToggleTheme: widget.onToggleTheme),
      ProfileScreenCubit(onToggleTheme: widget.onToggleTheme),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: colorAnimation.value,
                    size: 26,
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
      // --- Modern FAB without glow ---
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: _navigateToGpsScreen,
          tooltip: 'Start GPS Tracking',
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          shape: const CircleBorder(),
          child: Icon(
            Icons.directions_run,
            size: 26,
            color: isDarkMode ? Colors.black : Colors.white,
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

      // --- Custom Bottom Bar without glow ---
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          height: 56,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28), // Match container radius
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
