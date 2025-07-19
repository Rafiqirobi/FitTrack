import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:FitTrack/services/firestore_service.dart';
import 'package:FitTrack/models/workout_model.dart';

class WorkoutTimerScreen extends StatefulWidget {
  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with TickerProviderStateMixin {
  late List<dynamic> steps;
  late Map<String, dynamic> workoutData;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  int totalStepDuration = 0;
  bool isResting = false;
  bool isPaused = false;
  bool workoutIsFinishedUI = false; // Controls the UI state (timer vs. finished screen)
  bool showingExercise = true; // New: true when showing exercise info, false when showing timer

  Timer? _timer;
  AnimationController? _progressController; // Still needed for internal logic, but not for circular UI
  AnimationController? _textPulseController; // For timer text pulsing animation
  Animation<double>? _textPulseAnimation;
  AnimationController? _finishAnimationController; // For workout finished animation
  Animation<double>? _finishScaleAnimation;
  Animation<double>? _finishFadeAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirestoreService _firestoreService = FirestoreService();

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
    _setupAnimations(); // Setup animation controllers
    // Don't auto-start - let user view exercise info first
    setState(() {
      showingExercise = true;
      isResting = false;
    });
  }

  void _setupAnimations() {
    // Controller for the pulsing effect on the timer text
    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Slightly faster pulse
      reverseDuration: const Duration(milliseconds: 700),
    );
    _textPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate( // More pronounced pulse
      CurvedAnimation(
        parent: _textPulseController!,
        curve: Curves.easeInOutSine, // Smoother sine wave curve
      ),
    );

    // Controller for the "Workout Complete" and checkmark animation
    _finishAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster finish animation
    );
    _finishScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _finishAnimationController!,
        curve: Curves.fastOutSlowIn, // A nice bouncy effect
      ),
    );
    _finishFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _finishAnimationController!,
        curve: Curves.easeIn,
      ),
    );
  }

  Future<void> _playStepSound() async {
    await _audioPlayer.play(AssetSource('sounds/step.mp3'));
  }

  Future<void> _playFinishSound() async {
    // Use the same step sound for finish since finish.mp3 doesn't exist
    await _audioPlayer.play(AssetSource('sounds/step.mp3'));
  }

  void startStep({bool rest = false}) {
    _timer?.cancel();
    _progressController?.dispose(); // Dispose old controller if exists
    _progressController = null;

    setState(() {
      isResting = rest;
      showingExercise = !rest; // Show exercise info for exercise, timer for rest
    });

    if (rest) {
      // Rest timer setup
      totalStepDuration = 30; // Default rest time
      currentStepTime = totalStepDuration;

      // Initialize new controller for rest duration
      _progressController = AnimationController(
        vsync: this,
        duration: Duration(seconds: totalStepDuration),
      );

      if (!isPaused) {
        _progressController!.forward(from: 0.0);
        _textPulseController!.repeat(reverse: true); // Start pulsing
      } else {
        _textPulseController!.stop(); // Stop pulsing if paused
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!isPaused) {
          if (currentStepTime > 0) {
            setState(() {
              currentStepTime--;
            });
            // Update progress controller value
            if (_progressController != null &&
                _progressController!.duration != null &&
                _progressController!.duration!.inSeconds > 0) {
              _progressController!.value =
                  1.0 - (currentStepTime / _progressController!.duration!.inSeconds);
            }
          } else {
            timer.cancel();
            await _playStepSound();
            goToNextStep();
          }
        }
      });
    }
    // For exercise steps, just show the info without starting timer
    setState(() {});
  }

  void goToNextStep() {
    _timer?.cancel();
    _progressController?.stop();
    _textPulseController?.stop(); // Stop pulsing when skipping/finishing

    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
        isPaused = false;
        showingExercise = true; // Show next exercise info
        isResting = false;
      });
      // Don't auto-start, let user view exercise info first
    } else {
      _prepareForFinishUI();
    }
  }

  void startExerciseTimer() {
    // Called when user clicks "Start Exercise" or "Next Step"
    if (!isResting && showingExercise) {
      // User finished current exercise, start rest timer
      startStep(rest: true);
    }
  }

  void skipRest() {
    // Skip rest and go to next exercise
    if (isResting) {
      _timer?.cancel();
      _progressController?.stop();
      _textPulseController?.stop();
      goToNextStep();
    }
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        _timer?.cancel();
        _progressController?.stop();
        _textPulseController?.stop(); // Stop pulsing when paused
      } else {
        // Resume animation from current value if it exists
        if (_progressController != null && totalStepDuration > 0) {
          _progressController!.forward(from: _progressController!.value);
        }
        _textPulseController?.repeat(reverse: true); // Resume pulsing when unpaused
        _startTimerHelper(); // Restart the timer
      }
    });
  }

  void _startTimerHelper() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!isPaused) {
        if (currentStepTime > 0) {
          setState(() {
            currentStepTime--;
          });
          if (_progressController != null &&
              _progressController!.duration != null &&
              _progressController!.duration!.inSeconds > 0) {
            _progressController!.value =
                1.0 - (currentStepTime / _progressController!.duration!.inSeconds);
          }
        } else {
          timer.cancel();
          await _playStepSound();

          if (isResting) {
            goToNextStep();
          } else {
            if (currentStepIndex < steps.length - 1) {
              startStep(rest: true);
            } else {
              _prepareForFinishUI();
            }
          }
        }
      }
    });
  }

  void _prepareForFinishUI() async {
    setState(() {
      workoutIsFinishedUI = true;
      currentStepIndex = steps.length; // Ensure this is set for 100% progress
    });

    _timer?.cancel();
    _progressController?.stop();
    _progressController?.dispose();
    _textPulseController?.stop(); // Stop pulsing
    _textPulseController?.dispose(); // Dispose pulsing controller

    // Start the finish animation
    _finishAnimationController?.forward();

    await _playFinishSound();

    // Save completed workout to Firestore
    try {
      // Create a Workout object from workoutData
      final workout = Workout(
        id: workoutData['id'] ?? '',
        name: workoutData['name'] ?? 'Unknown Workout',
        description: workoutData['description'] ?? '',
        duration: workoutData['duration'] ?? 30,
        calories: workoutData['calories'] ?? 200,
        category: workoutData['category'] ?? 'general',
        restTime: workoutData['restTime'] ?? 30,
        steps: List<Map<String, dynamic>>.from(workoutData['steps'] ?? []),
      );

      // Calculate actual duration (rough estimate based on steps)
      final actualDuration = steps.length * 2; // Assume 2 minutes per exercise on average
      final actualCalories = (workoutData['calories'] ?? 200) as int;

      await _firestoreService.saveWorkoutCompletion(
        workoutDetails: workout,
        finalDurationMinutes: actualDuration,
        finalCaloriesBurned: actualCalories,
      );
      
      print('Workout completion saved successfully!');
    } catch (e) {
      print('Error saving workout completion: $e');
      // Don't block the UI if saving fails
    }

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context, workoutData);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
    _textPulseController?.dispose(); // Dispose pulsing controller
    _finishAnimationController?.dispose(); // Dispose finish controller
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
    final stepTitle = isResting 
        ? "Rest Time" 
        : (step['name'] ?? step['text'] ?? 'Exercise ${currentStepIndex + 1}');
    final stepDescription = isResting
        ? "Take a short break before the next exercise."
        : (step['text'] ?? "Follow the exercise instructions.");

    final double overallProgress;
    if (workoutIsFinishedUI) {
      overallProgress = 1.0;
    } else {
      overallProgress = (currentStepIndex + (isResting ? 0.5 : 0)) / steps.length;
    }

    final bool isLastExerciseStep = currentStepIndex == steps.length - 1;
    final String primaryButtonText = showingExercise 
        ? (isLastExerciseStep ? 'FINISH WORKOUT' : 'NEXT STEP')
        : (isPaused ? 'RESUME' : 'PAUSE');
    final IconData primaryButtonIcon = showingExercise 
        ? (isLastExerciseStep ? Icons.check_circle : Icons.arrow_forward)
        : (isPaused ? Icons.play_arrow : Icons.pause);

    final String secondaryButtonText = showingExercise 
        ? 'SKIP EXERCISE' 
        : 'SKIP REST';
    final IconData secondaryButtonIcon = Icons.skip_next;

    final double circleSize = MediaQuery.of(context).size.width * 0.7;
    final double timerTextFontSize = 64;

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
            // Overall Workout Progress Bar
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

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                workoutIsFinishedUI
                    ? 'WORKOUT COMPLETE!'
                    : (isResting 
                        ? 'RESTING' 
                        : showingExercise 
                            ? 'EXERCISE ${currentStepIndex + 1} of ${steps.length}'
                            : 'STEP ${currentStepIndex + 1} of ${steps.length}'),
                key: ValueKey<String>(
                    workoutIsFinishedUI ? 'complete' : 'step-${currentStepIndex}-${isResting}-${showingExercise}'),
                style: const TextStyle( // Removed shadow
                  color: neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Step Card - Only show if not completely finished
            if (!workoutIsFinishedUI)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  // Add a subtle gradient border (using final for colors)
                  border: Border.all(color: neonGreen.withOpacity(0.2), width: 1.5), // Subtle border
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
                    if (showingExercise && !isResting)
                      Column(
                        children: [
                          Text(
                            'Reps: ${step['reps'] ?? 'N/A'} | Sets: ${step['sets'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: neonGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (step['duration'] != null && step['duration'] > 0)
                            Text(
                              'Duration: ${step['duration']} seconds',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      )
                    else if (isResting)
                      Text(
                        'Rest time remaining',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              )
            else
              // Show a message or celebratory animation when workout is complete
              FadeTransition(
                opacity: _finishFadeAnimation!,
                child: ScaleTransition(
                  scale: _finishScaleAnimation!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const Text(
                          'Great job!',
                          style: TextStyle( // Removed shadow
                            color: neonGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Workout completed.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Timer Display / Finish Check
            Flexible(
              child: Center(
                child: SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle (static, no progress indicator)
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: darkBg, // Solid background color
                          border: Border.all(color: Colors.grey[800]!, width: 4), // Subtle border
                        ),
                      ),
                      // Animated visibility for timer or checkmark
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: !workoutIsFinishedUI
                            ? showingExercise && !isResting
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fitness_center,
                                        size: circleSize * 0.3,
                                        color: neonGreen,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Ready?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : ScaleTransition(
                                    scale: _textPulseAnimation!,
                                    child: Text(
                                      '$currentStepTime s',
                                      key: ValueKey<int>(currentStepTime), // Key for AnimatedSwitcher
                                      style: TextStyle(
                                        color: neonGreen,
                                        fontSize: timerTextFontSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  )
                            : Container(
                                key: const ValueKey<String>('finished_check'),
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: neonGreen, // Solid neon green when finished
                                  // Removed border as the solid color makes it redundant
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: circleSize * 0.4,
                                  color: darkBg, // Checkmark color contrasts with neonGreen
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      foregroundColor: darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4, // Reduced elevation for a flatter look
                    ),
                    onPressed: !workoutIsFinishedUI 
                        ? (showingExercise && !isResting
                            ? () {
                                if (currentStepIndex == steps.length - 1) {
                                  _prepareForFinishUI();
                                } else {
                                  startExerciseTimer();
                                }
                              }
                            : togglePause)
                        : null,
                    icon: Icon(primaryButtonIcon, size: 28),
                    label: Text(
                      primaryButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4, // Reduced elevation
                    ),
                    onPressed: !workoutIsFinishedUI 
                        ? (showingExercise && !isResting
                            ? goToNextStep  // Skip exercise
                            : isResting 
                                ? skipRest  // Skip rest
                                : goToNextStep)  // Skip current step
                        : null,
                    icon: Icon(secondaryButtonIcon, size: 28),
                    label: Text(
                      secondaryButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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