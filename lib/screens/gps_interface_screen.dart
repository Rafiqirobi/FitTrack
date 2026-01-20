import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/background_location_service.dart';
import '../services/firestore_service.dart';
import '../services/running_session_service.dart'; // Global running state
import '../models/run_route_model.dart';

// Enum to manage the different states of the running session
enum RunningState { notStarted, running, paused, stopped }

class GpsInterfaceScreen extends StatefulWidget {
  const GpsInterfaceScreen({super.key});

  @override
  State<GpsInterfaceScreen> createState() => _GpsInterfaceScreenState();
}

class _GpsInterfaceScreenState extends State<GpsInterfaceScreen> {
  RunningState _currentState = RunningState.notStarted;
  String _currentStatusText = 'Ready to Run';

  // Runtime state
  double _distanceMeters = 0.0;
  String _timeElapsed = '00:00:00';
  int _paceSeconds = 0; // Pace in seconds per km

  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // Map state
  final List<LatLng> _routeCoordinates = [];
  LatLng? _currentLocationLatLng;

  // --- Permission & Location Helpers ---
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission permanently denied. Please enable it from settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  // --- State Management Functions ---
  Future<void> _startRun() async {
    final ok = await _ensureLocationPermission();
    if (!ok) return;

    setState(() {
      _currentState = RunningState.running;
      _currentStatusText = 'RUNNING';
      _distanceMeters = 0.0;
      _lastPosition = null;
      _routeCoordinates.clear();
      _paceSeconds = 0;
    });

    // 🌍 Update global running state (shows banner on all pages)
    runningSession.startSession();
    runningSession.clearRoute();

    // Start foreground task for background tracking
    try {
      await initializeForegroundTask();
      await startForegroundTask();
    } catch (e) {
      print('⚠️ Foreground task error: $e');
    }

    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    
    // Create timer that updates every 500ms
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return; // Check if widget is still mounted
      
      final elapsed = _stopwatch.elapsed;
      setState(() {
        _timeElapsed = _formatDuration(elapsed);
      });
    });
    print('✅ Run started - Timer active (updates every 500ms)');

    // Start listening to position updates (foreground)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // meters
    );

    try {
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (pos) {
          if (!mounted) return;
          
          if (_lastPosition != null) {
            final delta = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              pos.latitude,
              pos.longitude,
            );
            setState(() {
              _distanceMeters += delta;
              // Calculate pace (seconds per km)
              if (_distanceMeters > 0) {
                _paceSeconds = (_stopwatch.elapsedMilliseconds / 1000 / (_distanceMeters / 1000)).toInt();
              }
            });
            
            // 🌍 Update global running state (updates banner on all pages)
            final distanceKm = _distanceMeters / 1000;
            final paceStr = _formatDuration(Duration(seconds: _paceSeconds));
            runningSession.updateDistance(distanceKm, '$paceStr/km');
            
            print('📍 Distance: ${distanceKm.toStringAsFixed(2)} km | Pace: $paceStr/km');
          }
          
          // Add to route and update map
          final newLatLng = LatLng(pos.latitude, pos.longitude);
          runningSession.addRouteCoordinate(newLatLng); // Sync with global state
          
          setState(() {
            _routeCoordinates.add(newLatLng);
            _currentLocationLatLng = newLatLng;
            _updatePolyline();
          });
          
          _lastPosition = pos;
        },
        onError: (e) {
          print('❌ Location stream error: $e');
        },
        cancelOnError: false,
      );
      print('✅ GPS stream started');
    } catch (e) {
      print('❌ Failed to start GPS stream: $e');
    }
  }

  void _pauseRun() {
    if (_currentState != RunningState.running) return;
    setState(() {
      _currentState = RunningState.paused;
      _currentStatusText = 'PAUSED';
    });
    _stopwatch.stop();
    runningSession.pauseSession(); // Sync with global state
    _positionStream?.pause();
    _timer?.cancel();
    print('⏸️ Run paused - Time: $_timeElapsed | Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km');
  }

  void _resumeRun() {
    if (_currentState != RunningState.paused) return;
    setState(() {
      _currentState = RunningState.running;
      _currentStatusText = 'RUNNING';
    });
    _stopwatch.start();
    runningSession.resumeSession(); // Sync with global state
    _positionStream?.resume();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final elapsed = _stopwatch.elapsed;
      setState(() {
        _timeElapsed = _formatDuration(elapsed);
      });
    });
    print('▶️ Run resumed - Continuing from $_timeElapsed');
  }

  void _stopRun() {
    if (_currentState == RunningState.notStarted) return;
    setState(() {
      _currentState = RunningState.stopped;
      _currentStatusText = 'STOPPED';
    });

    // 🌍 Stop global running state (removes banner from all pages)
    runningSession.stopSession();

    _stopwatch.stop();
    _positionStream?.cancel();
    _positionStream = null;
    _timer?.cancel();

    // Stop foreground task
    stopForegroundTask();
    stopLocationTracking();

    // Save run to Firestore
    _saveRunToFirestore();

    // Show completion summary
    final meters = _distanceMeters;
    final elapsed = _stopwatch.elapsed;
    final km = (meters / 1000).toStringAsFixed(2);
    final time = _formatDuration(elapsed);
    
    print('\n🏁 RUN COMPLETED');
    print('⏱️ Time: $time');
    print('📍 Distance: $km km');
    print('${_routeCoordinates.length} waypoints recorded\n');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Run saved — $km km in $time')),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  Future<void> _saveRunToFirestore() async {
    try {
      final runRoute = RunRoute(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        coordinates: _routeCoordinates,
        startTime: DateTime.now().subtract(_stopwatch.elapsed),
        endTime: DateTime.now(),
        totalDistanceMeters: _distanceMeters,
        durationSeconds: _stopwatch.elapsed.inSeconds,
      );

      final firestoreService = FirestoreService();
      await firestoreService.saveRun(runRoute);
      
      print('✅ Run successfully saved to Firestore');
    } catch (e) {
      print('❌ Error saving run to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving run: $e')),
      );
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  void _updatePolyline() {
    // Rebuild is handled by the caller's setState to avoid nested setState calls.
    if (_routeCoordinates.isEmpty) return;
  }

  // --- UI Builders ---
  Widget _buildActionButton() {
    IconData icon;
    VoidCallback onPressed;
    Color backgroundColor = Theme.of(context).colorScheme.primary;

    if (_currentState == RunningState.notStarted || _currentState == RunningState.stopped) {
      icon = Icons.directions_run_rounded;
      onPressed = _startRun;
    } else if (_currentState == RunningState.running) {
      icon = Icons.pause_rounded;
      onPressed = _pauseRun;
      backgroundColor = Colors.amber; // Change color when running
    } else { // Paused
      icon = Icons.play_arrow_rounded;
      onPressed = _resumeRun;
      backgroundColor = Colors.green; // Change color when paused
    }

    return FloatingActionButton.large(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      child: Icon(icon, size: 48, color: Theme.of(context).scaffoldBackgroundColor),
    );
  }

  Widget _buildStopButton() {
    if (_currentState == RunningState.running || _currentState == RunningState.paused) {
      return Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: ElevatedButton.icon(
          onPressed: _stopRun,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('STOP AND SAVE'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onError,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    // ⚠️ IMPORTANT: Only cancel stream if run is stopped
    // This allows the GPS tracking to continue even if user navigates away
    if (_currentState == RunningState.stopped || _currentState == RunningState.notStarted) {
      _positionStream?.cancel();
      _timer?.cancel();
      _stopwatch.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // If run is active, allow navigation (user can return via banner)
        if (_currentState == RunningState.running || _currentState == RunningState.paused) {
          print('⏸️ User navigated away while running - GPS continues in background');
          return true; // Allow navigation
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Outdoor Run Tracker'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Status Indicator
                Text(
                  _currentStatusText,
                  style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // Time Elapsed (Main Metric)
              Text(
                _timeElapsed,
                style: theme.textTheme.displayLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 72,
                ),
              ),
              Text(
                'TIME ELAPSED',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 40),

              // Distance Metric
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        (_distanceMeters / 1000).toStringAsFixed(2),
                        style: theme.textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Distance (km)',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (_paceSeconds > 0)
                        Column(
                          children: [
                            Text(
                              _formatDuration(Duration(seconds: _paceSeconds)),
                              style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                            ),
                            const Text(
                              'Per Kilometer',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Map with OpenStreetMap (free, no API key needed)
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLocationLatLng ?? const LatLng(0, 0),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fittrack.app',
                    ),
                    if (_routeCoordinates.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeCoordinates,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    if (_currentLocationLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocationLatLng!,
                            width: 40,
                            height: 40,
                            child: Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Action Button (Start/Pause/Resume)
              _buildActionButton(),

              // Stop Button (Only visible when running or paused)
              _buildStopButton(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      ),
    );
  }
}