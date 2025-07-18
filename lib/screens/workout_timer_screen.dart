import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class WorkoutTimerScreen extends StatefulWidget {
  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> with TickerProviderStateMixin {
  late List<dynamic> steps;
  late Map<String, dynamic> workoutData;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  int totalStepDuration = 0;
  bool isResting = false;
  bool isPaused = false;
  bool workoutIsFinishedUI = false;

  Timer? _timer;
  AnimationController? _progressController;

  final AudioPlayer _audioPlayer = AudioPlayer();

  static const Color neonGreen = Color(0xFFCCFF00);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    workoutData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    steps = workoutData['steps'] ?? [];

    if (steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No workout steps available for this workout.')),
        );
        Navigator.pop(context);
      });
      return;
    }
    startStep();
  }

  Future<void> _playStepSound() async {
    await _audioPlayer.play(AssetSource('lib/assets/sounds/step.mp3'));
  }

  Future<void> _playFinishSound() async {
    await _audioPlayer.play(AssetSource('lib/assets/sounds/step.mp3'));
  }

  void startStep({bool rest = false}) {
    _progressController?.dispose();
    _progressController = null;

    final stepData = steps[currentStepIndex] as Map<String, dynamic>;
    totalStepDuration = rest ? 5 : (stepData['duration'] ?? 30);
    currentStepTime = totalStepDuration;
    isResting = rest;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalStepDuration),
    );

    if (!isPaused) _progressController!.forward();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        if (currentStepTime > 0) {
          setState(() {
            currentStepTime--;
          });
          if (_progressController != null &&
              _progressController!.duration != null &&
              _progressController!.duration!.inSeconds > 0) {
            _progressController!.value = 1.0 - (currentStepTime / _progressController!.duration!.inSeconds);
          }
        } else {
          timer.cancel();
          () async {
            await _playStepSound();
            if (isResting) {
              goToNextStep();
            } else {
              if (currentStepIndex < steps.length - 1) {
                startStep(rest: true);
              } else {
                await _playFinishSound();
                _prepareForFinishUI();
              }
            }
          }();
        }
      }
    });

    setState(() {});
  }

  void goToNextStep() {
    _timer?.cancel();
    _progressController?.stop();

    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
        isPaused = false;
      });
      startStep();
    } else {
      _prepareForFinishUI();
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        _timer?.cancel();
        _progressController?.stop();
      } else {
        if (_progressController != null && totalStepDuration > 0) {
          _progressController!.value = 1.0 - (currentStepTime / totalStepDuration);
          _progressController!.forward(from: _progressController!.value);
        }
        _startTimerHelper();
      }
    });
  }

  void _startTimerHelper() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        if (currentStepTime > 0) {
          setState(() {
            currentStepTime--;
          });
          if (_progressController != null &&
              _progressController!.duration != null &&
              _progressController!.duration!.inSeconds > 0) {
            _progressController!.value = 1.0 - (currentStepTime / _progressController!.duration!.inSeconds);
          }
        } else {
          timer.cancel();
          () async {
            await _playStepSound();
            if (isResting) {
              goToNextStep();
            } else {
              if (currentStepIndex < steps.length - 1) {
                startStep(rest: true);
              } else {
                await _playFinishSound();
                _prepareForFinishUI();
              }
            }
          }();
        }
      }
    });
  }

  void _prepareForFinishUI() {
  setState(() {
    workoutIsFinishedUI = true;
  });

  Future.delayed(Duration(milliseconds: 100), () {
    _playFinishSound();
  });


    _timer?.cancel();
    _progressController?.stop();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context, workoutData);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Scaffold(
        backgroundColor: darkBg,
        body: Center(
          child: Text(
            'No workout steps available.',
            style: TextStyle(color: neonGreen),
          ),
        ),
      );
    }

    final step = steps[currentStepIndex < steps.length ? currentStepIndex : steps.length - 1];
    final stepTitle = isResting ? "Rest" : step['name'] ?? 'Exercise';
    final stepDescription = isResting
        ? "Take a short break before the next exercise."
        : step['text'] ?? "No description available.";

    final double overallProgress = currentStepIndex >= steps.length ? 1.0 : currentStepIndex / steps.length;

    final bool isLastExerciseStep = currentStepIndex == steps.length - 1 && !isResting;
    final String skipButtonText = isLastExerciseStep ? 'FINISH' : 'SKIP STEP';
    final IconData skipButtonIcon = isLastExerciseStep ? Icons.check_circle : Icons.skip_next;

    final double circleSize = MediaQuery.of(context).size.width * 0.9;

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
            LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(neonGreen),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Progress: ${((overallProgress) * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              workoutIsFinishedUI
                  ? 'WORKOUT COMPLETE!'
                  : (isResting ? 'RESTING' : 'STEP ${currentStepIndex + 1} of ${steps.length}'),
              style: const TextStyle(
                color: neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),
            if (!workoutIsFinishedUI)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: neonGreen.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      stepTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stepDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isResting)
                      Text(
                        'Reps: ${step['reps'] ?? 'N/A'} | Sets: ${step['sets'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Great job! Workout completed.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            Flexible(
              child: Center(
                child: SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!workoutIsFinishedUI)
                        Text(
                          '$currentStepTime s',
                          style: const TextStyle(
                            color: neonGreen,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      foregroundColor: darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: !workoutIsFinishedUI ? togglePause : null,
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      isPaused ? 'RESUME' : 'PAUSE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: !workoutIsFinishedUI ? goToNextStep : null,
                    icon: Icon(skipButtonIcon),
                    label: Text(
                      skipButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
