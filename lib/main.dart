import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
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
import 'screens/notification_test_screen.dart';
import 'screens/gps_interface_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Seed workout data (run once to populate new workouts)
  // await seedWorkoutData();
  
  runApp(FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  // Light theme configuration
  final ThemeData _neonLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFFF5722), // Orange primary
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF5722), // Orange primary
      secondary: Color(0xFFFF7043), // Light orange
      surface: Colors.white,
      background: Colors.white,
      error: Color(0xFFE53935),
      onPrimary: Colors.white,
      tertiary: Color(0xFFFF8A65), // Lighter orange
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFEEEEEE),
  );

  // Dark theme configuration
  final ThemeData _neonDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFF5722), // Orange primary
    scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Near black
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF5722), // Orange primary
      secondary: Color(0xFFFF7043), // Light orange
      surface: Color(0xFF121212), // Slightly lighter black
      background: Color(0xFF0A0A0A), // Near black
      error: Color(0xFFE53935),
      onPrimary: Colors.white,
      tertiary: Color(0xFFFF8A65), // Lighter orange
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
  );
  ThemeMode _themeMode = ThemeMode.system;

  // Define text themes using Google Fonts
  TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: GoogleFonts.montserrat(
        textStyle: base.headlineLarge,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.montserrat(
        textStyle: base.headlineMedium,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.montserrat(
        textStyle: base.titleLarge,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.roboto(
        textStyle: base.bodyLarge,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.roboto(
        textStyle: base.bodyMedium,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.roboto(
        textStyle: base.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Workout data seeding completed - commenting out to prevent re-running
    //await seedWorkoutData();
    
    // Load theme first before initializing other services
    await _loadTheme();
    
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.initializeNotifications();
    await notificationService.requestPermissions();
    
    // Set up daily motivational quotes at 9 AM
    await notificationService.scheduleMotivationalQuote();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme');
    
    if (isDark == null) {
      // First time launch - set default to dark mode and save it
      setState(() {
        _themeMode = ThemeMode.dark;
      });
      await prefs.setBool('isDarkTheme', true);
    } else {
      // Load saved preference
      setState(() {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isCurrentlyDark = _themeMode == ThemeMode.dark;
    
    // Update UI state
    setState(() {
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
    
    // Save the NEW theme state (opposite of current)
    await prefs.setBool('isDarkTheme', !isCurrentlyDark);
    
    // Debug print to verify saving
    print('🎨 Theme toggled to: ${!isCurrentlyDark ? 'Dark' : 'Light'} mode');
    print('🔄 Saved to SharedPreferences: isDarkTheme = ${!isCurrentlyDark}');
  }

  @override
  Widget build(BuildContext context) {
    // Apply Google Fonts text theme to both light and dark themes
    final lightTheme = _neonLightTheme.copyWith(
      textTheme: _buildTextTheme(_neonLightTheme.textTheme),
    );
    final darkTheme = _neonDarkTheme.copyWith(
      textTheme: _buildTextTheme(_neonDarkTheme.textTheme),
    );

    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/', // Splash screen starts first
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/navBottomBar': (context) => NavBottomBar(onToggleTheme: _toggleTheme),
        '/workoutDetail': (context) => WorkoutDetailScreen(),
        '/browse': (context) => const BrowseScreen(),
        '/workoutTimer': (context) => WorkoutTimerScreen(),
        '/repsScreen': (context) => RepsScreen(),
        '/favourites': (context) => FavouritesScreen(),
        '/notificationTest': (context) => NotificationTestScreen(),
        '/gpsInterface': (context) => const GpsInterfaceScreen(), // <<< NEW ROUTE ADDED
      },
    );
  }
}

// 🎨 Dark Theme (These final definitions outside the class are redundant if used inside, 
// but I'm keeping them to respect your original structure)
final ThemeData neonDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFFF5722),
  scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 29),
  cardColor: const Color(0xFF121212),
  iconTheme: const IconThemeData(color: Color(0xFFFF5722)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFF5722),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(
      color: Color(0xFFFF5722),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0A0A),
    foregroundColor: Color(0xFFFF5722),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0A0A0A),
    selectedItemColor: Color(0xFFFF5722),
    unselectedItemColor: Colors.grey,
    elevation: 8,
  ),
);

// 🎨 Light Theme
final ThemeData neonLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFFFF5722),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  iconTheme: const IconThemeData(color: Color(0xFFFF5722)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFF5722),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
    titleLarge: TextStyle(
      color: Color(0xFFFF5722),
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFFFF5722),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFFFF5722),
    unselectedItemColor: Color(0xFF9E9E9E),
    elevation: 8,
  ),
);