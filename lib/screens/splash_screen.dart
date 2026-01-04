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
    Future.delayed(const Duration(seconds: 3), () => _checkLogin());
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

  Future<void> _checkLogin() async {
    bool isLoggedIn = await SessionManager.getLoginStatus();
    print('🚀 SplashScreen: Navigating to ${isLoggedIn ? '/navBottomBar' : '/login'}');
    if (!mounted) return;
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/navBottomBar');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
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

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) // Dark theme background (matches neonDarkTheme)
          : Colors.white, // Light theme background (matches neonLightTheme)
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FitTrack logo with slide from left to center - Using theme colors
              SlideTransition(
                position: _logoSlideAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Text(
                    'FITTRACK',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900, // Heavy weight (91-98 range)
                      fontStyle: FontStyle.italic, // ITALIC like in your logo image
                      color: const Color(0xFFFF5722), // Orange primary color
                      letterSpacing: 3.0,
                      fontFamily: 'HeadingNow91-98', // Updated to use Heading Now 91-98 font
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFF5722).withOpacity(0.5), // Orange shadow
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8), // Reduced gap from 20 to 8
              
              // Description with slide from right to center - Using theme colors
              SlideTransition(
                position: _descriptionSlideAnimation,
                child: FadeTransition(
                  opacity: _descriptionFadeAnimation,
                  child: Text(
                    'YOUR JOURNEY STARTS HERE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // Medium weight
                      fontStyle: FontStyle.italic, // ITALIC to match logo style
                      color: isDarkMode 
                          ? Colors.white70 // Light text for dark mode
                          : Colors.black54, // Dark text for light mode
                      letterSpacing: 1.5,
                      fontFamily: 'HeadingNow91-98', // Updated to use Heading Now 91-98 font
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
