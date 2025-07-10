import 'dart:async';
import 'package:flutter/material.dart';

class WorkoutTimerScreen extends StatefulWidget {
  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with SingleTickerProviderStateMixin {
  late List<dynamic> steps;
  late int totalDuration;
  int currentStepIndex = 0;
  int currentStepTime = 0;

  Timer? _timer;
  AnimationController? _progressController;

  static const Color neonGreen = Color(0xFFCCFF00);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workout = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    steps = workout['steps'] ?? [];
    totalDuration = workout['duration'] ?? 30;

    startStep();
  }

  void startStep() {
    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration),
    )..forward();

    setState(() {
      currentStepTime = totalDuration;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentStepTime > 1) {
        setState(() {
          currentStepTime--;
        });
      } else {
        timer.cancel();
        goToNextStep();
      }
    });
  }

  void goToNextStep() {
    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
      startStep();
    } else {
      Navigator.pushReplacementNamed(context, '/workoutComplete');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WORKOUT TIMER',
          style: TextStyle(
            color: neonGreen,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: neonGreen),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'STEP ${currentStepIndex + 1} of ${steps.length}',
              style: const TextStyle(
                color: neonGreen,
                fontSize: 18,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),

            // Step Text in Glassy Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: neonGreen.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: neonGreen.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                steps[currentStepIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Neon Timer Circle
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _progressController ?? AnimationController(vsync: this),
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _progressController?.value ?? 0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(neonGreen),
                        );
                      },
                    ),
                    Text(
                      '$currentStepTime s',
                      style: const TextStyle(
                        color: neonGreen,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Modern Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  foregroundColor: darkBg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor: neonGreen.withOpacity(0.3),
                ),
                onPressed: goToNextStep,
                icon: const Icon(Icons.skip_next),
                label: const Text(
                  'SKIP / NEXT STEP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
