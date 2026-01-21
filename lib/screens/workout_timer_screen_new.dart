import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:FitTrack/services/firestore_service.dart';
import 'package:FitTrack/models/completed_workout_model.dart';

class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key});

  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with TickerProviderStateMixin {
  List<dynamic> steps = [];
  late Map<String, dynamic> workoutData;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  int totalStepDuration = 0;
  bool isResting = false;
  bool isPaused = false;
  bool workoutIsFinished = false;
  bool showingExerciseInfo = true;
  bool _isInitialized = false;

  Timer? _timer;
  AnimationController? _progressController;
  AnimationController? _textPulseController;
  Animation<double>? _textPulseAnimation;
  AnimationController? _finishAnimationController;
  Animation<double>? _finishScaleAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirestoreService _firestoreService = FirestoreService();
  DateTime? _workoutSessionStartTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args = ModalRoute.of(context)!.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      workoutData = args;
      steps = workoutData['steps'] ?? [];
      _isInitialized = true;
    } else {
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
          const SnackBar(content: Text('No workout steps available.')),
        );
        Navigator.pop(context);
      });
      return;
    }
    
    _setupAnimations();
    setState(() {
      showingExerciseInfo = true;
      isResting = false;
    });
  }

  void _setupAnimations() {
    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 700),
    );
    _textPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _textPulseController!,
        curve: Curves.easeInOut,
      ),
    );

    _finishAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _finishScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _finishAnimationController!,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _startExercise() {
    if (showingExerciseInfo) {
      setState(() {
        showingExerciseInfo = false;
        _workoutSessionStartTime ??= DateTime.now();
      });
      _startCurrentStep();
    }
  }

  void _startCurrentStep() {
    if (currentStepIndex >= steps.length) {
      _finishWorkout();
      return;
    }

    final step = steps[currentStepIndex];
    final duration = step['duration'] as int? ?? 30;
    
    setState(() {
      currentStepTime = duration;
      totalStepDuration = duration;
      isPaused = false;
    });

    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: duration),
    );

    _progressController!.forward();
    _textPulseController?.repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && currentStepTime > 0) {
        setState(() {
          currentStepTime--;
        });
      } else if (currentStepTime <= 0) {
        timer.cancel();
        _playStepSound();
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (!isResting && steps[currentStepIndex]['rest'] != null) {
      // Start rest period
      setState(() {
        isResting = true;
        currentStepTime = steps[currentStepIndex]['rest'] as int;
        totalStepDuration = currentStepTime;
      });
      _startTimer();
    } else {
      // Check if this was the last step
      if (currentStepIndex >= steps.length - 1) {
        // All exercises completed or skipped, go back
        Navigator.pop(context);
        return;
      }
      // Move to next exercise
      setState(() {
        currentStepIndex++;
        isResting = false;
        showingExerciseInfo = true;
      });
      _textPulseController?.stop();
    }
  }

  void _skipStep() {
    _timer?.cancel();
    _textPulseController?.stop();
    _nextStep();
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    
    if (isPaused) {
      _progressController?.stop();
      _textPulseController?.stop();
    } else {
      _progressController?.forward();
      _textPulseController?.repeat(reverse: true);
    }
  }

  void _finishWorkout() async {
    setState(() {
      workoutIsFinished = true;
    });

    _timer?.cancel();
    _progressController?.dispose();
    _textPulseController?.dispose();
    _finishAnimationController?.forward();

    // Save workout
    try {
      final duration = _workoutSessionStartTime != null 
        ? DateTime.now().difference(_workoutSessionStartTime!).inMinutes
        : workoutData['duration'] ?? 30;

      final completedWorkout = CompletedWorkout(
        id: '', // Will be set by Firestore
        userId: '', // Will be set by FirestoreService
        workoutId: workoutData['id'] ?? '',
        workoutName: workoutData['name'] ?? 'Unknown Workout',
        actualDurationMinutes: duration,
        actualCaloriesBurned: workoutData['calories'] ?? 100,
        timestamp: DateTime.now(),
        workoutCategory: workoutData['category'] ?? 'General',
      );

      await _firestoreService.saveWorkoutCompletion(completedWorkout);
    } catch (e) {
      print('Error saving workout: $e');
    }
  }

  Future<void> _playStepSound() async {
    try {
      await _audioPlayer.play(AssetSource('lib/assets/sounds/step.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _showExitConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Exit Workout?',
                style: TextStyle(
                  color: theme.textTheme.headlineMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to exit? Your progress will be lost.',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
    _textPulseController?.dispose();
    _finishAnimationController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : Colors.black87);
    
    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'No workout steps available.',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    if (workoutIsFinished) {
      return _buildFinishedScreen(theme, primaryColor, textColor);
    }

    if (showingExerciseInfo) {
      return _buildExerciseInfoScreen(theme, primaryColor, cardColor, textColor);
    }

    return _buildTimerScreen(theme, primaryColor, cardColor, textColor, isDarkMode);
  }

  Widget _buildFinishedScreen(ThemeData theme, Color primaryColor, Color textColor) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WORKOUT COMPLETE!',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _finishScaleAnimation ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: _finishScaleAnimation?.value ?? 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 100,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You\'ve completed your workout!',
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FACFE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text(
                      'FINISH',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExerciseInfoScreen(ThemeData theme, Color primaryColor, Color cardColor, Color textColor) {
    final step = steps[currentStepIndex];
    final isLastStep = currentStepIndex == steps.length - 1;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'EXERCISE ${currentStepIndex + 1} OF ${steps.length}',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: currentStepIndex / steps.length,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 8,
              ),
              const SizedBox(height: 30),
              
              // Exercise card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        step['name'] ?? 'Exercise ${currentStepIndex + 1}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (step['text'] != null)
                        Text(
                          step['text'],
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 30),
                      
                      // Exercise details
                      if (step['duration'] != null)
                        _buildDetailRow(Icons.timer, 'Duration', '${step['duration']} seconds', textColor),
                      if (step['sets'] != null)
                        _buildDetailRow(Icons.repeat, 'Sets', '${step['sets']}', textColor),
                      if (step['reps'] != null)
                        _buildDetailRow(Icons.fitness_center, 'Reps', '${step['reps']}', textColor),
                      if (step['rest'] != null)
                        _buildDetailRow(Icons.pause, 'Rest', '${step['rest']} seconds', textColor),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skipStep,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLastStep ? _finishWorkout : _startExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FACFE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isLastStep ? 'FINISH WORKOUT' : 'START',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildTimerScreen(ThemeData theme, Color primaryColor, Color cardColor, Color textColor, bool isDarkMode) {
    final step = steps[currentStepIndex];
    final stepTitle = isResting ? "Rest Time" : (step['name'] ?? 'Exercise ${currentStepIndex + 1}');
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'WORKOUT TIMER',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                ? [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)]
                : [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: currentStepIndex / steps.length,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exercise ${currentStepIndex + 1} of ${steps.length}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timer circle
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      children: [
                        // Circular progress
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: totalStepDuration > 0 
                              ? (totalStepDuration - currentStepTime) / totalStepDuration 
                              : 0.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isResting ? Colors.orange : primaryColor,
                            ),
                          ),
                        ),
                        // Timer content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stepTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isResting ? Colors.orange : primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              AnimatedBuilder(
                                animation: _textPulseAnimation ?? const AlwaysStoppedAnimation(1.0),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _textPulseAnimation?.value ?? 1.0,
                                    child: Text(
                                      _formatTime(currentStepTime),
                                      style: TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Control buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipStep,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'SKIP',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _togglePause,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FACFE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isPaused ? 'RESUME' : 'PAUSE',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
