// Unified model for both workouts and running activities
abstract class Activity {
  final String id;
  final DateTime timestamp;
  final String title;
  final int durationMinutes;
  final String type; // 'workout' or 'run'

  Activity({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.durationMinutes,
    required this.type,
  });

  // Returns a summary description
  String getDescription();
  
  // Returns the icon to display
  String getIconType();
}

// Workout Activity
class WorkoutActivity extends Activity {
  final int caloriesBurned;
  final String workoutName;
  final String workoutCategory;

  WorkoutActivity({
    required String id,
    required DateTime timestamp,
    required this.workoutName,
    required this.workoutCategory,
    required int durationMinutes,
    required this.caloriesBurned,
  }) : super(
    id: id,
    timestamp: timestamp,
    title: workoutName,
    durationMinutes: durationMinutes,
    type: 'workout',
  );

  @override
  String getDescription() {
    return '$durationMinutes min • $caloriesBurned cal • $workoutCategory';
  }

  @override
  String getIconType() {
    return workoutCategory; // 'chest', 'legs', 'arms', etc.
  }
}
// Running Activity
class RunActivity extends Activity {
  final double distanceKm;
  final double? pace; // min/km

  RunActivity({
    required String id,
    required DateTime timestamp,
    required int durationSeconds,
    required this.distanceKm,
  }) : pace = durationSeconds > 0 ? (durationSeconds / 60.0) / distanceKm : null,
       super(
    id: id,
    timestamp: timestamp,
    title: 'Running',
    durationMinutes: (durationSeconds / 60).round(),
    type: 'run',
  );

  @override
  String getDescription() {
    String paceStr = pace != null ? '${pace!.toStringAsFixed(1)} min/km' : 'N/A';
    return '${distanceKm.toStringAsFixed(2)} km • $durationMinutes min • $paceStr';
  }

  @override
  String getIconType() {
    return 'run';
  }
}
