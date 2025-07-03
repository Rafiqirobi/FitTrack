import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Import your actual screens
import 'home_screen.dart';
import 'browse_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MainScreen({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Screens to show
  final List<Widget> _pages = [
    HomeScreen(),
    BrowseScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  // Bottom nav icons
  final List<IconData> _navIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.magnifyingGlass,
    FontAwesomeIcons.chartBar,
    FontAwesomeIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    final Color neonPrimary = Theme.of(context).primaryColor;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color navBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: neonPrimary),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          )
        ],
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navIcons.length, (index) {
                return _buildNavIcon(
                  icon: _navIcons[index],
                  index: index,
                  selectedColor: neonPrimary,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required int index,
    required Color selectedColor,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: FaIcon(
        icon,
        color: isSelected ? selectedColor : Colors.grey,
        size: 24,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Browse';
      case 2:
        return 'Statistics';
      case 3:
        return 'Profile';
      default:
        return '';
    }
  }
}
