// lib/screens/reps_screen.dart

import 'package:flutter/material.dart';

class RepsScreen extends StatelessWidget {
  static const Color neonGreen = Color(0xFFCCFF00);
  static const Color darkBg = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final workout = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('REPS WORKOUT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: neonGreen),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              workout['name'] ?? 'Workout',
              style: const TextStyle(
                color: neonGreen,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${workout['sets'] ?? 3} Sets x ${workout['reps'] ?? 12} Reps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
