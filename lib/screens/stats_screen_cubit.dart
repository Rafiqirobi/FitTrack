import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:FitTrack/cubit/stats_cubit.dart';
import 'package:FitTrack/cubit/stats_state.dart';
import 'package:FitTrack/models/activity_model.dart';

/// Stats Screen using Cubit for state management
class StatsScreenCubit extends StatelessWidget {
  final VoidCallback? onToggleTheme;

  const StatsScreenCubit({super.key, this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsCubit()..initialize(),
      child: _StatsScreenContent(onToggleTheme: onToggleTheme),
    );
  }
}

class _StatsScreenContent extends StatelessWidget {
  final VoidCallback? onToggleTheme;

  const _StatsScreenContent({this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? 
        (isDarkMode ? Colors.white : Colors.black87);
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
          if (onToggleTheme != null)
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: primaryColor,
              ),
              onPressed: onToggleTheme,
              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) {
          if (state.status == StatsStatus.loading || state.status == StatsStatus.initial) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (state.status == StatsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'An error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<StatsCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Calculate avg per week
          double avgWorkoutsPerWeekValue = state.averagePerWeek;

          return RefreshIndicator(
            onRefresh: () => context.read<StatsCubit>().refresh(),
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rank Section
                  if (state.currentRank != null) ...[
                    Text(
                      'Your Rank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRankCard(context, state, isDarkMode),
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
                          title: 'Total Activities',
                          value: '${state.totalActivities}',
                          icon: Icons.fitness_center,
                          gradientStart: const Color(0xFF667EEA),
                          gradientEnd: const Color(0xFF764BA2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Calories Burned',
                          value: state.totalCombinedCalories >= 1000
                              ? '${(state.totalCombinedCalories / 1000).toStringAsFixed(1)}k'
                              : '${state.totalCombinedCalories}',
                          icon: Icons.local_fire_department,
                          gradientStart: const Color(0xFFFF512F),
                          gradientEnd: const Color(0xFFDD2476),
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
                          value: '${state.totalCombinedMinutes}',
                          icon: Icons.timer,
                          gradientStart: const Color(0xFF11998E),
                          gradientEnd: const Color(0xFF38EF7D),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Avg/Week',
                          value: avgWorkoutsPerWeekValue.toStringAsFixed(1),
                          icon: Icons.trending_up,
                          gradientStart: const Color(0xFFF093FB),
                          gradientEnd: const Color(0xFFF5576C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Running Stats Section
                  Text(
                    'Running Stats',
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
                          title: 'Total Runs',
                          value: '${state.totalRuns}',
                          icon: Icons.directions_run,
                          gradientStart: const Color(0xFF4FACFE),
                          gradientEnd: const Color(0xFF00F2FE),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: 'Total Distance',
                          value: '${state.totalDistanceKm.toStringAsFixed(1)} km',
                          icon: Icons.straighten,
                          gradientStart: const Color(0xFFFA709A),
                          gradientEnd: const Color(0xFFFEE140),
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
                                    state.weeklyWorkouts[entry.key] + state.weeklyRuns[entry.key],
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'This Week: ${state.weeklyWorkouts.reduce((a, b) => a + b) + state.weeklyRuns.reduce((a, b) => a + b)} activities',
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
                    'Daily Goal',
                    'Complete ${state.userGoals['dailyMinutes'] ?? 30} minutes',
                    _getTodayMinutes(state),
                    state.userGoals['dailyMinutes'] ?? 30,
                    Icons.timer,
                  ),
                  const SizedBox(height: 12),

                  _buildGoalCard(
                    context,
                    'Weekly Goal',
                    'Complete ${state.userGoals['weeklyWorkouts'] ?? 5} activities',
                    state.weeklyWorkouts.reduce((a, b) => a + b) + state.weeklyRuns.reduce((a, b) => a + b),
                    state.userGoals['weeklyWorkouts'] ?? 5,
                    Icons.flag_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGoalCard(
                    context,
                    'Monthly Goal',
                    'Burn ${state.userGoals['monthlyCalories'] ?? 5000} calories',
                    _getMonthlyCalories(state),
                    state.userGoals['monthlyCalories'] ?? 5000,
                    Icons.local_fire_department,
                  ),

                  const SizedBox(height: 30),

                  // Activity History Section
                  Text(
                    'Activity History',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (state.allActivities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 48,
                              color: primaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activities yet',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.allActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final activity = state.allActivities[index];
                        return _buildActivityTile(context, activity, primaryColor, cardColor, textColor);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to calculate today's minutes
  int _getTodayMinutes(StatsState state) {
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime endOfToday = startOfToday.add(const Duration(days: 1));

    int todayMinutes = 0;

    for (var workout in state.allCompletedWorkouts) {
      if (workout.timestamp.isAfter(startOfToday) && workout.timestamp.isBefore(endOfToday)) {
        todayMinutes += workout.actualDurationMinutes;
      }
    }

    for (var run in state.allRuns) {
      if (run.startTime.isAfter(startOfToday) && run.startTime.isBefore(endOfToday)) {
        todayMinutes += (run.durationSeconds / 60).round();
      }
    }

    return todayMinutes;
  }

  // Helper method to calculate monthly calories
  int _getMonthlyCalories(StatsState state) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    int monthlyCalories = 0;

    for (var workout in state.allCompletedWorkouts) {
      if (workout.timestamp.isAfter(startOfMonth) && workout.timestamp.isBefore(endOfMonth)) {
        monthlyCalories += workout.actualCaloriesBurned;
      }
    }

    for (var run in state.allRuns) {
      if (run.startTime.isAfter(startOfMonth) && run.startTime.isBefore(endOfMonth)) {
        monthlyCalories += (run.totalDistanceMeters / 1000 * 60).round();
      }
    }

    return monthlyCalories;
  }

  Widget _buildRankCard(BuildContext context, StatsState state, bool isDarkMode) {
    final rank = state.currentRank!;
    final rankColor = Color(rank.colorValue);
    final nextRank = state.nextRank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [rankColor.withOpacity(0.6), rankColor.withOpacity(0.3)]
              : [rankColor.withOpacity(0.8), rankColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.3),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  _getIconForRank(rank.iconName),
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
                      rank.title.toUpperCase(),
                      style: const TextStyle(
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
          Text(
            rank.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (nextRank != null) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Rank: ${nextRank.title}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${nextRank.requiredWorkouts - state.totalActivities} more',
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
                      value: state.totalActivities / nextRank.requiredWorkouts,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.military_tech, color: Colors.white, size: 20),
                  SizedBox(width: 8),
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
    );
  }

  IconData _getIconForRank(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'stars':
        return Icons.stars;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color startColor = gradientStart ?? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5));
    final Color endColor = gradientEnd ?? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBar(BuildContext context, String day, int value) {
    final theme = Theme.of(context);
    final double heightFactor = value / 5.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: 60,
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

  Widget _buildActivityTile(BuildContext context, Activity activity, Color primaryColor, Color cardColor, Color textColor) {
    IconData activityIcon;
    Color activityColor;

    if (activity is WorkoutActivity) {
      activityIcon = Icons.fitness_center;
      activityColor = primaryColor;
    } else if (activity is RunActivity) {
      activityIcon = Icons.directions_run;
      activityColor = Colors.lightGreen;
    } else {
      activityIcon = Icons.dashboard;
      activityColor = primaryColor;
    }

    // Format date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(activity.timestamp.year, activity.timestamp.month, activity.timestamp.day);
    final dayDiff = today.difference(activityDate).inDays;

    String dateLabel;
    if (dayDiff == 0) {
      dateLabel = 'Today at ${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')}';
    } else if (dayDiff == 1) {
      dateLabel = 'Yesterday';
    } else if (dayDiff < 7) {
      dateLabel = '$dayDiff days ago';
    } else {
      dateLabel = '${activity.timestamp.month}/${activity.timestamp.day}/${activity.timestamp.year}';
    }

    // Build description
    String description = activity.getDescription();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activityColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activityIcon,
              color: activityColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
