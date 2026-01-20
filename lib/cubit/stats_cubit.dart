import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FitTrack/models/completed_workout_model.dart';
import 'package:FitTrack/models/run_route_model.dart';
import 'package:FitTrack/models/activity_model.dart';
import 'package:FitTrack/services/goal_service.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit() : super(const StatsState());

  StreamSubscription<QuerySnapshot>? _workoutSubscription;
  StreamSubscription<QuerySnapshot>? _runSubscription;
  StreamSubscription? _goalsSubscription;

  String? _userId;

  // Rank tiers definition
  static const List<RankData> _rankTiers = [
    RankData(
      title: 'Beginner',
      description: 'Starting your fitness journey',
      iconName: 'fitness_center',
      colorValue: 0xFF9E9E9E, // Colors.grey
      requiredWorkouts: 0,
      maxWorkouts: 9,
    ),
    RankData(
      title: 'Warrior',
      description: 'Showing dedication and consistency',
      iconName: 'local_fire_department',
      colorValue: 0xFF4CAF50, // Colors.green
      requiredWorkouts: 10,
      maxWorkouts: 24,
    ),
    RankData(
      title: 'Elite',
      description: 'Advanced fitness enthusiast',
      iconName: 'military_tech',
      colorValue: 0xFF2196F3, // Colors.blue
      requiredWorkouts: 25,
      maxWorkouts: 49,
    ),
    RankData(
      title: 'Master',
      description: 'Fitness master with exceptional commitment',
      iconName: 'emoji_events',
      colorValue: 0xFFFF5722, // Colors.deepOrange
      requiredWorkouts: 50,
      maxWorkouts: 99,
    ),
    RankData(
      title: 'Legend',
      description: 'Ultimate fitness legend',
      iconName: 'stars',
      colorValue: 0xFF9C27B0, // Colors.purple
      requiredWorkouts: 100,
      maxWorkouts: 999,
    ),
  ];

  /// Initialize the cubit and start fetching data
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(state.copyWith(
        status: StatsStatus.error,
        errorMessage: 'User not logged in',
      ));
      return;
    }

    _userId = user.uid;
    emit(state.copyWith(status: StatsStatus.loading));
    
    await _setupListeners();
    _setupGoalsListener();
  }

  /// Set up real-time Firestore listeners
  Future<void> _setupListeners() async {
    if (_userId == null) return;

    // Cancel existing subscriptions
    await _workoutSubscription?.cancel();
    await _runSubscription?.cancel();

    // Workouts listener
    _workoutSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('completedWorkouts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) => _processWorkoutData(snapshot),
      onError: (error) {
        emit(state.copyWith(
          status: StatsStatus.error,
          errorMessage: 'Failed to load workout stats: $error',
        ));
      },
    );

    // Runs listener
    _runSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('runs')
        .snapshots()
        .listen(
      (snapshot) => _processRunData(snapshot),
      onError: (error) {
        // Non-critical, don't emit error
        print('⚠️ Runs listener error: $error');
      },
    );
  }

  /// Set up goals listener
  void _setupGoalsListener() {
    _goalsSubscription?.cancel();
    _goalsSubscription = GoalService.getUserGoalsStream().listen(
      (goals) {
        emit(state.copyWith(userGoals: goals));
      },
      onError: (error) {
        print('❌ Goals listener error: $error');
      },
    );
  }

  /// Process workout data from Firestore
  void _processWorkoutData(QuerySnapshot snapshot) {
    final workouts = snapshot.docs
        .map((doc) => CompletedWorkout.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();

    int totalWorkouts = workouts.length;
    int caloriesBurned = 0;
    int totalMinutes = 0;
    List<int> weeklyWorkouts = List.filled(7, 0);

    final now = DateTime.now();
    final currentDay = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentDay - 1));

    for (var workout in workouts) {
      caloriesBurned += workout.actualCaloriesBurned;
      totalMinutes += workout.actualDurationMinutes;

      // Check if within current week
      if (workout.timestamp.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          workout.timestamp.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        int dayIndex = workout.timestamp.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyWorkouts[dayIndex]++;
        }
      }
    }

    // Calculate rank with current totals
    final rankResult = _calculateRank(totalWorkouts + state.totalRuns);

    emit(state.copyWith(
      status: StatsStatus.loaded,
      totalWorkouts: totalWorkouts,
      caloriesBurned: caloriesBurned,
      totalMinutes: totalMinutes,
      weeklyWorkouts: weeklyWorkouts,
      allCompletedWorkouts: workouts,
      currentRank: rankResult['current'] as RankData?,
      nextRank: rankResult['next'] as RankData?,
      allActivities: _buildActivitiesList(workouts, state.allRuns),
    ));
  }

  /// Process running data from Firestore
  void _processRunData(QuerySnapshot snapshot) {
    final runs = snapshot.docs
        .map((doc) {
          try {
            return RunRoute.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<RunRoute>()
        .toList();

    int totalRuns = runs.length;
    double totalDistanceKm = 0.0;
    int totalRunMinutes = 0;
    int runCalories = 0;
    List<int> weeklyRuns = List.filled(7, 0);

    final now = DateTime.now();
    final currentDay = now.weekday;
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentDay - 1));

    for (var run in runs) {
      totalDistanceKm += run.totalDistanceMeters / 1000;
      totalRunMinutes += (run.durationSeconds / 60).round();
      runCalories += (run.totalDistanceMeters / 1000 * 60).round();

      if (run.startTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          run.startTime.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        int dayIndex = run.startTime.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyRuns[dayIndex]++;
        }
      }
    }

    // Calculate rank with current totals
    final rankResult = _calculateRank(state.totalWorkouts + totalRuns);

    emit(state.copyWith(
      status: StatsStatus.loaded,
      totalRuns: totalRuns,
      totalDistanceKm: totalDistanceKm,
      totalRunMinutes: totalRunMinutes,
      runCaloriesBurned: runCalories,
      weeklyRuns: weeklyRuns,
      allRuns: runs,
      currentRank: rankResult['current'] as RankData?,
      nextRank: rankResult['next'] as RankData?,
      allActivities: _buildActivitiesList(state.allCompletedWorkouts, runs),
    ));
  }

  /// Calculate rank based on total activities
  Map<String, RankData?> _calculateRank(int totalActivities) {
    RankData? currentRank;
    RankData? nextRank;

    for (int i = 0; i < _rankTiers.length; i++) {
      final rank = _rankTiers[i];
      if (totalActivities >= rank.requiredWorkouts &&
          totalActivities <= rank.maxWorkouts) {
        currentRank = rank;
        if (i < _rankTiers.length - 1) {
          nextRank = _rankTiers[i + 1];
        }
        break;
      }
    }

    return {'current': currentRank, 'next': nextRank};
  }

  /// Build unified activities list
  List<Activity> _buildActivitiesList(
    List<CompletedWorkout> workouts,
    List<RunRoute> runs,
  ) {
    final activities = <Activity>[];

    // Add workouts
    for (var workout in workouts) {
      activities.add(WorkoutActivity(
        id: workout.id,
        timestamp: workout.timestamp,
        workoutName: workout.workoutName,
        workoutCategory: workout.workoutCategory,
        durationMinutes: workout.actualDurationMinutes,
        caloriesBurned: workout.actualCaloriesBurned,
      ));
    }

    // Add runs
    for (var run in runs) {
      activities.add(RunActivity(
        id: run.id,
        timestamp: run.startTime,
        durationSeconds: run.durationSeconds,
        distanceKm: run.totalDistanceMeters / 1000,
      ));
    }

    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  /// Refresh data manually (for pull-to-refresh)
  Future<void> refresh() async {
    emit(state.copyWith(status: StatsStatus.loading));
    await _setupListeners();
  }

  @override
  Future<void> close() {
    _workoutSubscription?.cancel();
    _runSubscription?.cancel();
    _goalsSubscription?.cancel();
    return super.close();
  }
}
