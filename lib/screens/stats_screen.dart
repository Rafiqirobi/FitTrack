import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  final int totalWorkouts = 42;
  final int caloriesBurned = 12340;
  final int totalMinutes = 1860;
  final List<int> weeklyWorkouts = [3, 4, 2, 5, 3, 4, 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Statistics',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievement Badge
            Container(
              width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
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
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.black 
                              : Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Workout Warrior',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.black 
                            : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Complete 40+ workouts',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.black87 
                            : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 30),

            // Overview Cards
            Text(
              'Overview',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Workouts',
                    value: '$totalWorkouts',
                    icon: Icons.fitness_center,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Calories Burned',
                    value: '${(caloriesBurned / 1000).toStringAsFixed(1)}k',
                    icon: Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Minutes',
                    value: '$totalMinutes',
                    icon: Icons.timer,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Avg/Week',
                    value: '${(totalWorkouts / 6).toStringAsFixed(1)}',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Weekly Activity Chart
            Text(
              'Weekly Activity',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                              weeklyWorkouts[entry.key],
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'This Week: ${weeklyWorkouts.reduce((a, b) => a + b)} workouts',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Goals Section
            Text(
              'Goals',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildGoalCard(
              context,
              'Weekly Goal',
              'Complete 5 workouts',
              weeklyWorkouts.reduce((a, b) => a + b),
              5,
              Icons.flag_outlined,
            ),
            SizedBox(height: 12),

            _buildGoalCard(
              context,
              'Monthly Goal',
              'Burn 5000 calories',
              3200,
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
        SizedBox(height: 4),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 32),
          SizedBox(width: 16),
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
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  color: theme.primaryColor,
                  minHeight: 6,
                ),
                SizedBox(height: 4),
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
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
