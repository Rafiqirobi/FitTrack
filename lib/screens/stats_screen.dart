import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/models/completed_workout_model.dart'; // Adjust import path
// You might also need your Workout model if you use it for achievement logic etc.
// import 'package:your_app_name/models/workout_model.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchData();
  }

  Future<void> _initializeUserAndFetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _fetchWorkoutData();
    } else {
      print('User not logged in. Cannot fetch stats.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWorkoutData() async {
    if (_userId == null) {
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
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('completed_workouts')
          .where('userId', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .get();

      List<CompletedWorkout> fetchedCompletedWorkouts = snapshot.docs
          .map((doc) => CompletedWorkout.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      int newTotalWorkouts = 0;
      int newCaloriesBurned = 0;
      int newTotalMinutes = 0;
      List<int> newWeeklyWorkouts = List.filled(7, 0);

      DateTime now = DateTime.now();
      DateTime startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      for (var workoutRecord in fetchedCompletedWorkouts) {
        newTotalWorkouts++;
        newCaloriesBurned += workoutRecord.actualCaloriesBurned;
        newTotalMinutes += workoutRecord.actualDurationMinutes;

        if (workoutRecord.timestamp.isAfter(startOfWeek) || workoutRecord.timestamp.isAtSameMomentAs(startOfWeek)) {
          int dayIndex = workoutRecord.timestamp.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            newWeeklyWorkouts[dayIndex]++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalWorkouts = newTotalWorkouts;
          _caloriesBurned = newCaloriesBurned;
          _totalMinutes = newTotalMinutes;
          _weeklyWorkouts = newWeeklyWorkouts;
          _allCompletedWorkouts = fetchedCompletedWorkouts; // Assign fetched data to state variable
        });
      }
    } catch (e) {
      print('Error fetching workout data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load statistics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : Colors.black87);
    final Color hintColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color cardColor = Theme.of(context).cardColor;

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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Achievement Badge (Placeholder, can be made dynamic based on _totalWorkouts)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [primaryColor.withOpacity(0.6), primaryColor.withOpacity(0.4)]
                            : [primaryColor.withOpacity(0.8), primaryColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
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
                            Icon(
                              Icons.emoji_events,
                              color: isDarkMode ? Colors.black : Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Achievement Unlocked!',
                              style: TextStyle(
                                color: isDarkMode ? Colors.black : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Workout Warrior',
                          style: TextStyle(
                            color: isDarkMode ? Colors.black : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete 40+ workouts', // You can make this dynamic based on _totalWorkouts
                          style: TextStyle(
                            color: isDarkMode ? Colors.black87 : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

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
                          // Corrected calculation for Avg/Week using _allCompletedWorkouts
                          value: '${(_totalWorkouts / (_allCompletedWorkouts.isNotEmpty ? (_allCompletedWorkouts.length / 7).ceil() : 1)).toStringAsFixed(1)}',
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

                  _buildGoalCard(
                    context,
                    'Weekly Goal',
                    'Complete 5 workouts',
                    _weeklyWorkouts.reduce((a, b) => a + b), // Current progress for current week
                    5,
                    Icons.flag_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGoalCard(
                    context,
                    'Monthly Goal',
                    'Burn 5000 calories',
                    _caloriesBurned, // Using total calories as current progress for example
                    5000,
                    Icons.local_fire_department,
                  ),
                ],
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