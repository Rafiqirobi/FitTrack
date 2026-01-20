import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/run_route_model.dart';
import '../models/completed_workout_model.dart';
import '../models/workout_session.dart';
import '../services/firestore_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    try {
      if (session is RunSession) {
        await _firestoreService.deleteRun(session.run.id);
      } else if (session is WorkoutRecord) {
        await _firestoreService.deleteWorkout(session.workout.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout history deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout history: $e')),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all your workout history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.clearAllRuns();
      await _firestoreService.clearAllWorkouts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All workouts cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing workouts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllHistory,
            tooltip: 'Clear all workouts',
          ),
        ],
      ),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: _firestoreService.getWorkoutSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading workouts',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_run,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Workouts Yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new workout to see your history here',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              if (session is RunSession) {
                return _buildRunCard(session.run);
              } else if (session is WorkoutRecord) {
                return _buildWorkoutCard(session.workout);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildRunCard(RunRoute run) {
    final theme = Theme.of(context);
    final distance = (run.totalDistanceMeters / 1000).toStringAsFixed(2);
    final duration = _formatDuration(Duration(seconds: run.durationSeconds));
    final date = DateFormat('MMM dd, yyyy · HH:mm').format(run.startTime);
    final pace = run.totalDistanceMeters > 0
        ? Duration(
            seconds: ((run.durationSeconds * 1000) / run.totalDistanceMeters).toInt(),
          )
        : Duration.zero;

    return Dismissible(
      key: ValueKey(run.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Workout?'),
            content: const Text(
              'Are you sure you want to delete this workout? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        _deleteSession(RunSession(run));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    distance,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'km',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    theme,
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: duration,
                  ),
                  _buildStatColumn(
                    theme,
                    icon: Icons.speed,
                    label: 'Pace',
                    value: '${_formatDuration(pace)}/km',
                  ),
                  _buildStatColumn(
                    theme,
                    icon: Icons.location_on,
                    label: 'Points',
                    value: '${run.coordinates.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(CompletedWorkout workout) {
    final theme = Theme.of(context);
    final date = DateFormat('MMM dd, yyyy · HH:mm').format(workout.timestamp);
    final duration = '${workout.actualDurationMinutes} min';

    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Workout?'),
            content: const Text(
              'Are you sure you want to delete this workout? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        _deleteSession(WorkoutRecord(workout));
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                workout.workoutName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(
                    theme,
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: duration,
                  ),
                  _buildStatColumn(
                    theme,
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${workout.actualCaloriesBurned} kcal',
                  ),
                  _buildStatColumn(
                    theme,
                    icon: Icons.category,
                    label: 'Category',
                    value: workout.workoutCategory,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }
}
