import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'utils/firebase_seed.dart'; // Workout seeding completed

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/workout_timer_screen.dart';
import 'screens/reps_screen.dart';
import 'screens/favourites_screen.dart';
import 'screens/nav_bottom_bar.dart'; // Main navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Seed workout data (run once to populate new workouts)
  // await seedWorkoutData();
  
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Workout data seeding completed - commenting out to prevent re-running
    //await seedWorkoutData();
    await _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
    await prefs.setBool('isDarkTheme', !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: neonLightTheme,
      darkTheme: neonDarkTheme,
      initialRoute: '/', // Splash screen starts first
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/navBottomBar': (context) => NavBottomBar(onToggleTheme: _toggleTheme),
        '/workoutDetail': (context) => WorkoutDetailScreen(),
        '/browse': (context) => BrowseScreen(),
        '/workoutTimer': (context) => WorkoutTimerScreen(),
        '/repsScreen': (context) => RepsScreen(),
        '/favourites': (context) => FavouritesScreen(),
      },
    );
  }
}

// 🎨 Dark Theme
final ThemeData neonDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFCCFF00),
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  iconTheme: const IconThemeData(color: Color(0xFFCCFF00)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFCCFF00),
    foregroundColor: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(
      color: Color(0xFFCCFF00),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFCCFF00),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF121212),
    selectedItemColor: Color(0xFFCCFF00),
    unselectedItemColor: Colors.grey,
  ),
);

// 🎨 Light Theme
final ThemeData neonLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFFFF2CCB),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.grey[200],
  iconTheme: const IconThemeData(color: Color(0xFFFF2CCB)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFF2CCB),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    titleLarge: TextStyle(
      color: Color(0xFFFF2CCB),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFFFF2CCB),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFFFF2CCB),
    unselectedItemColor: Colors.grey,
  ),
);
