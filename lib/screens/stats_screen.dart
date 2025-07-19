import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:FitTrack/models/completed_workout_model.dart'; // Adjust import path as needed
import 'package:FitTrack/services/goal_service.dart';

// Rank system based on total workouts completed
class Rank {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredWorkouts;
  final int maxWorkouts;

  Rank({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredWorkouts,
    required this.maxWorkouts,
  });
}

// IMPORTANT: Ensure Firebase is initialized in your main.dart file like this:
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Make sure firebase_options.dart is generated and imported
  );
  runApp(const MyApp()); // Replace MyApp with your root widget
}
*/

class StatsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const StatsScreen({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _totalWorkouts = 0;
  int _caloriesBurned = 0;
  int _totalMinutes = 0;
  List<int> _weeklyWorkouts = List.filled(7, 0); // 0=Mon, ..., 6=Sun
  List<CompletedWorkout> _allCompletedWorkouts = []; // Stores all fetched workouts for calculations
  bool _isLoading = true;
  String? _userId;
  
  // Rank system variables
  Rank? _currentRank;
  Rank? _nextRank;
  
  // Goals variables
  Map<String, dynamic> _userGoals = {};
  StreamSubscription? _goalsSubscription;
  
  // Real-time listener for auto-updates
  StreamSubscription<QuerySnapshot>? _workoutDataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchData();
  }

  // Define rank tiers based on total workout count
  List<Rank> _getRankTiers() {
    return [
      Rank(
        title: 'Beginner',
        description: 'Starting your fitness journey',
        icon: Icons.fitness_center,
        color: Colors.grey,
        requiredWorkouts: 0,
        maxWorkouts: 9,
      ),
      Rank(
        title: 'Warrior',
        description: 'Showing dedication and consistency',
        icon: Icons.local_fire_department,
        color: Colors.green,
        requiredWorkouts: 10,
        maxWorkouts: 24,
      ),
      Rank(
        title: 'Elite',
        description: 'Advanced fitness enthusiast',
        icon: Icons.military_tech,
        color: Colors.blue,
        requiredWorkouts: 25,
        maxWorkouts: 49,
      ),
      Rank(
        title: 'Master',
        description: 'Fitness master with exceptional commitment',
        icon: Icons.emoji_events,
        color: Colors.deepOrange,
        requiredWorkouts: 50,
        maxWorkouts: 99,
      ),
      Rank(
        title: 'Legend',
        description: 'Ultimate fitness legend',
        icon: Icons.stars,
        color: Colors.purple,
        requiredWorkouts: 100,
        maxWorkouts: 999,
      ),
    ];
  }

  // Calculate current rank based on total workout count
  void _calculateRank() {
    final rankTiers = _getRankTiers();
    
    _currentRank = null;
    _nextRank = null;
    
    for (int i = 0; i < rankTiers.length; i++) {
      Rank rank = rankTiers[i];
      if (_totalWorkouts >= rank.requiredWorkouts && _totalWorkouts <= rank.maxWorkouts) {
        _currentRank = rank;
        
        // Set next rank if available
        if (i < rankTiers.length - 1) {
          _nextRank = rankTiers[i + 1];
        }
        break;
      }
    }
    
    print('🏆 Current rank: ${_currentRank?.title}, Total workouts: $_totalWorkouts');
    if (_nextRank != null) {
      print('🎯 Next rank: ${_nextRank?.title}, Required: ${_nextRank?.requiredWorkouts}');
    }
  }

  Future<void> _initializeUserAndFetchData() async {
    print('🔄 _initializeUserAndFetchData: Starting initialization'); // Debug print
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      print('🔄 Firebase Auth: User ID found: $_userId'); // Debug print
      print('🔄 About to call _setupRealtimeListener()'); // Debug print
      await _setupRealtimeListener();
      print('🔄 _setupRealtimeListener() completed'); // Debug print
      
      // Initialize goals
      _initializeUserGoals();
    } else {
      print('❌ Firebase Auth: User not logged in. Cannot fetch stats.'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Set up real-time listener for automatic updates
  Future<void> _setupRealtimeListener() async {
    print('🔄 _setupRealtimeListener: Entry point reached'); // Debug print
    if (_userId == null) {
      print('❌ Firestore Listener: User ID is null, cannot setup listener.'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    print('🔄 _setupRealtimeListener: User ID verified: $_userId'); // Debug print

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('🔄 Setting up real-time listener for userId: $_userId'); // Debug print
      
      // Cancel any existing subscription
      await _workoutDataSubscription?.cancel();
      print('🔄 Previous subscription cancelled (if any)'); // Debug print
      
      // Set up real-time listener
      print('🔄 Creating Firestore snapshots listener...'); // Debug print
      _workoutDataSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('completedWorkouts')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          print('🔄 Real-time listener triggered: Found ${snapshot.docs.length} documents.'); // Debug print
          if (mounted) {
            _processWorkoutData(snapshot);
          }
        },
        onError: (error) {
          print('❌ Real-time listener error: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load statistics: $error')),
            );
          }
        },
      );
      print('🔄 Real-time listener setup complete!'); // Debug print
    } catch (e) {
      print('❌ Error setting up real-time listener: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to setup real-time updates: $e')),
        );
      }
    }
  }

  // Initialize user goals
  void _initializeUserGoals() {
    print('🎯 Stats: Initializing user goals');
    
    // Cancel existing subscription if any
    _goalsSubscription?.cancel();

    // Listen to real-time goal changes
    _goalsSubscription = GoalService.getUserGoalsStream().listen(
      (goals) {
        if (mounted) {
          setState(() {
            _userGoals = goals;
          });
          print('🎯 Stats: Goals updated - $goals');
        }
      },
      onError: (error) {
        print('❌ Stats: Error listening to goals: $error');
      },
    );
  }

  // Process workout data from real-time listener
  void _processWorkoutData(QuerySnapshot snapshot) {
    print('🔄 _processWorkoutData: Processing real-time update with ${snapshot.docs.length} documents.'); // Debug print

    List<CompletedWorkout> fetchedCompletedWorkouts = snapshot.docs
        .map((doc) {
          // Debug print individual document data to check for parsing issues
          print('🔄 Document data: ${doc.data()}');
          return CompletedWorkout.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
        })
        .toList();

    print('✅ _processWorkoutData: Successfully parsed ${fetchedCompletedWorkouts.length} completed workouts'); // Debug print

    int newTotalWorkouts = 0;
    int newCaloriesBurned = 0;
    int newTotalMinutes = 0;
    List<int> newWeeklyWorkouts = List.filled(7, 0);

    DateTime now = DateTime.now();
    // Adjust startOfWeek to always be Monday for consistency
    // DateTime.weekday returns 1 for Monday, ..., 7 for Sunday
    // This ensures 'startOfWeek' is always the Monday of the current week.
    int currentDay = now.weekday; // 1 for Monday, 7 for Sunday
    DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentDay - 1));

    for (var workoutRecord in fetchedCompletedWorkouts) {
      newTotalWorkouts++;
      newCaloriesBurned += workoutRecord.actualCaloriesBurned;
      newTotalMinutes += workoutRecord.actualDurationMinutes;

      // Check if the workout falls within the *current* week
      // Ensure timestamp is not in the future and is on or after startOfWeek
      if (workoutRecord.timestamp.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          workoutRecord.timestamp.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        int dayIndex = workoutRecord.timestamp.weekday - 1; // Convert 1-7 (Mon-Sun) to 0-6
        if (dayIndex >= 0 && dayIndex < 7) {
          newWeeklyWorkouts[dayIndex]++;
        }
      }
    }
    
    // Update state first, then calculate rank
    if (mounted) {
      setState(() {
        _totalWorkouts = newTotalWorkouts;
        _caloriesBurned = newCaloriesBurned;
        _totalMinutes = newTotalMinutes;
        _weeklyWorkouts = newWeeklyWorkouts;
        _allCompletedWorkouts = fetchedCompletedWorkouts;
        _isLoading = false; // Stop loading indicator
        
        // Calculate rank based on new total workouts
        _calculateRank();
        
        print('🔄 Stats auto-updated: Total workouts: $_totalWorkouts, Calories: $_caloriesBurned, Minutes: $_totalMinutes'); // Debug print
        print('🔄 Weekly Workouts: $_weeklyWorkouts'); // Debug print
      });
    }
  }

  Future<void> _fetchWorkoutData() async {
    print('🔄 PULL-TO-REFRESH: Manual refresh triggered'); // Debug print
    if (_userId == null) {
      print('❌ PULL-TO-REFRESH: User ID is null, stopping fetch.'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('🔄 PULL-TO-REFRESH: Fetching data for userId: $_userId'); // Debug print
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('completedWorkouts')
          .orderBy('timestamp', descending: true)
          .get();

      print('🔄 PULL-TO-REFRESH: Found ${snapshot.docs.length} documents.'); // Debug print
      _processWorkoutData(snapshot);
    } catch (e) {
      print('❌ Error in pull-to-refresh: $e'); // Original error message
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh statistics: ${e.toString()}')), // Use e.toString() for full error
        );
      }
    }
  }

  @override
  void dispose() {
    // Cancel the real-time listener to prevent memory leaks
    _workoutDataSubscription?.cancel();
    _goalsSubscription?.cancel();
    super.dispose();
  }

  // Helper method to calculate today's minutes
  int _getTodayMinutes() {
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime endOfToday = startOfToday.add(const Duration(days: 1));

    int todayMinutes = 0;
    for (var workout in _allCompletedWorkouts) {
      bool isToday = workout.timestamp.isAfter(startOfToday) && workout.timestamp.isBefore(endOfToday);
      if (isToday) {
        todayMinutes += workout.actualDurationMinutes;
      }
    }
    return todayMinutes;
  }

  // Helper method to calculate monthly calories
  int _getMonthlyCalories() {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    int monthlyCalories = 0;
    for (var workout in _allCompletedWorkouts) {
      bool isThisMonth = workout.timestamp.isAfter(startOfMonth) && workout.timestamp.isBefore(endOfMonth);
      if (isThisMonth) {
        monthlyCalories += workout.actualCaloriesBurned;
      }
    }
    return monthlyCalories;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : Colors.black87);
    final Color hintColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color cardColor = Theme.of(context).cardColor;

    // Calculate Avg/Week value here to use the more robust calculation
    double avgWorkoutsPerWeekValue = 0.0;
    if (_allCompletedWorkouts.isNotEmpty) {
      DateTime firstWorkoutDate = _allCompletedWorkouts.last.timestamp; // Oldest workout
      DateTime latestWorkoutDate = _allCompletedWorkouts.first.timestamp; // Most recent workout
      final differenceInDays = latestWorkoutDate.difference(firstWorkoutDate).inDays;
      // Ensure at least one week is counted if there's any data
      final numberOfWeeks = (differenceInDays / 7).ceil();

      if (numberOfWeeks > 0) {
        avgWorkoutsPerWeekValue = _totalWorkouts / numberOfWeeks;
      } else {
        avgWorkoutsPerWeekValue = _totalWorkouts.toDouble(); // All workouts in less than a week, so consider it 1 week's worth
      }
    }


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Statistics',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: primaryColor,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: Theme.of(context).brightness == Brightness.dark
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchWorkoutData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Rank Section
                  if (_currentRank != null) ...[
                    Text(
                      'Your Rank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Current Rank Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [_currentRank!.color.withOpacity(0.6), _currentRank!.color.withOpacity(0.3)]
                              : [_currentRank!.color.withOpacity(0.8), _currentRank!.color.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _currentRank!.color.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Animated Icon Container
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                ),
                                child: Icon(
                                  _currentRank!.icon,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ACHIEVEMENT UNLOCKED',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentRank!.title.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Description with stats
                          Text(
                            _currentRank!.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          
                          // Progress to next rank
                          if (_nextRank != null) ...[
                            const SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Next Rank: ${_nextRank!.title}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_nextRank!.requiredWorkouts - _totalWorkouts} more',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _totalWorkouts / _nextRank!.requiredWorkouts,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.military_tech, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MAXIMUM RANK ACHIEVED!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // Overview Cards
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Total Workouts',
                          value: '$_totalWorkouts',
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Calories Burned',
                          // Formats to "12.3k" if over 1000, else "123"
                          value: '${(_caloriesBurned >= 1000 ? (_caloriesBurned / 1000).toStringAsFixed(1) + 'k' : _caloriesBurned.toString())}',
                          icon: Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Total Minutes',
                          value: '$_totalMinutes',
                          icon: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Avg/Week',
                          // Use the calculated average here
                          value: avgWorkoutsPerWeekValue.toStringAsFixed(1),
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Weekly Activity Chart
                  Text(
                    'Weekly Activity',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                              .asMap()
                              .entries
                              .map((entry) => _buildWeeklyBar(
                                  context,
                                  entry.value,
                                  _weeklyWorkouts[entry.key],
                                ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'This Week: ${_weeklyWorkouts.reduce((a, b) => a + b)} workouts',
                              style: TextStyle(
                                color: hintColor,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.trending_up,
                              color: primaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Goals Section
                  Text(
                    'Goals',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily Goal
                  _buildGoalCard(
                    context,
                    'Daily Goal',
                    'Complete ${_userGoals['dailyMinutes'] ?? 30} minutes',
                    _getTodayMinutes(),
                    _userGoals['dailyMinutes'] ?? 30,
                    Icons.timer,
                  ),
                  const SizedBox(height: 12),

                  // Weekly Goal
                  _buildGoalCard(
                    context,
                    'Weekly Goal',
                    'Complete ${_userGoals['weeklyWorkouts'] ?? 5} workouts',
                    _weeklyWorkouts.reduce((a, b) => a + b),
                    _userGoals['weeklyWorkouts'] ?? 5,
                    Icons.flag_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Monthly Goal
                  _buildGoalCard(
                    context,
                    'Monthly Goal',
                    'Burn ${_userGoals['monthlyCalories'] ?? 5000} calories',
                    _getMonthlyCalories(),
                    _userGoals['monthlyCalories'] ?? 5000,
                    Icons.local_fire_department,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWeeklyBar(BuildContext context, String day, int value) {
    final theme = Theme.of(context);
    final double heightFactor = value / 5.0; // Max 5 workouts for full height (adjust as needed for max workouts per day)
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: 60, // Fixed height for the bar background
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            heightFactor: heightFactor.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, String title, String subtitle, int current, int goal, IconData icon) {
    final theme = Theme.of(context);
    double progress = (current / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  color: theme.primaryColor,
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  '$current / $goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final Color hintColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[400]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }
}