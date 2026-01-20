import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';

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
import 'screens/about_fittrack_screen.dart';
import 'screens/workout_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Remove seeding from main - do it only on first app run or when needed
  // seedWorkoutData() should be called from a dedicated screen/method when user navigates, not on startup

  runApp(const FitTrackApp());
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  // Light theme configuration - White background with Black accents
  final ThemeData _neonLightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black, // Black primary
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black, // Black primary
      secondary: Color(0xFF424242), // Dark grey
      surface: Colors.white,
      background: Colors.white,
      error: Color(0xFFE53935),
      onPrimary: Colors.white,
      tertiary: Color(0xFF616161), // Medium grey
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFEEEEEE),
  );

  // Dark theme configuration - Black background with White accents
  final ThemeData _neonDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white, // White primary
    scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Near black
    colorScheme: const ColorScheme.dark(
      primary: Colors.white, // White primary
      secondary: Color(0xFFE0E0E0), // Light grey
      surface: Color(0xFF121212), // Slightly lighter black
      background: Color(0xFF0A0A0A), // Near black
      error: Color(0xFFE53935),
      onPrimary: Colors.black,
      tertiary: Color(0xFFBDBDBD), // Medium grey
      onSecondary: Colors.black,
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
    // Load theme first (quick local operation)
    await _loadTheme();

    // Lazy initialize notifications in background - don't block UI
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.initializeNotifications();
        await notificationService.requestPermissions();
        await notificationService.scheduleMotivationalQuote();
      } catch (e) {
        print('⚠️ Notification init failed: $e');
      }
    });
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
        '/': (context) => const SplashScreen(),
        '/about': (context) => const AboutFitTrackScreen(),
        '/login': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return LoginScreen(initialEmail: email);
        },
        '/register': (context) => const RegisterScreen(),
        '/navBottomBar': (context) => NavBottomBar(onToggleTheme: _toggleTheme),
        '/workoutDetail': (context) => const WorkoutDetailScreen(),
        '/browse': (context) => const BrowseScreen(),
        '/workoutTimer': (context) => const WorkoutTimerScreen(),
        '/repsScreen': (context) => const RepsScreen(),
        '/favourites': (context) => const FavouritesScreen(),
        '/notificationTest': (context) => const NotificationTestScreen(),
        '/gpsInterface': (context) => const GpsInterfaceScreen(),
        '/workoutHistory': (context) => const WorkoutHistoryScreen(),
      },
    );
  }
}

// 🎨 Dark Theme - Black background with White accents
final ThemeData neonDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 29),
  cardColor: const Color(0xFF121212),
  iconTheme: const IconThemeData(color: Colors.white),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0A0A),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0A0A0A),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey,
    elevation: 8,
  ),
);

// 🎨 Light Theme - White background with Black accents
final ThemeData neonLightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.black),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
    titleLarge: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.black,
    unselectedItemColor: Color(0xFF9E9E9E),
    elevation: 8,
  ),
);
