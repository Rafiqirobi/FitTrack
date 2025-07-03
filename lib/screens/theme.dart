import 'package:flutter/material.dart';

const Color neonGreen = Color(0xFFCCFF00);
const Color neonPink = Color(0xFFFF2CCB);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: neonGreen,
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  iconTheme: IconThemeData(color: neonGreen),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: neonGreen,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: neonGreen,
    foregroundColor: Colors.black,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF121212),
    selectedItemColor: neonGreen,
    unselectedItemColor: Colors.grey,
  ),
);

final ThemeData neonDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFFCCFF00),
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  iconTheme: IconThemeData(color: Color(0xFFCCFF00)),
  textTheme: TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFFCCFF00),
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.grey[400]),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFCCFF00),
    elevation: 0,
  ),
);
