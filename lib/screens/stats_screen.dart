import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {

  final int totalWorkouts = 42;
  final int caloriesBurned = 12340;
  final int totalMinutes = 1860;

  final List<int> weeklyWorkouts = [3, 4, 2, 5, 3, 4, 1];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Your Statistics', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ✅ Overview Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Workouts',
                    value: '$totalWorkouts',
                    icon: Icons.fitness_center,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Calories',
                    value: '$caloriesBurned',
                    icon: Icons.local_fire_department,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Minutes',
                    value: '$totalMinutes',
                    icon: Icons.timer,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ✅ Weekly Chart Section
              Text(
                'Weekly Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Simple bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(weeklyWorkouts.length, (index) {
                    return _buildBar(
                      context,
                      day: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                      value: weeklyWorkouts[index],
                      maxValue: 5,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Small stat card
  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
                color: theme.hintColor ?? Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Simple vertical bar
  Widget _buildBar(BuildContext context, {
    required String day,
    required int value,
    required int maxValue,
  }) {
    final theme = Theme.of(context);
    final double heightFactor = value / maxValue;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: 80,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }
}
