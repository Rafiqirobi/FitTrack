import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/browse_screen.dart';

void main() {
  runApp(FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final isDark = _themeMode == ThemeMode.dark ? false : true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: neonLightTheme,
      darkTheme: neonDarkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => MainScreen(onToggleTheme: _toggleTheme),
        '/profile': (context) => ProfileScreen(),
        '/workoutDetail': (context) => WorkoutDetailScreen(),
        '/browse': (context) => BrowseScreen(),
      },
    );
  }
}

// 🎨 Dark Theme
final ThemeData neonDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFFCCFF00),
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  iconTheme: IconThemeData(color: Color(0xFFCCFF00)),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFCCFF00),
    foregroundColor: Colors.black,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(
      color: Color(0xFFCCFF00),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFCCFF00),
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF121212),
    selectedItemColor: Color(0xFFCCFF00),
    unselectedItemColor: Colors.grey,
  ),
);

// 🎨 Light Theme
final ThemeData neonLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFFF2CCB),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.grey[100],
  iconTheme: IconThemeData(color: Color(0xFFFF2CCB)),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFF2CCB),
    foregroundColor: Colors.white,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    titleLarge: TextStyle(
      color: Color(0xFFFF2CCB),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFFFF2CCB),
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFFFF2CCB),
    unselectedItemColor: Colors.grey,
  ),
);
