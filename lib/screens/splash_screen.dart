import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      body: Center(
        child: Text(
          'FitTrack',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }
}
