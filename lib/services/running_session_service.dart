import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

/// Global Running Session Service
/// Manages running state across the entire app and persists across page navigation
class RunningSessionService extends ChangeNotifier {
  static final RunningSessionService _instance = RunningSessionService._internal();

  factory RunningSessionService() {
    return _instance;
  }

  RunningSessionService._internal();

  // --- Running State ---
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  String _currentPaceStr = '--:--';
  DateTime? _startTime;
  DateTime? _sessionStartTime; // Actual start time for duration calculation
  
  // GPS Data (persists across navigation)
  List<LatLng> _routeCoordinates = [];
  int _totalDurationSeconds = 0; // Total elapsed time including paused periods
  Stopwatch? _internalStopwatch;
  
  // Timer for updating elapsed time
  Timer? _elapsedTimeTimer;

  // --- Getters ---
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  double get distanceKm => _distanceKm;
  String get currentPaceStr => _currentPaceStr;
  DateTime? get startTime => _startTime;
  List<LatLng> get routeCoordinates => _routeCoordinates;
  int get totalDurationSeconds => _totalDurationSeconds;
  
  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Start Running Session ---
  void startSession() {
    _isRunning = true;
    _startTime = DateTime.now();
    _sessionStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _distanceKm = 0.0;
    _currentPaceStr = '--:--';
    _routeCoordinates = [];
    _totalDurationSeconds = 0;
    _internalStopwatch = Stopwatch()..start();
    
    // Start timer to update elapsed time
    _startElapsedTimer();
    
    notifyListeners();
    print('🏃 Running session STARTED at $_startTime');
  }

  // --- Stop Running Session ---
  void stopSession() {
    _isRunning = false;
    _elapsedTimeTimer?.cancel();
    _internalStopwatch?.stop();
    _totalDurationSeconds = _elapsedSeconds;
    notifyListeners();
    print('🏃 Running session STOPPED - Total: $_elapsedSeconds seconds');
  }

  // --- Pause Session ---
  void pauseSession() {
    if (_internalStopwatch != null) {
      _internalStopwatch!.stop();
    }
    _elapsedTimeTimer?.cancel();
    print('⏸️ Session paused');
  }

  // --- Resume Session ---
  void resumeSession() {
    if (_internalStopwatch != null) {
      _internalStopwatch!.start();
    }
    _startElapsedTimer();
    print('▶️ Session resumed');
  }

  // --- Update Distance & Pace ---
  void updateDistance(double newDistanceKm, String paceStr) {
    _distanceKm = newDistanceKm;
    _currentPaceStr = paceStr;
    notifyListeners();
  }

  // --- Add route coordinate ---
  void addRouteCoordinate(LatLng coord) {
    _routeCoordinates.add(coord);
  }

  // --- Clear route coordinates ---
  void clearRoute() {
    _routeCoordinates.clear();
  }

  // --- Private: Update Elapsed Time ---
  void _startElapsedTimer() {
    _elapsedTimeTimer?.cancel();
    _elapsedTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _elapsedTimeTimer?.cancel();
    _internalStopwatch = null;
    super.dispose();
  }
}

/// Global singleton instance
final runningSession = RunningSessionService();
