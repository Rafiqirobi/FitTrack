import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:FitTrack/services/firestore_service.dart';
import 'package:FitTrack/models/workout_model.dart'; // Assuming this exists
import 'package:FitTrack/models/completed_workout_model.dart'; // Ensure this path is correct

class WorkoutTimerScreen extends StatefulWidget {
  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with TickerProviderStateMixin {
  late List<dynamic> steps;
  late Map<String, dynamic> workoutData;
  int currentStepIndex = 0;
  int currentStepTime = 0; // Time remaining for current timed step (rest or exercise with duration)
  int totalStepDuration = 0; // Total duration of the current timed step
  bool isResting = false;
  bool isPaused = false;
  bool workoutIsFinishedUI = false; // Controls the UI state (timer vs. finished screen)
  bool showingExerciseInfo = true; // true when showing exercise details, false when showing active timer

  Timer? _timer;
  AnimationController? _progressController; // For circular progress
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

  // New variable to track the start time of the entire workout session
  DateTime? _workoutSessionStartTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if workoutData is already set, preventing re-initialization on hot reload
    if (!mounted || steps.isNotEmpty) return;

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map<String, dynamic>) {
      workoutData = args;
      steps = workoutData['steps'] ?? [];
    } else {
      // Handle the case where arguments are null or not of the expected type
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid workout data received.')),
        );
        Navigator.pop(context);
      });
      return;
    }

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
      showingExerciseInfo = true;
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
    // Only play sound if not paused and not finished
    if (!isPaused && !workoutIsFinishedUI) {
      await _audioPlayer.play(AssetSource('sounds/step.mp3'));
    }
  }

  Future<void> _playFinishSound() async {
    await _audioPlayer.play(AssetSource('sounds/step.mp3'));
  }

  void startTimedStep({bool rest = false}) {
    _timer?.cancel();
    _progressController?.dispose(); // Dispose old controller if exists
    _progressController = null;

    setState(() {
      isResting = rest;
      showingExerciseInfo = false; // We are now in a timed segment
      isPaused = false; // Ensure not paused when starting new segment
    });

    // Capture workout start time if this is the very first step being timed
    if (_workoutSessionStartTime == null) {
      _workoutSessionStartTime = DateTime.now();
      print('Workout session started at: $_workoutSessionStartTime');
    }

    if (rest) {
      totalStepDuration = workoutData['restTime'] as int? ?? 30;
      currentStepTime = totalStepDuration;
    } else {
      // This is an exercise step with a duration
      totalStepDuration = steps[currentStepIndex]['duration'] as int? ?? 0;
      currentStepTime = totalStepDuration;
      if (totalStepDuration == 0) {
        // If an exercise has no duration, immediately go to rest or next exercise
        // This is for reps/sets exercises that don't have a timed component
        if (currentStepIndex < steps.length - 1) {
          // If not the last step, transition to rest
          startTimedStep(rest: true);
        } else {
          // If it's the last step and has no duration, finish the workout
          _prepareForFinishUI();
        }
        return; // Exit as we've handled the step or transitioned
      }
    }

    // Initialize new controller for current step duration
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalStepDuration),
    );

    // Only forward animation if not paused (i.e., when first starting or resuming)
    if (!isPaused) {
      _progressController!.forward(from: 0.0);
      _textPulseController!.repeat(reverse: true); // Start pulsing
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!isPaused) {
        if (currentStepTime > 0) {
          setState(() {
            currentStepTime--;
          });
          if (_progressController != null &&
              _progressController!.duration != null &&
              _progressController!.duration!.inSeconds > 0) {
            // Update progress controller value (from 0.0 to 1.0)
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

  void goToNextStep() {
    _timer?.cancel();
    _progressController?.stop();
    _textPulseController?.stop(); // Stop pulsing when skipping/finishing

    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
        isPaused = false;
        showingExerciseInfo = true; // Show next exercise info
        isResting = false;
        currentStepTime = 0; // Reset time for next step info display
        totalStepDuration = 0; // Reset total duration
      });
      // Don't auto-start, let user view exercise info first
    } else {
      _prepareForFinishUI();
    }
  }

  void startOrCompleteCurrentStep() {
    if (showingExerciseInfo) {
      // User is viewing exercise info and wants to start the current exercise or go to rest
      final currentExercise = steps[currentStepIndex];
      if (currentExercise['duration'] != null && (currentExercise['duration'] as int) > 0) {
        // If exercise has a duration, start its timer
        startTimedStep(rest: false);
      } else {
        // If exercise has no duration (reps/sets based), immediately go to rest
        startTimedStep(rest: true);
      }
    } else {
      // If currently in a timed segment (rest or timed exercise), the primary button is "Pause/Resume"
      togglePause();
    }
  }

  void skipCurrentSegment() {
    if (workoutIsFinishedUI) return; // Cannot skip if workout is finished

    if (showingExerciseInfo) {
      // If showing exercise info, skip the current exercise and go to next.
      goToNextStep();
    } else {
      // If currently in a timed segment (rest or timed exercise), skip it
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
        // Only resume timer if we were in an active timed segment
        if (!showingExerciseInfo && totalStepDuration > 0) {
          // Resume animation from current value if it exists
          if (_progressController != null) {
            _progressController!.forward(from: _progressController!.value);
          }
          _textPulseController?.repeat(reverse: true); // Resume pulsing when unpaused
          _startTimerHelper(); // Restart the timer
        }
      }
    });
  }

  void _startTimerHelper() {
    // This helper is specifically for resuming any active timer after pause
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
          goToNextStep();
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
      // Calculate actual duration based on session start time
      int finalDurationMinutes = 0;
      if (_workoutSessionStartTime != null) {
        finalDurationMinutes = DateTime.now().difference(_workoutSessionStartTime!).inMinutes;
        // Ensure duration is at least 1 minute if it's a very quick workout but not zero
        if (finalDurationMinutes == 0 && DateTime.now().difference(_workoutSessionStartTime!).inSeconds > 0) {
          finalDurationMinutes = 1;
        }
      } else {
        // Fallback if start time was never captured (e.g., direct finish without starting timer)
        // This might happen if user immediately clicks "Finish Workout" from the first exercise info screen
        finalDurationMinutes = workoutData['duration'] as int? ?? (steps.length * 2); // Fallback to estimated
        if (finalDurationMinutes == 0 && steps.isNotEmpty) finalDurationMinutes = 1; // Ensure at least 1 min if workout had steps
      }

      // Re-use the estimated calories from the workout data as actual.
      final int finalCaloriesBurned = (workoutData['calories'] as int? ?? 200);

      // Construct CompletedWorkout object with explicit casting for safety
      final completedWorkout = CompletedWorkout(
        id: '', // Firestore will generate this ID
        userId: _firestoreService.getCurrentUserId() ?? 'unknown', // Get current user ID
        workoutId: workoutData['id'] as String? ?? '',
        workoutName: workoutData['name'] as String? ?? 'Unknown Workout',
        actualDurationMinutes: finalDurationMinutes,
        actualCaloriesBurned: finalCaloriesBurned,
        timestamp: DateTime.now(),
        workoutCategory: workoutData['category'] as String? ?? 'Uncategorized',
      );

      // Pass the fully constructed CompletedWorkout object to FirestoreService
      await _firestoreService.saveWorkoutCompletion(completedWorkout);

      print('Workout completion saved successfully! Duration: $finalDurationMinutes mins, Calories: $finalCaloriesBurned');
    } catch (e) {
      print('Error saving workout completion: $e');
      // Optionally show a snackbar to the user about the save error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save workout: $e')),
      );
    }

    // Delay before popping the screen to allow animation and sound to play
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { // Check if the widget is still mounted before popping
        Navigator.pop(context, workoutData);
      }
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

    // Ensure we don't go out of bounds if workout finishes but UI hasn't popped yet
    final step = steps[currentStepIndex < steps.length ? currentStepIndex : steps.length - 1];
    final stepTitle = isResting
        ? "Rest Time"
        : (step['name'] as String? ?? step['text'] as String? ?? 'Exercise ${currentStepIndex + 1}');
    final stepDescription = isResting
        ? "Take a short break before the next exercise."
        : (step['text'] as String? ?? "Follow the exercise instructions.");

    final double overallProgress;
    if (workoutIsFinishedUI) {
      overallProgress = 1.0;
    } else {
      // More accurate progress: steps completed + proportion of current step
      double currentStepProgress = 0.0;
      if (!showingExerciseInfo && totalStepDuration > 0) {
        currentStepProgress = (totalStepDuration - currentStepTime) / totalStepDuration;
      }
      overallProgress = (currentStepIndex + currentStepProgress) / steps.length;
    }

    final bool isLastExerciseStep = currentStepIndex == steps.length - 1;
    final String primaryButtonText = showingExerciseInfo
        ? (isLastExerciseStep ? 'FINISH WORKOUT' : 'START EXERCISE')
        : (isPaused ? 'RESUME' : 'PAUSE');
    final IconData primaryButtonIcon = showingExerciseInfo
        ? (isLastExerciseStep ? Icons.check_circle : Icons.play_arrow)
        : (isPaused ? Icons.play_arrow : Icons.pause);

    final String secondaryButtonText = showingExerciseInfo
        ? 'SKIP EXERCISE'
        : 'SKIP'; // Unified skip text
    final IconData secondaryButtonIcon = Icons.skip_next;

    final double circleSize = MediaQuery.of(context).size.width * 0.7;
    final double timerTextFontSize = 64;

    // Determine if the circular progress indicator should be shown
    final bool showCircularProgress = !workoutIsFinishedUI && !showingExerciseInfo && totalStepDuration > 0;

    return PopScope(
      canPop: workoutIsFinishedUI, // Only allow popping if workout is finished
      onPopInvoked: (didPop) {
        if (!didPop && !workoutIsFinishedUI) {
          // If popped gesture is detected and workout isn't finished,
          // optionally show a confirmation dialog.
          // For now, we'll just prevent popping by not calling Navigator.pop
          // if workout is not finished.
          // You could add a showDialog here for "Are you sure you want to quit?"
        }
      },
      child: Scaffold(
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
          automaticallyImplyLeading: workoutIsFinishedUI, // Show back button only when finished
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
                          : showingExerciseInfo
                              ? 'EXERCISE ${currentStepIndex + 1} of ${steps.length}'
                              : 'STEP ${currentStepIndex + 1} of ${steps.length}'),
                  key: ValueKey<String>(
                      workoutIsFinishedUI ? 'complete' : 'step-${currentStepIndex}-${isResting}-${showingExerciseInfo}'),
                  style: const TextStyle(
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
                      if (showingExerciseInfo && !isResting)
                        Column(
                          children: [
                            Text(
                              'Reps: ${step['reps'] as int? ?? 'N/A'} | Sets: ${step['sets'] as int? ?? 'N/A'}',
                              style: const TextStyle(
                                color: neonGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (step['duration'] != null && (step['duration'] as int) > 0)
                              Text(
                                'Duration: ${step['duration']} seconds',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                          ],
                        )
                      else if (isResting)
                        const Text(
                          'Rest time remaining',
                          style: TextStyle(
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
                            style: TextStyle(
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
                            color: darkBg,
                            border: Border.all(color: Colors.grey[800]!, width: 4),
                          ),
                        ),
                        // Progress Indicator (only for timed steps where controller is initialized)
                        if (showCircularProgress && _progressController != null)
                          SizedBox(
                            width: circleSize,
                            height: circleSize,
                            child: AnimatedBuilder(
                              animation: _progressController!,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _progressController!.value,
                                  strokeWidth: 8,
                                  valueColor: const AlwaysStoppedAnimation<Color>(neonGreen),
                                  backgroundColor: Colors.transparent,
                                );
                              },
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
                              ? (showingExerciseInfo
                                  ? Column( // Show "Ready?" and icon when viewing exercise info
                                      key: const ValueKey<String>('ready_info'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          size: circleSize * 0.3,
                                          color: neonGreen,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Ready?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ScaleTransition( // Show timer when actively timing (rest or exercise with duration)
                                      key: ValueKey<int>(currentStepTime),
                                      scale: _textPulseAnimation!,
                                      child: Text(
                                        '$currentStepTime s',
                                        style: TextStyle(
                                          color: neonGreen,
                                          fontSize: timerTextFontSize,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ))
                              : Container( // Show checkmark when workout is finished
                                  key: const ValueKey<String>('finished_check'),
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: neonGreen,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: circleSize * 0.4,
                                    color: darkBg,
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
                        elevation: 4,
                      ),
                      onPressed: !workoutIsFinishedUI
                          ? (isLastExerciseStep && showingExerciseInfo
                              ? _prepareForFinishUI // If last exercise and showing info, "Finish Workout"
                              : startOrCompleteCurrentStep) // Otherwise, start/pause/resume
                          : null, // Disable button if workout is finished
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
                        elevation: 4,
                      ),
                      // Disable skip button if workout is finished or it's the very last step
                      onPressed: !workoutIsFinishedUI && !(isLastExerciseStep && showingExerciseInfo)
                          ? skipCurrentSegment
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
      ),
    );
  }
}