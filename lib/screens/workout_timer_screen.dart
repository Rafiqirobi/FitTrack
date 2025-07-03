import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/workout_service.dart';

class WorkoutTimerScreen extends StatefulWidget {
  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  late Workout workout;
  late int remainingTime;
  Timer? timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    workout = ModalRoute.of(context)!.settings.arguments as Workout;
    remainingTime = workout.duration;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer?.cancel();
          WorkoutService.markAsCompleted(workout.name);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Workout completed!')));
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Workout Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(workout.imageAsset, height: 200),
            SizedBox(height: 20),
            Text(workout.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('${remainingTime}s remaining', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
