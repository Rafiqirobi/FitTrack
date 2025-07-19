import 'package:flutter/material.dart';
import 'dart:async';
import 'package:FitTrack/services/firestore_service.dart';
import 'package:FitTrack/services/quote_service.dart';
import 'package:FitTrack/models/workout_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/models/completed_workout_model.dart';

// Ensure your main.dart or app setup includes a MaterialApp
// with defined themes (light and dark) for primaryColor, scaffoldBackgroundColor,
// cardColor, and textTheme to see the full effect.
// Example:
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'FitTrack App',
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.grey[50],
//         cardColor: Colors.white,
//         textTheme: TextTheme(
//           headlineLarge: TextStyle(color: Colors.black87),
//           headlineMedium: TextStyle(color: Colors.black87),
//         ),
//         appBarTheme: AppBarTheme(
//           iconTheme: IconThemeData(color: Colors.black87),
//         ),
//       ),
//       darkTheme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.grey[900],
//         cardColor: Colors.grey[850],
//         textTheme: TextTheme(
//           headlineLarge: TextStyle(color: Colors.white),
//           headlineMedium: TextStyle(color: Colors.white),
//         ),
//         appBarTheme: AppBarTheme(
//           iconTheme: IconThemeData(color: Colors.white),
//         ),
//       ),
//       themeMode: ThemeMode.system, // Or ThemeMode.dark / ThemeMode.light for testing
//       initialRoute: '/',
//       routes: {
//         '/': (context) => HomeScreen(),
//         '/workoutDetail': (context) => WorkoutDetailScreen(), // Replace with your actual screens
//         '/browse': (context) => BrowseWorkoutsScreen(),       // Replace with your actual screens
//       },
//     );
//   }
// }


class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const HomeScreen({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// IMPORTANT: Add `with TickerProviderStateMixin` here!
// This provides the `vsync` needed for AnimationControllers.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _messageShown = false;
  
  // Services
  final FirestoreService _firestoreService = FirestoreService();
  
  // Favorite workouts state
  List<Workout> _favoriteWorkouts = [];
  bool _loadingFavoriteWorkouts = true;
  int _totalFavoriteCount = 0; // Track total number of favorites
  StreamSubscription? _favoritesSubscription;
  
  // Workout statistics state
  int _todayMinutes = 0;
  int _weeklyWorkouts = 0;
  String? _userId;
  StreamSubscription<QuerySnapshot>? _workoutStatsSubscription;

  // --- Motivational Quotes from ZenQuotes API ---
  Quote? _currentQuote;
  bool _loadingQuote = true;

  // --- Animation Controllers and Animations ---
  // Declared as `late` because they are initialized in `initState`.

  late AnimationController _headerController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  late AnimationController _statsController;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _statsFadeAnimation;

  late AnimationController _quickStartController;
  late Animation<double> _quickStartScaleAnimation;

  late List<AnimationController> _categoryControllers;
  late List<Animation<double>> _categoryFadeAnimations;
  late List<Animation<Offset>> _categorySlideAnimations;



  void _loadFavoriteWorkouts() {
    // Cancel existing subscription if any
    _favoritesSubscription?.cancel();
    
    setState(() {
      _loadingFavoriteWorkouts = true;
    });

    _favoritesSubscription = _firestoreService.getFavoriteWorkoutsForCurrentUser().listen(
      (workouts) {
        if (mounted) {
          setState(() {
            _totalFavoriteCount = workouts.length; // Store total count
            _favoriteWorkouts = workouts.take(3).toList(); // Take only the 3 most recent favorites
            _loadingFavoriteWorkouts = false;
          });
          print('Loaded ${workouts.length} favorite workouts');
        }
      },
      onError: (error) {
        print('Error loading favorite workouts: $error');
        if (mounted) {
          setState(() {
            _loadingFavoriteWorkouts = false;
          });
        }
      },
    );
  }

  // Initialize workout statistics with real-time listeners
  Future<void> _initializeWorkoutStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      print('🔄 Home: Setting up workout stats listener for user: $_userId');
      await _setupWorkoutStatsListener();
    } else {
      print('❌ Home: User not logged in, cannot load workout stats');
    }
  }

  // Set up real-time listener for workout statistics
  Future<void> _setupWorkoutStatsListener() async {
    if (_userId == null) return;

    try {
      // Cancel any existing subscription
      await _workoutStatsSubscription?.cancel();

      // Set up real-time listener for completed workouts
      _workoutStatsSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('completedWorkouts')
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          if (mounted) {
            _processWorkoutStats(snapshot);
          }
        },
        onError: (error) {
          print('❌ Home: Error in workout stats listener: $error');
        },
      );
    } catch (e) {
      print('❌ Home: Error setting up workout stats listener: $e');
    }
  }

  // Process workout statistics from Firestore
  void _processWorkoutStats(QuerySnapshot snapshot) {
    if (!mounted) return;

    print('🔄 Home: Processing ${snapshot.docs.length} completed workout documents');

    List<CompletedWorkout> completedWorkouts = snapshot.docs
        .map((doc) => CompletedWorkout.fromMap(
            doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();

    print('🔄 Home: Successfully parsed ${completedWorkouts.length} completed workouts');

    // Calculate today's total minutes
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime endOfToday = startOfToday.add(const Duration(days: 1));

    print('🔄 Home: Today calculation - Start: $startOfToday, End: $endOfToday, Now: $today');

    int todayMinutes = 0;
    for (var workout in completedWorkouts) {
      bool isToday = (workout.timestamp.isAfter(startOfToday) || workout.timestamp.isAtSameMomentAs(startOfToday)) &&
                     workout.timestamp.isBefore(endOfToday);
      
      if (isToday) {
        todayMinutes += workout.actualDurationMinutes;
        print('🔄 Home: Workout included in today - ${workout.workoutName}: ${workout.actualDurationMinutes} min at ${workout.timestamp}');
      }
    }

    // Calculate this week's workouts
    int currentDay = today.weekday; // 1 for Monday, 7 for Sunday
    DateTime startOfWeek = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: currentDay - 1)); // Start of current week (Monday)
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7)); // Start of next week

    print('🔄 Home: Week calculation - Start: $startOfWeek, End: $endOfWeek, Today: $today');

    int weeklyWorkouts = 0;
    for (var workout in completedWorkouts) {
      // Use isAtSameMomentAs or comparisons that include boundaries
      bool isInCurrentWeek = (workout.timestamp.isAfter(startOfWeek) || workout.timestamp.isAtSameMomentAs(startOfWeek)) &&
                            workout.timestamp.isBefore(endOfWeek);
      
      if (isInCurrentWeek) {
        weeklyWorkouts++;
        print('🔄 Home: Workout included in week count - ${workout.workoutName} at ${workout.timestamp}');
      }
    }

    print('🔄 Home: Total completed workouts in dataset: ${completedWorkouts.length}');
    print('🔄 Home: Workouts this week: $weeklyWorkouts');

    setState(() {
      _todayMinutes = todayMinutes;
      _weeklyWorkouts = weeklyWorkouts;
    });

    print('🔄 Home: Stats updated - Today: ${_todayMinutes} min, This week: ${_weeklyWorkouts} workouts');
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
    } catch (e) {
      print('Error generating quote: $e');
      setState(() {
        _loadingQuote = false;
      });
    }
  }

  // Refresh method for pull-to-refresh
  Future<void> _refreshHomeData() async {
    print('🔄 Home: Pull-to-refresh triggered');
    
    // Generate a new quote
    _generateRandomQuote();
    
    // Refresh workout statistics
    await _initializeWorkoutStats();
    
    // Refresh favorite workouts
    _loadFavoriteWorkouts();
    
    // Small delay for better UX
    await Future.delayed(Duration(milliseconds: 500));
    
    print('🔄 Home: Pull-to-refresh completed');
  }

  void _navigateToWorkout(String workoutId, String workoutName) {
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 Starting $workoutName...'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.0),
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

    // Header Animations (Welcome back! text)
    _headerController = AnimationController(
      vsync: this, // `this` refers to the TickerProviderStateMixin
      duration: const Duration(milliseconds: 800),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Starts slightly below its final position
      end: Offset.zero,            // Ends at its natural position
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic, // Smooth deceleration
    ));
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeIn)); // Fades in

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
      duration: const Duration(milliseconds: 1000), // Longer for a more dramatic bounce
    );
    _quickStartScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _quickStartController, curve: Curves.elasticOut)); // Bouncy effect

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

    // Start all animations shortly after the initial build completes
    // This gives Flutter a moment to lay out the widgets before animating them.
    Future.delayed(const Duration(milliseconds: 200), () {
      _headerController.forward();
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
              margin: EdgeInsets.all(16.0), // Margin around the SnackBar
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
    _headerController.dispose();
    _statsController.dispose();
    _quickStartController.dispose();
    for (var controller in _categoryControllers) {
      controller.dispose(); // Dispose each controller in the list
    }
    _favoritesSubscription?.cancel(); // Cancel favorites subscription
    _workoutStatsSubscription?.cancel(); // Cancel workout stats subscription
    super.dispose(); // Always call super.dispose() last
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current theme is dark for responsive coloring
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow under AppBar
        title: Text(
          'FitTrack',
          style: TextStyle(
            color: Theme.of(context).primaryColor, // Use primary color for branding
            fontWeight: FontWeight.bold,
            fontSize: 26, // Slightly larger
            letterSpacing: 1.2, // Adds a subtle, modern touch
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
      body: SafeArea( // Ensures content doesn't go under notches/status bar
        child: RefreshIndicator(
          onRefresh: _refreshHomeData,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).cardColor,
          child: SingleChildScrollView( // Allows content to scroll if it overflows
            physics: AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content doesn't fill screen
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Adjusted padding
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
                children: [
              // Welcome header (with Fade and Slide Animations)
              FadeTransition(
                opacity: _headerFadeAnimation,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: GestureDetector(
                    onTap: _generateRandomQuote, // Tap to get a new quote
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_loadingQuote)
                            CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                              strokeWidth: 2,
                            )
                          else if (_currentQuote != null)
                            Column(
                              children: [
                                Text(
                                  '"${_currentQuote!.text}"',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.headlineLarge?.color ?? (isDarkMode ? Colors.white : Colors.black),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '- ${_currentQuote!.author}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else
                            Text(
                              'Welcome back, Fitness Enthusiast!',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.headlineLarge?.color ?? (isDarkMode ? Colors.white : Colors.black),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition( // Apply animation to the second line of text as well
                opacity: _headerFadeAnimation,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: Text(
                    'Tap the quote above for daily inspiration!', // Updated hint about tapping for new quotes
                    style: TextStyle(
                      color: Colors.grey[isDarkMode ? 400 : 700], // Adjust color for dark mode
                      fontSize: 15, // Slightly smaller to accommodate the hint
                    ),
                    textAlign: TextAlign.center, // Center align to match the main title
                  ),
                ),
              ),
              SizedBox(height: 35), // Increased spacing

              // Quick Stats Row (with Fade and Slide Animations)
              FadeTransition(
                opacity: _statsFadeAnimation,
                child: SlideTransition(
                  position: _statsSlideAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Today\'s Goal',
                          '$_todayMinutes min',
                          Icons.flag_outlined,
                          Theme.of(context).primaryColor.withOpacity(0.15), // Slightly more opaque background
                          Theme.of(context).primaryColor, // Icon color matches primary
                          isDarkMode,
                        ),
                      ),
                      SizedBox(width: 18), // Slightly increased spacing
                      Expanded(
                        child: _buildStatCard(
                          'This Week',
                          '$_weeklyWorkouts workouts',
                          Icons.calendar_today_outlined,
                          Colors.orange.withOpacity(0.15),
                          Colors.orange, // Icon color matches orange
                          isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 35), // Increased spacing

              // Favourite Workouts - Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favourite Workouts',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color ?? (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 22, // Slightly larger
                      fontWeight: FontWeight.w700, // Bolder
                    ),
                  ),
                  // View All button - only show when there are favorites
                  if (!_loadingFavoriteWorkouts && _favoriteWorkouts.isNotEmpty)
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
                        _totalFavoriteCount > 3 ? 'View All (${_totalFavoriteCount})' : 'View All',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 18), // Slightly increased spacing

              // Favourite Workouts List
              ScaleTransition(
                scale: _quickStartScaleAnimation,
                child: _loadingFavoriteWorkouts
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 16),
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
                            padding: EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.7),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.favorite_border,
                                          color: isDarkMode ? Colors.black : Colors.white,
                                          size: 36,
                                        ),
                                        Icon(
                                          Icons.explore,
                                          color: isDarkMode ? Colors.black : Colors.white,
                                          size: 40,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'No Favourites Yet!',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.black : Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Explore workouts and add your favorites!',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.black87 : Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: _favoriteWorkouts.asMap().entries.map((entry) {
                              int index = entry.key;
                              Workout workout = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: index < _favoriteWorkouts.length - 1 ? 12 : 0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _navigateToWorkout(workout.id, workout.name),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(workout.category),
                                              color: Theme.of(context).primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  workout.name,
                                                  style: TextStyle(
                                                    color: Theme.of(context).textTheme.headlineMedium?.color ?? (isDarkMode ? Colors.white : Colors.black87),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${workout.category} • ${workout.duration} min • ${workout.calories} cal',
                                                  style: TextStyle(
                                                    color: Colors.grey[isDarkMode ? 400 : 600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Favourite workout',
                                                  style: TextStyle(
                                                    color: Colors.grey[isDarkMode ? 500 : 500],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.play_circle_outline,
                                            color: Theme.of(context).primaryColor,
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

              SizedBox(height: 35), // Increased spacing

              // Workout Categories - Section Title
              Text(
                'Explore Workouts', // More inviting title
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color ?? (isDarkMode ? Colors.white : Colors.black87),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 18),

              // Workout Categories Grid (with staggered Fade and Slide Animations)
              GridView.count(
                shrinkWrap: true, // Takes only as much space as its children need
                physics: NeverScrollableScrollPhysics(), // Prevents nested scrolling
                crossAxisCount: 2, // 2 cards per row
                crossAxisSpacing: 18, // Spacing between columns
                mainAxisSpacing: 18, // Spacing between rows
                childAspectRatio: 1.1, // Adjusted aspect ratio for better look
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

              SizedBox(height: 20), // Padding at the very bottom
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
      padding: EdgeInsets.all(20), // More padding
      decoration: BoxDecoration(
        color: backgroundColor, // Background color passed in
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(color: Colors.grey.withOpacity(0.1)), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28), // Icon with specified color and size
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color ??
                  (isDarkMode ? Colors.white : Colors.black),
              fontSize: 22, // Larger font
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[isDarkMode ? 400 : 700],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Category Cards ---
  Widget _buildCategoryCard(
      String title, IconData icon, Color color, String category, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Uses theme's card color
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(color: Colors.grey.withOpacity(0.15)), // Slightly more prominent border
        // Shadow removed as per request
      ),
      child: Material( // Allows InkWell ripple effect
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loading $title workouts...'),
                duration: Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.0),
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
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
              children: [
                Container(
                  padding: EdgeInsets.all(12), // Reduced padding inside icon container
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15), // Category specific color with opacity
                    borderRadius: BorderRadius.circular(12), // Rounded icon background
                  ),
                  child: Icon(
                    icon,
                    color: color, // Category specific icon color
                    size: 28, // Reduced icon size
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                Flexible( // Added to prevent overflow
                  child: Text(
                    title,
                    textAlign: TextAlign.center, // Center text for better appearance
                    maxLines: 2, // Allow text to wrap to 2 lines
                    overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color ??
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