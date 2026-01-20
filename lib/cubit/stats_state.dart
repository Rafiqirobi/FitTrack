import 'package:equatable/equatable.dart';
import 'package:FitTrack/models/completed_workout_model.dart';
import 'package:FitTrack/models/run_route_model.dart';
import 'package:FitTrack/models/activity_model.dart';

/// Represents the different statuses of stats loading
enum StatsStatus { initial, loading, loaded, error }

/// Represents a user's rank in the fitness system
class RankData {
  final String title;
  final String description;
  final String iconName;
  final int colorValue;
  final int requiredWorkouts;
  final int maxWorkouts;

  const RankData({
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorValue,
    required this.requiredWorkouts,
    required this.maxWorkouts,
  });
}

/// The state for the Stats feature
class StatsState extends Equatable {
  final StatsStatus status;
  final String? errorMessage;
  
  // Workout stats
  final int totalWorkouts;
  final int caloriesBurned;
  final int totalMinutes;
  final List<int> weeklyWorkouts; // 0=Mon, ..., 6=Sun
  final List<CompletedWorkout> allCompletedWorkouts;
  
  // Running stats
  final int totalRuns;
  final double totalDistanceKm;
  final int totalRunMinutes;
  final int runCaloriesBurned;
  final List<int> weeklyRuns; // 0=Mon, ..., 6=Sun
  final List<RunRoute> allRuns;
  
  // Unified activities
  final List<Activity> allActivities;
  
  // Rank system
  final RankData? currentRank;
  final RankData? nextRank;
  
  // Goals
  final Map<String, dynamic> userGoals;

  const StatsState({
    this.status = StatsStatus.initial,
    this.errorMessage,
    this.totalWorkouts = 0,
    this.caloriesBurned = 0,
    this.totalMinutes = 0,
    this.weeklyWorkouts = const [0, 0, 0, 0, 0, 0, 0],
    this.allCompletedWorkouts = const [],
    this.totalRuns = 0,
    this.totalDistanceKm = 0.0,
    this.totalRunMinutes = 0,
    this.runCaloriesBurned = 0,
    this.weeklyRuns = const [0, 0, 0, 0, 0, 0, 0],
    this.allRuns = const [],
    this.allActivities = const [],
    this.currentRank,
    this.nextRank,
    this.userGoals = const {},
  });

  /// Creates a copy of this state with the given fields replaced
  StatsState copyWith({
    StatsStatus? status,
    String? errorMessage,
    int? totalWorkouts,
    int? caloriesBurned,
    int? totalMinutes,
    List<int>? weeklyWorkouts,
    List<CompletedWorkout>? allCompletedWorkouts,
    int? totalRuns,
    double? totalDistanceKm,
    int? totalRunMinutes,
    int? runCaloriesBurned,
    List<int>? weeklyRuns,
    List<RunRoute>? allRuns,
    List<Activity>? allActivities,
    RankData? currentRank,
    RankData? nextRank,
    Map<String, dynamic>? userGoals,
  }) {
    return StatsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      weeklyWorkouts: weeklyWorkouts ?? this.weeklyWorkouts,
      allCompletedWorkouts: allCompletedWorkouts ?? this.allCompletedWorkouts,
      totalRuns: totalRuns ?? this.totalRuns,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalRunMinutes: totalRunMinutes ?? this.totalRunMinutes,
      runCaloriesBurned: runCaloriesBurned ?? this.runCaloriesBurned,
      weeklyRuns: weeklyRuns ?? this.weeklyRuns,
      allRuns: allRuns ?? this.allRuns,
      allActivities: allActivities ?? this.allActivities,
      currentRank: currentRank ?? this.currentRank,
      nextRank: nextRank ?? this.nextRank,
      userGoals: userGoals ?? this.userGoals,
    );
  }

  // Computed properties
  int get totalActivities => totalWorkouts + totalRuns;
  int get totalCombinedCalories => caloriesBurned + runCaloriesBurned;
  int get totalCombinedMinutes => totalMinutes + totalRunMinutes;
  
  double get averagePerWeek {
    if (allActivities.isEmpty) return 0.0;
    // Calculate weeks since first activity
    DateTime? earliest;
    for (var activity in allActivities) {
      if (earliest == null || activity.timestamp.isBefore(earliest)) {
        earliest = activity.timestamp;
      }
    }
    if (earliest == null) return 0.0;
    
    final weeks = DateTime.now().difference(earliest).inDays / 7;
    if (weeks < 1) return totalActivities.toDouble();
    return totalActivities / weeks;
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        totalWorkouts,
        caloriesBurned,
        totalMinutes,
        weeklyWorkouts,
        allCompletedWorkouts,
        totalRuns,
        totalDistanceKm,
        totalRunMinutes,
        runCaloriesBurned,
        weeklyRuns,
        allRuns,
        allActivities,
        currentRank,
        nextRank,
        userGoals,
      ];
}
