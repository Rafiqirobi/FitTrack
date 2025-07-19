import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default goal values
  static const int defaultDailyMinutes = 30;
  static const int defaultWeeklyWorkouts = 5;
  static const int defaultMonthlyCalories = 5000;

  // Get user's custom goals
  static Future<Map<String, dynamic>> getUserGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getDefaultGoals();
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .get();

      if (doc.exists) {
        return doc.data() ?? _getDefaultGoals();
      } else {
        // Initialize with default goals if doesn't exist
        await setUserGoals(_getDefaultGoals());
        return _getDefaultGoals();
      }
    } catch (e) {
      print('Error getting user goals: $e');
      return _getDefaultGoals();
    }
  }

  // Set user's custom goals
  static Future<void> setUserGoals(Map<String, dynamic> goals) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .set(goals, SetOptions(merge: true));
      
      print('Goals saved successfully: $goals');
    } catch (e) {
      print('Error setting user goals: $e');
      throw e;
    }
  }

  // Update specific goal
  static Future<void> updateGoal(String goalType, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .update({goalType: value});
      
      print('Goal updated: $goalType = $value');
    } catch (e) {
      print('Error updating goal: $e');
      throw e;
    }
  }

  // Get real-time stream of user goals
  static Stream<Map<String, dynamic>> getUserGoalsStream() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value(_getDefaultGoals());
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .snapshots()
          .map((doc) {
            if (doc.exists) {
              return doc.data() ?? _getDefaultGoals();
            } else {
              // Initialize with defaults if doesn't exist
              setUserGoals(_getDefaultGoals());
              return _getDefaultGoals();
            }
          });
    } catch (e) {
      print('Error getting goals stream: $e');
      return Stream.value(_getDefaultGoals());
    }
  }

  // Get default goals map
  static Map<String, dynamic> _getDefaultGoals() {
    return {
      'dailyMinutes': defaultDailyMinutes,
      'weeklyWorkouts': defaultWeeklyWorkouts,
      'monthlyCalories': defaultMonthlyCalories,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Validate goal values
  static bool isValidGoal(String goalType, dynamic value) {
    if (value == null) return false;
    
    switch (goalType) {
      case 'dailyMinutes':
        return value is int && value >= 5 && value <= 180; // 5 minutes to 3 hours
      case 'weeklyWorkouts':
        return value is int && value >= 1 && value <= 21; // 1 to 21 workouts per week
      case 'monthlyCalories':
        return value is int && value >= 100 && value <= 50000; // 100 to 50k calories
      default:
        return false;
    }
  }

  // Get goal display name
  static String getGoalDisplayName(String goalType) {
    switch (goalType) {
      case 'dailyMinutes':
        return 'Daily Minutes';
      case 'weeklyWorkouts':
        return 'Weekly Workouts';
      case 'monthlyCalories':
        return 'Monthly Calories';
      default:
        return goalType;
    }
  }

  // Get goal unit
  static String getGoalUnit(String goalType) {
    switch (goalType) {
      case 'dailyMinutes':
        return 'min';
      case 'weeklyWorkouts':
        return 'workouts';
      case 'monthlyCalories':
        return 'cal';
      default:
        return '';
    }
  }
}
