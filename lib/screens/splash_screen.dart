import 'package:flutter/material.dart';
import '../helpers/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _descriptionController;
  
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _descriptionSlideAnimation;
  late Animation<double> _descriptionFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Logo controller - slides from left to center
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Description controller - slides from right to center
    _descriptionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo animations - from left to center
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0), // Start from left
      end: Offset.zero, // End at center
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // Description animations - from right to center
    _descriptionSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0), // Start from right
      end: Offset.zero, // End at center
    ).animate(
      CurvedAnimation(
        parent: _descriptionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _descriptionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _descriptionController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations with staggered timing
    _startAnimations();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 3), () => _navigate());
  }

  void _startAnimations() {
    // Start logo animation immediately
    _logoController.forward();
    
    // Start description animation after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _descriptionController.forward();
      }
    });
  }

  Future<void> _navigate() async {
    bool isFirstTime = await SessionManager.isFirstTime();
    if (!mounted) return;

    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/about');
    } else {
      bool isLoggedIn = await SessionManager.getLoginStatus();
      print('🚀 SplashScreen: Navigating to ${isLoggedIn ? '/navBottomBar' : '/login'}');
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/navBottomBar');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the current theme from context (follows the main app's theme)
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Select logo based on theme:
    // - Dark mode: black logo 
    // - Light mode: white logo
    final logoPath = isDarkMode 
        ? 'lib/assets/fittracklogoblack.png'
        : 'lib/assets/fittracklogowhite.png';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FitTrack logo image with slide and fade animation
              SlideTransition(
                position: _logoSlideAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Image.asset(
                    logoPath,
                    width: 320,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tagline with slide from right to center
              SlideTransition(
                position: _descriptionSlideAnimation,
                child: FadeTransition(
                  opacity: _descriptionFadeAnimation,
                  child: Text(
                    'YOUR JOURNEY STARTS HERE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
