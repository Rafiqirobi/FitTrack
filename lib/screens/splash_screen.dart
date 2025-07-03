import 'package:flutter/material.dart';
import '../helpers/session_manager.dart';


class SplashScreen extends StatelessWidget {
    Future<void> _checkLogin(BuildContext context) async {
    bool isLoggedIn = await SessionManager.getLoginStatus();
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () => _checkLogin(context));
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
