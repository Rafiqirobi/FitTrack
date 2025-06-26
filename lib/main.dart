import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Roboto'),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/workoutDetail': (context) => WorkoutDetailScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
