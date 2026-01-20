import 'package:flutter/material.dart';
import 'dart:async';
import 'package:FitTrack/services/firestore_service.dart';
import 'package:FitTrack/services/quote_service.dart';
import 'package:FitTrack/models/workout_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// IMPORTANT: Add `with TickerProviderStateMixin` here!
// This provides the `vsync` needed for AnimationControllers.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _messageShown = false;

  // Services
  final FirestoreService _firestoreService = FirestoreService();

  // User display name from Firestore
  String _displayName = '';

  // Favorite workouts state
  List<Workout> _favoriteWorkouts = [];
  bool _loadingFavoriteWorkouts = true;
  int _totalFavoriteCount = 0; // Track total number of favorites
  StreamSubscription? _favoritesSubscription;

  // Workout statistics state
  int _todayMinutes = 0;
  int _todayWorkouts = 0;
  int _weeklyWorkouts = 0;
  String? _userId;
  StreamSubscription<QuerySnapshot>? _workoutStatsSubscription;

  // Goals state
  Map<String, dynamic> _userGoals = {};
  StreamSubscription? _goalsSubscription;

  // --- Motivational Quotes from ZenQuotes API ---
  Quote? _currentQuote;
  bool _loadingQuote = true;

  // --- Animation Controllers and Animations ---
  // Declared as `late` because they are initialized in `initState`.

  late AnimationController _statsController;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _statsFadeAnimation;

  late AnimationController _quickStartController;
  late Animation<double> _quickStartScaleAnimation;

  late List<AnimationController> _categoryControllers;
  late List<Animation<double>> _categoryFadeAnimations;
  late List<Animation<Offset>> _categorySlideAnimations;

  void _loadFavoriteWorkouts() {
    setState(() {
      _loadingFavoriteWorkouts = false;
      _favoriteWorkouts = [];
      _totalFavoriteCount = 0;
    });
  }

  Future<void> _loadUserDisplayName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _displayName = userDoc.data()?['username'] ??
                user.displayName ??
                user.email?.split('@').first ??
                'there';
          });
        }
      }
    } catch (e) {
      print('Error loading display name: $e');
    }
  }

  Future<void> _initializeWorkoutStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _todayMinutes = 0;
        _todayWorkouts = 0;
        _weeklyWorkouts = 0;
      });
      return;
    }

    try {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      int todayCount = 0;

      // Count completed workouts for today
      try {
        final workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('completedWorkouts')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
            .get();

        todayCount += workoutsSnapshot.docs.length;
        print('📊 Workouts found: ${workoutsSnapshot.docs.length}');
      } catch (e) {
        print('⚠️ Error querying workouts: $e');
      }

      // Count runs for today - fetch all and filter locally to avoid index issues
      try {
        final runsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('runs')
            .get();

        print('📊 Total runs in collection: ${runsSnapshot.docs.length}');

        for (var doc in runsSnapshot.docs) {
          final data = doc.data();
          DateTime? runStartTime;

          // Handle both Timestamp and String formats
          final startTimeField = data['startTime'];
          if (startTimeField is Timestamp) {
            runStartTime = startTimeField.toDate();
          } else if (startTimeField is String) {
            runStartTime = DateTime.tryParse(startTimeField);
          }

          if (runStartTime != null) {
            print('📊 Run found: ${doc.id}, startTime: $runStartTime');
            if (runStartTime.isAfter(todayStart) &&
                runStartTime.isBefore(todayEnd)) {
              todayCount++;
              print('✅ Run is from today!');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error querying runs: $e');
      }

      if (mounted) {
        setState(() {
          _todayWorkouts = todayCount;
        });
      }

      print('📊 Today\'s total activities: $todayCount');
    } catch (e) {
      print('Error fetching workout stats: $e');
      if (mounted) {
        setState(() {
          _todayMinutes = 0;
          _todayWorkouts = 0;
          _weeklyWorkouts = 0;
        });
      }
    }
  }

  void _initializeUserGoals() {
    setState(() {
      _userGoals = {};
    });
  }

  Future<void> _generateRandomQuote() async {
    setState(() {
      _loadingQuote = true;
    });
    try {
      final quote = await QuoteService.getRandomQuote();
      setState(() {
        _currentQuote = quote;
        _loadingQuote = false;
      });
    } catch (_) {
      setState(() {
        _loadingQuote = false;
      });
    }
  }

  // Refresh method for pull-to-refresh
  Future<void> _refreshHomeData() async {
    print('🔄 Home: Pull-to-refresh triggered');

    // Refresh user display name (in case it was changed in profile)
    await _loadUserDisplayName();

    // Generate a new quote
    _generateRandomQuote();

    // Refresh workout statistics
    await _initializeWorkoutStats();

    // Refresh favorite workouts
    _loadFavoriteWorkouts();

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    print('🔄 Home: Pull-to-refresh completed');
  }

  void _navigateToWorkout(String workoutId, String workoutName) {
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 Starting $workoutName...'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );

    // Navigate to workout detail
    Navigator.pushNamed(
      context,
      '/workoutDetail',
      arguments: workoutId,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.favorite;
      case 'yoga':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.local_fire_department;
      case 'arms':
        return Icons.sports_handball;
      case 'chest':
        return Icons.accessibility_new;
      case 'abs':
        return Icons.grid_on;
      case 'leg':
        return Icons.directions_run;
      case 'back':
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  void initState() {
    // !!! IMPORTANT: Always call super.initState() first !!!
    // This ensures the State object is fully initialized before you
    // attempt to set up late variables or animation controllers.
    super.initState();

    // --- Initialize Animation Controllers and Animations ---

    // Quick Stats Animations
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // Slightly longer
    );
    _statsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));
    _statsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _statsController, curve: Curves.easeIn));

    // Quick Start Card Animation
    _quickStartController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1000), // Longer for a more dramatic bounce
    );
    _quickStartScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _quickStartController,
            curve: Curves.elasticOut)); // Bouncy effect

    // Category Cards Animations (staggered effect)
    _categoryControllers = List.generate(
      4, // Number of category cards (reduced to 4)
      (index) => AnimationController(
        vsync: this,
        // Staggered duration: each card animates slightly after the previous one
        duration: Duration(milliseconds: 800 + index * 100),
      ),
    );
    _categoryFadeAnimations = _categoryControllers
        .map((controller) =>
            Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeIn,
            )))
        .toList();
    _categorySlideAnimations = _categoryControllers
        .map((controller) =>
            Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
                .animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutCubic,
            )))
        .toList();

    // Load favorite workouts
    _loadFavoriteWorkouts();

    // Generate a random motivational quote from ZenQuotes API
    _generateRandomQuote();

    // Initialize workout statistics
    _initializeWorkoutStats();

    // Initialize user goals
    _initializeUserGoals();

    // Load user display name from Firestore
    _loadUserDisplayName();

    // Start all animations shortly after the initial build completes
    // This gives Flutter a moment to lay out the widgets before animating them.
    Future.delayed(const Duration(milliseconds: 200), () {
      _statsController.forward();
      _quickStartController.forward();
      for (var controller in _categoryControllers) {
        controller.forward();
      }
    });
  }

  // --- Handling messages passed via route arguments (e.g., from login) ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_messageShown) {
      // Safely try to get arguments from the current route
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null && message.isNotEmpty) {
        // Schedule the SnackBar to show after the first frame is rendered
        // This prevents "setState() or markNeedsBuild() called during build" errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating, // Modern floating style
              margin: const EdgeInsets.all(16.0), // Margin around the SnackBar
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
            ),
          );
        });
        _messageShown = true; // Prevent showing the message multiple times
      }
    }
  }

  // --- Dispose Animation Controllers to prevent memory leaks ---
  @override
  void dispose() {
    _statsController.dispose();
    _quickStartController.dispose();
    for (var controller in _categoryControllers) {
      controller.dispose(); // Dispose each controller in the list
    }
    _favoritesSubscription?.cancel(); // Cancel favorites subscription
    _workoutStatsSubscription?.cancel(); // Cancel workout stats subscription
    _goalsSubscription?.cancel(); // Cancel goals subscription
    super.dispose(); // Always call super.dispose() last
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current theme is dark for responsive coloring
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // Use _displayName from Firestore, fallback to email if not loaded yet
    String firstName = _displayName.isNotEmpty
        ? _displayName.split(' ').first
        : (user?.email?.split('@').first ?? 'there');

    String _deriveInitial() {
      if (_displayName.isNotEmpty) return _displayName[0].toUpperCase();
      final email = user?.email;
      if (email != null && email.isNotEmpty) return email[0].toUpperCase();
      return 'U';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow under AppBar
        title: Text(
          'FITTRACK',
          style: TextStyle(
            color: Theme.of(context)
                .primaryColor, // Use primary color for branding
            fontWeight: FontWeight.w900, // Heavy weight like splash screen
            fontStyle: FontStyle.italic, // Italic like splash screen
            fontSize: 28, // Slightly larger for app bar
            letterSpacing: 3.0, // Match splash screen spacing
            fontFamily: 'HeadingNow91-98', // Same font as splash screen
            shadows: [
              Shadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: Theme.of(context).brightness == Brightness.dark
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: SafeArea(
        // Ensures content doesn't go under notches/status bar
        child: RefreshIndicator(
          onRefresh: _refreshHomeData,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            // Allows content to scroll if it overflows
            physics:
                const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content doesn't fill screen
            padding: const EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 10.0), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Align children to the start (left)
              children: [
                // Greeting header with avatar
                Padding(
                  padding: const EdgeInsets.only(
                      left: 4.0, right: 4.0, bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hello, $firstName !',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                  onToggleTheme: widget.onToggleTheme),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.9),
                                Theme.of(context).primaryColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: (user?.photoURL != null &&
                                    (user!.photoURL ?? '').isNotEmpty)
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: (user?.photoURL == null ||
                                    (user!.photoURL ?? '').isEmpty)
                                ? Text(
                                    _deriveInitial(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Stats - Single Card for Today's Workouts
                FadeTransition(
                  opacity: _statsFadeAnimation,
                  child: SlideTransition(
                    position: _statsSlideAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _todayWorkouts == 0
                                      ? "You did 0 workouts today"
                                      : 'You did $_todayWorkouts workout${_todayWorkouts == 1 ? '' : 's'} today',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.color ??
                                        (isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _todayWorkouts == 0
                                      ? "Let's start now! 💪"
                                      : 'Keep up the great work! 🔥',
                                  style: TextStyle(
                                    color: Colors.grey[isDarkMode ? 400 : 700],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35), // Increased spacing

                // Motivational Quote Card (with Fade and Slide Animations)
                FadeTransition(
                  opacity: _statsFadeAnimation,
                  child: SlideTransition(
                    position: _statsSlideAnimation,
                    child: GestureDetector(
                      onTap: _generateRandomQuote, // Tap to get a new quote
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [
                                    const Color(0xFF667EEA),
                                    const Color(0xFF764BA2),
                                  ]
                                : [
                                    const Color(0xFF667EEA),
                                    const Color(0xFF764BA2),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Quote icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.format_quote,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quote content
                              if (_loadingQuote)
                                Column(
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading inspiration...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              else if (_currentQuote != null)
                                Column(
                                  children: [
                                    Text(
                                      '"${_currentQuote!.text}"',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 1,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _currentQuote!.author,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 30,
                                          height: 1,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    const Text(
                                      'Welcome back!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ready to crush your fitness goals?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 16),
                              // Tap hint with refresh icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.grey[isDarkMode ? 500 : 600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tap for new inspiration',
                                    style: TextStyle(
                                      color:
                                          Colors.grey[isDarkMode ? 500 : 600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35), // Increased spacing

                // Favourite Workouts - Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Favourite Workouts',
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.headlineMedium?.color ??
                                (isDarkMode ? Colors.white : Colors.black87),
                        fontSize: 22, // Slightly larger
                        fontWeight: FontWeight.w700, // Bolder
                      ),
                    ),
                    // View All button - only show when there are favorites
                    if (!_loadingFavoriteWorkouts &&
                        _favoriteWorkouts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/favourites');
                        },
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          _totalFavoriteCount > 3
                              ? 'View All ($_totalFavoriteCount)'
                              : 'View All',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18), // Slightly increased spacing

                // Favourite Workouts List
                ScaleTransition(
                  scale: _quickStartScaleAnimation,
                  child: _loadingFavoriteWorkouts
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                                strokeWidth: 2,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading your favourite workouts...',
                                style: TextStyle(
                                  color: Colors.grey[isDarkMode ? 400 : 600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _favoriteWorkouts.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () {
                                    // Navigate to browse screen for first workout
                                    Navigator.pushNamed(
                                      context,
                                      '/browse',
                                      arguments: {'initialCategory': 'hiit'},
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.favorite_border,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            size: 36,
                                          ),
                                          Icon(
                                            Icons.explore,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            size: 40,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'No Favourites Yet!',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Explore workouts and add your favorites!',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.black87
                                              : Colors.white70,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _favoriteWorkouts
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                int index = entry.key;
                                Workout workout = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom:
                                          index < _favoriteWorkouts.length - 1
                                              ? 12
                                              : 0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.15)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _navigateToWorkout(
                                          workout.id, workout.name),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _getCategoryIcon(
                                                    workout.category),
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    workout.name,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                              .textTheme
                                                              .headlineMedium
                                                              ?.color ??
                                                          (isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${workout.category} • ${workout.duration} min • ${workout.calories} cal',
                                                    style: TextStyle(
                                                      color: Colors.grey[
                                                          isDarkMode
                                                              ? 400
                                                              : 600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Favourite workout',
                                                    style: TextStyle(
                                                      color: Colors.grey[
                                                          isDarkMode
                                                              ? 500
                                                              : 500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.play_circle_outline,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 28,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ),

                const SizedBox(height: 35), // Increased spacing

                // Workout Categories - Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore Workouts', // More inviting title
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.headlineMedium?.color ??
                                (isDarkMode ? Colors.white : Colors.black87),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // View More button
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/browse');
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        'View More',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Workout Categories Grid (with staggered Fade and Slide Animations)
                GridView.count(
                  shrinkWrap:
                      true, // Takes only as much space as its children need
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevents nested scrolling
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 18, // Spacing between columns
                  mainAxisSpacing: 18, // Spacing between rows
                  childAspectRatio:
                      1.1, // Adjusted aspect ratio for better look
                  children: [
                    // First row
                    FadeTransition(
                      opacity: _categoryFadeAnimations[0],
                      child: SlideTransition(
                        position: _categorySlideAnimations[0],
                        child: _buildCategoryCard(
                          'Strength Training',
                          Icons.fitness_center,
                          Colors.deepOrange,
                          'strength',
                          isDarkMode,
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _categoryFadeAnimations[1],
                      child: SlideTransition(
                        position: _categorySlideAnimations[1],
                        child: _buildCategoryCard(
                          'Cardio Workouts',
                          Icons.favorite,
                          Colors.red,
                          'cardio',
                          isDarkMode,
                        ),
                      ),
                    ),
                    // Second row
                    FadeTransition(
                      opacity: _categoryFadeAnimations[2],
                      child: SlideTransition(
                        position: _categorySlideAnimations[2],
                        child: _buildCategoryCard(
                          'Yoga & Mindfulness',
                          Icons.self_improvement,
                          Colors.lightGreen,
                          'yoga',
                          isDarkMode,
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _categoryFadeAnimations[3],
                      child: SlideTransition(
                        position: _categorySlideAnimations[3],
                        child: _buildCategoryCard(
                          'HIIT Intense',
                          Icons.local_fire_department,
                          Colors.purple,
                          'hiit',
                          isDarkMode,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Padding at the very bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Stat Cards ---
  Widget _buildStatCard(String title, String value, IconData icon,
      Color backgroundColor, Color iconColor, bool isDarkMode) {
    return Container(
      height: 140, // Fixed height to match goal card
      padding: const EdgeInsets.all(20), // More padding
      decoration: BoxDecoration(
        color: backgroundColor, // Background color passed in
        borderRadius: BorderRadius.circular(20), // More rounded
        border:
            Border.all(color: Colors.grey.withOpacity(0.1)), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Distribute space evenly
        children: [
          Icon(icon,
              color: iconColor, size: 28), // Icon with specified color and size
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color ??
                      (isDarkMode ? Colors.white : Colors.black),
                  fontSize: 22, // Larger font
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[isDarkMode ? 400 : 700],
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Category Cards ---
  Widget _buildCategoryCard(String title, IconData icon, Color color,
      String category, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Uses theme's card color
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(
            color: Colors.grey
                .withOpacity(0.15)), // Slightly more prominent border
        // Shadow removed as per request
      ),
      child: Material(
        // Allows InkWell ripple effect
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loading $title workouts...'),
                duration: const Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            // Navigate to browse screen with the specific category pre-selected
            Navigator.pushNamed(
              context,
              '/browse',
              arguments: {'initialCategory': category},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Reduced padding
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically
              children: [
                Container(
                  padding: const EdgeInsets.all(
                      12), // Reduced padding inside icon container
                  decoration: BoxDecoration(
                    color: color.withOpacity(
                        0.15), // Category specific color with opacity
                    borderRadius:
                        BorderRadius.circular(12), // Rounded icon background
                  ),
                  child: Icon(
                    icon,
                    color: color, // Category specific icon color
                    size: 28, // Reduced icon size
                  ),
                ),
                const SizedBox(height: 12), // Reduced spacing
                Flexible(
                  // Added to prevent overflow
                  child: Text(
                    title,
                    textAlign:
                        TextAlign.center, // Center text for better appearance
                    maxLines: 2, // Allow text to wrap to 2 lines
                    overflow:
                        TextOverflow.ellipsis, // Handle overflow gracefully
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.headlineMedium?.color ??
                              (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 15, // Reduced font size
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
