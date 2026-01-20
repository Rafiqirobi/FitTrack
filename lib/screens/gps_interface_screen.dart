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

  // Map controller for programmatic control
  final MapController _mapController = MapController();

  // Map state
  final List<LatLng> _routeCoordinates = [];
  LatLng? _currentLocationLatLng;

  @override
  void initState() {
    super.initState();
    _initializeMapLocation();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    // If there's already a running session, sync with it
    if (runningSession.isRunning) {
      print('🔄 Found existing running session, syncing...');
      setState(() {
        _currentState = RunningState.running;
        _currentStatusText = 'RUNNING';
        _distanceMeters = runningSession.distanceKm * 1000; // Convert km to meters
        _timeElapsed = runningSession.formattedTime;
        _routeCoordinates.clear();
        _routeCoordinates.addAll(runningSession.routeCoordinates);
        
        // Calculate pace if distance > 0
        if (_distanceMeters > 0) {
          final totalSeconds = runningSession.elapsedSeconds;
          _paceSeconds = (totalSeconds / (runningSession.distanceKm)).toInt();
        }
      });
      
      // Start timer to keep UI updated
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        final elapsed = runningSession.elapsedSeconds;
        setState(() {
          _timeElapsed = runningSession.formattedTime;
          // Update pace calculation
          if (_distanceMeters > 0) {
            _paceSeconds = (elapsed / (runningSession.distanceKm)).toInt();
          }
        });
      });
      
      print('✅ Synced with existing session: ${_timeElapsed}, ${runningSession.distanceKm.toStringAsFixed(2)} km');
    }
  }

  Future<void> _initializeMapLocation() async {
    try {
      // First try to get last known position (faster)
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null && mounted) {
        setState(() {
          _currentLocationLatLng = LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
        });
        print('📍 Using last known location: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
        return;
      }

      // If no last known position, request current location
      final hasPermission = await _ensureLocationPermission();
      if (hasPermission) {
        print('📍 Requesting current location...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds:15), // Increased timeout
        );

        if (mounted) {
          setState(() {
            _currentLocationLatLng = LatLng(position.latitude, position.longitude);
          });
          print('📍 Got current location: ${position.latitude}, ${position.longitude}');
        }
      } else {
        // Permission denied - show message and keep NYC fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission needed for accurate map positioning'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        print('⚠️ Location permission denied, using fallback location');
      }
    } catch (e) {
      print('⚠️ Could not get location: $e');
      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get your location: ${e.toString().split('.').first}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Final fallback - if still no location, use NYC
    if (_currentLocationLatLng == null && mounted) {
      setState(() {
        _currentLocationLatLng = const LatLng(40.7128, -74.0060); // NYC
      });
      print('📍 Using fallback location (New York City)');
    }
  }

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
    // If there's already a running session, don't start a new one
    if (runningSession.isRunning) {
      print('⚠️ Run already active, navigating to resume existing session');
      // Just update UI to match current session
      setState(() {
        _currentState = RunningState.running;
        _currentStatusText = 'RUNNING';
        _distanceMeters = runningSession.distanceKm * 1000;
        _timeElapsed = runningSession.formattedTime;
        _routeCoordinates.clear();
        _routeCoordinates.addAll(runningSession.routeCoordinates);
      });
      return;
    }

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

  void _stopRun() async {
    if (_currentState == RunningState.notStarted) return;

    print('🛑 Stopping run... Current state: $_currentState');

    setState(() {
      _currentState = RunningState.stopped;
      _currentStatusText = 'STOPPED';
    });

    // 🌍 Stop global running state (removes banner from all pages)
    runningSession.stopSession();
    print('✅ Global running session stopped');

    _stopwatch.stop();
    _positionStream?.cancel();
    _positionStream = null;
    _timer?.cancel();
    print('✅ Local timers and streams stopped');

    // Stop foreground task
    stopForegroundTask();
    stopLocationTracking();
    print('✅ Foreground task and location tracking stopped');

    // Save run to Firestore (await completion)
    await _saveRunToFirestore();

    // Show completion summary
    final meters = _distanceMeters;
    final elapsed = _stopwatch.elapsed;
    final km = (meters / 1000).toStringAsFixed(2);
    final time = _formatDuration(elapsed);

    print('\n🏁 RUN COMPLETED');
    print('⏱️ Time: $time');
    print('📍 Distance: $km km');
    print('${_routeCoordinates.length} waypoints recorded\n');

    // Show completion summary (safely)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Run saved — $km km in $time')),
      );
    }

    // Navigate after save is complete
    if (mounted) {
      // Try to pop normally first
      if (Navigator.of(context).canPop()) {
        print('✅ Can pop, navigating back...');
        Navigator.of(context).pop();
        print('✅ Successfully navigated back');
      } else {
        // If can't pop, navigate to home screen to avoid black screen
        print('⚠️ Cannot pop - navigating to home screen');
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } else {
      print('⚠️ Context not mounted - cannot navigate');
    }
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
        // If run is active, show confirmation dialog
        if (_currentState == RunningState.running || _currentState == RunningState.paused) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave Run?'),
              content: const Text(
                'Your run is still active. You can return to it anytime using the run button.\n\n'
                'GPS tracking will continue in the background.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Stay
                  child: const Text('STAY'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Leave
                  child: const Text('LEAVE'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
          if (shouldPop == true) {
            print('⏸️ User chose to leave run - GPS continues in background');
            return true;
          }
          return false; // Stay on GPS screen
        }
        return true; // Allow navigation if no active run
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Outdoor Run Tracker'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Refresh Location',
              onPressed: () async {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Getting your location...')),
                );

                // Refresh location
                await _initializeMapLocation();

                // Center map on new location
                if (_currentLocationLatLng != null) {
                  _mapController.move(_currentLocationLatLng!, 15);
                }

                // Show success message
                if (_currentLocationLatLng != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location updated: ${_currentLocationLatLng!.latitude.toStringAsFixed(4)}, ${_currentLocationLatLng!.longitude.toStringAsFixed(4)}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
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
              
              // Navigation hint for active runs
              if (_currentState == RunningState.running || _currentState == RunningState.paused)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tap run button to return to this screen anytime',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _currentLocationLatLng == null
                        ? Container(
                            color: theme.cardColor,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Finding your location...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Make sure location services are enabled',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentLocationLatLng ?? const LatLng(40.7128, -74.0060), // Default to NYC
                              initialZoom: 15,
                              minZoom: 3,
                              maxZoom: 18,
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
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
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