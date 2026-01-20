import 'package:FitTrack/models/completed_workout_model.dart';
import 'package:FitTrack/models/run_route_model.dart';

abstract class WorkoutSession {
  final DateTime timestamp;

  WorkoutSession(this.timestamp);
}

class RunSession extends WorkoutSession {
  final RunRoute run;

  RunSession(this.run) : super(run.startTime);
}

class WorkoutRecord extends WorkoutSession {
  final CompletedWorkout workout;

  WorkoutRecord(this.workout) : super(workout.timestamp);
}
