// lib/screens/nav_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:FitTrack/screens/home_screen.dart';
import 'package:FitTrack/screens/profile_screen.dart';
import 'package:FitTrack/screens/browse_screen.dart';
import 'package:FitTrack/screens/stats_screen.dart';
import 'package:FitTrack/widgets/animated_bottom_bar_item.dart';

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

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onToggleTheme: widget.onToggleTheme),
      BrowseScreen(onToggleTheme: widget.onToggleTheme),
      StatsScreen(onToggleTheme: widget.onToggleTheme),
      ProfileScreen(onToggleTheme: widget.onToggleTheme),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color homePillColor = isDarkMode ? const Color(0xFFCCFF00) : const Color(0xFFFF2CCB);
    final Color browsePillColor = isDarkMode ? Colors.blueAccent : Colors.lightBlueAccent;
    final Color progressPillColor = isDarkMode ? Colors.purpleAccent : Colors.deepPurpleAccent;
    final Color profilePillColor = isDarkMode ? Colors.orangeAccent : Colors.deepOrangeAccent;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
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
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.black,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: AnimatedBottomBarItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: '',
                  selectedColor: homePillColor,
                  isDarkMode: isDarkMode,
                  isSelected: _selectedIndex == 0,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AnimatedBottomBarItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search,
                  label: '',
                  selectedColor: browsePillColor,
                  isDarkMode: isDarkMode,
                  isSelected: _selectedIndex == 1,
                ),
                label: 'Browse',
              ),
              BottomNavigationBarItem(
                icon: AnimatedBottomBarItem(
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  label: '',
                  selectedColor: progressPillColor,
                  isDarkMode: isDarkMode,
                  isSelected: _selectedIndex == 2,
                ),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: AnimatedBottomBarItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: '',
                  selectedColor: profilePillColor,
                  isDarkMode: isDarkMode,
                  isSelected: _selectedIndex == 3,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
