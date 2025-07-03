import 'package:shared_preferences/shared_preferences.dart';

class WorkoutService {
  static Future<void> markAsCompleted(String workoutName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList('completed') ?? [];
    if (!completed.contains(workoutName)) {
      completed.add(workoutName);
      await prefs.setStringList('completed', completed);
    }
  }

  static Future<List<String>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('completed') ?? [];
  }
}
