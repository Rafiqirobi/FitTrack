import 'package:flutter/material.dart';
import '../helpers/session_manager.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () => _checkLogin());
  }

  Future<void> _checkLogin() async {
    bool isLoggedIn = await SessionManager.getLoginStatus();
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              'FitTrack'.toUpperCase(),
              style: TextStyle(
                fontSize: 48,
                fontFamily: 'Roboto', 
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
