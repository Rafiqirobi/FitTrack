import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

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
        _distanceMeters =
            runningSession.distanceKm * 1000; // Convert km to meters
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

      print(
          '✅ Synced with existing session: ${_timeElapsed}, ${runningSession.distanceKm.toStringAsFixed(2)} km');
    }
  }

  Future<void> _initializeMapLocation() async {
    try {
      // First try to get last known position (faster)
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null && mounted) {
        setState(() {
          _currentLocationLatLng =
              LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
        });
        print(
            '📍 Using last known location: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
        return;
      }

      // If no last known position, request current location
      final hasPermission = await _ensureLocationPermission();
      if (hasPermission) {
        print('📍 Requesting current location...');
        try {
          // Try with medium accuracy first (faster)
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit:
                const Duration(seconds: 30), // Longer timeout for poor signal
          );

          if (mounted) {
            setState(() {
              _currentLocationLatLng =
                  LatLng(position.latitude, position.longitude);
            });
            print(
                '📍 Got current location: ${position.latitude}, ${position.longitude}');
          }
        } catch (e) {
          // If medium accuracy fails, try with low accuracy (network-based, faster)
          print('⚠️ Medium accuracy failed, trying low accuracy...');
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 10),
            );
            if (mounted) {
              setState(() {
                _currentLocationLatLng =
                    LatLng(position.latitude, position.longitude);
              });
              print(
                  '📍 Got location with low accuracy: ${position.latitude}, ${position.longitude}');
            }
          } catch (e2) {
            print('⚠️ Low accuracy also failed: $e2');
            rethrow; // Let outer catch handle it
          }
        }
      } else {
        // Permission denied - show message and keep NYC fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission needed for accurate map positioning'),
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
            content: Text(
                'Could not get your location: ${e.toString().split('.').first}'),
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
        const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.')),
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
          content: const Text(
              'Location permission permanently denied. Please enable it from settings.'),
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
      // Request background location first (Android 10+)
      await _ensureBackgroundLocationPermission();

      // Then check notification permission (Android 13+)
      final bool notificationsOk = await _ensureNotificationPermission();
      if (notificationsOk) {
        await initializeForegroundTask();
        await startForegroundTask();
      } else {
        // Do not start foreground service without notification permission (Android 13+)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Notifications disabled. Background tracking may be limited.')),
          );
        }
      }
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
      _positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
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
                _paceSeconds = (_stopwatch.elapsedMilliseconds /
                        1000 /
                        (_distanceMeters / 1000))
                    .toInt();
              }
            });

            // 🌍 Update global running state (updates banner on all pages)
            final distanceKm = _distanceMeters / 1000;
            final paceStr = _formatDuration(Duration(seconds: _paceSeconds));
            runningSession.updateDistance(distanceKm, '$paceStr/km');

            print(
                '📍 Distance: ${distanceKm.toStringAsFixed(2)} km | Pace: $paceStr/km');
          }

          // Add to route and update map
          final newLatLng = LatLng(pos.latitude, pos.longitude);
          runningSession
              .addRouteCoordinate(newLatLng); // Sync with global state

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

  // Request Android 13+ notification permission safely with user prompt
  Future<bool> _ensureNotificationPermission() async {
    try {
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null)
        return true; // Non-Android or plugin unavailable

      final areEnabled = await androidPlugin.areNotificationsEnabled();
      if (areEnabled ?? true) return true;

      // Show dialog prompting user to enable notifications
      if (!mounted) return false;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'FitTrack needs notification permission to track your run in the background.\n\n'
            'Please enable notifications for this app in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('SKIP'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('OPEN SETTINGS'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
      // Re-check after user returns
      final nowEnabled = await androidPlugin.areNotificationsEnabled();
      return nowEnabled ?? false;
    } catch (e) {
      print('⚠️ Notification permission check failed: $e');
      return false;
    }
  }

  // Request background location for Android 10+ with user prompt
  Future<bool> _ensureBackgroundLocationPermission() async {
    try {
      // On Android 10+, background location is a separate permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always) return true;

      // If only whileInUse, prompt the user
      if (permission == LocationPermission.whileInUse) {
        if (!mounted) return false;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Allow Background Location'),
            content: const Text(
              'For uninterrupted GPS tracking while your screen is off, '
              'please grant "Allow all the time" location access in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('SKIP'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        // Re-check
        final updated = await Geolocator.checkPermission();
        return updated == LocationPermission.always;
      }

      return false;
    } catch (e) {
      print('⚠️ Background location permission check failed: $e');
      return false;
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
    print(
        '⏸️ Run paused - Time: $_timeElapsed | Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km');
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
        // If can't pop, navigate to main nav bar (not splash screen)
        print('⚠️ Cannot pop - navigating to home screen');
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/navBottomBar', (route) => false);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving run: $e')),
        );
      }
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
    List<Color> gradientColors;
    String label;

    if (_currentState == RunningState.notStarted ||
        _currentState == RunningState.stopped) {
      icon = Icons.play_arrow_rounded;
      onPressed = _startRun;
      gradientColors = [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      label = 'START';
    } else if (_currentState == RunningState.running) {
      icon = Icons.pause_rounded;
      onPressed = _pauseRun;
      gradientColors = [const Color(0xFFFFB347), const Color(0xFFFFCC33)];
      label = 'PAUSE';
    } else {
      // Paused
      icon = Icons.play_arrow_rounded;
      onPressed = _resumeRun;
      gradientColors = [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      label = 'RESUME';
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.white),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    if (_currentState == RunningState.running ||
        _currentState == RunningState.paused) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: GestureDetector(
          onTap: _stopRun,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'STOP & SAVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ⚠️ IMPORTANT: Only cancel stream if run is stopped
    // This allows the GPS tracking to continue even if user navigates away
    if (_currentState == RunningState.stopped ||
        _currentState == RunningState.notStarted) {
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
        if (_currentState == RunningState.running ||
            _currentState == RunningState.paused) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave Run?'),
              content: const Text(
                  'Your run is still active. You can return to it anytime using the run button.\n\n'
                  'GPS tracking will continue in the background.'),
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
                      content: Text(
                          'Location updated: ${_currentLocationLatLng!.latitude.toStringAsFixed(4)}, ${_currentLocationLatLng!.longitude.toStringAsFixed(4)}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive sizes based on screen height
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 600;
            final mapHeight = isSmallScreen
                ? 180.0
                : (screenHeight * 0.30).clamp(180.0, 280.0);
            final timerFontSize = isSmallScreen ? 52.0 : 64.0;
            final isDarkMode = theme.brightness == Brightness.dark;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  children: <Widget>[
                    // Map Section at the top
                    Container(
                      height: mapHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            _currentLocationLatLng == null
                                ? Container(
                                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: const Color(0xFF667EEA),
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Finding your location...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _currentLocationLatLng ??
                                          const LatLng(40.7128, -74.0060),
                                      initialZoom: 16,
                                      minZoom: 3,
                                      maxZoom: 18,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.fittrack.app',
                                      ),
                                      if (_routeCoordinates.isNotEmpty)
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: _routeCoordinates,
                                              color: const Color(0xFF667EEA),
                                              strokeWidth: 5,
                                            ),
                                          ],
                                        ),
                                      if (_currentLocationLatLng != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _currentLocationLatLng!,
                                              width: 50,
                                              height: 50,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 3),
                                                ),
                                                child: const Icon(
                                                  Icons.navigation_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                            // Status badge overlay
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _currentState == RunningState.running
                                      ? const Color(0xFF11998E)
                                      : _currentState == RunningState.paused
                                          ? const Color(0xFFFFB347)
                                          : isDarkMode
                                              ? Colors.black.withOpacity(0.7)
                                              : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentState == RunningState.running)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      _currentStatusText,
                                      style: TextStyle(
                                        color: _currentState == RunningState.running ||
                                                _currentState == RunningState.paused
                                            ? Colors.white
                                            : (isDarkMode ? Colors.white : Colors.black87),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Center on location button
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  if (_currentLocationLatLng != null) {
                                    _mapController.move(_currentLocationLatLng!, 16);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: const Color(0xFF667EEA),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 28),

                    // Timer Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                              : [Colors.white, Colors.grey[50]!],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _timeElapsed,
                            style: TextStyle(
                              fontSize: timerFontSize,
                              fontWeight: FontWeight.w900,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              letterSpacing: 2,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'DURATION',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value: (_distanceMeters / 1000).toStringAsFixed(2),
                            label: 'KM',
                            icon: Icons.straighten_rounded,
                            gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: _paceSeconds > 0
                                ? _formatDuration(Duration(seconds: _paceSeconds))
                                : '--:--',
                            label: 'PACE/KM',
                            icon: Icons.speed_rounded,
                            gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: (_distanceMeters > 0
                                ? ((_distanceMeters / 1000) * 60).toStringAsFixed(0)
                                : '0'),
                            label: 'KCAL',
                            icon: Icons.local_fire_department_rounded,
                            gradientColors: [const Color(0xFFFF512F), const Color(0xFFDD2476)],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Action Buttons - Row with Stop and Pause/Resume
                    if (_currentState == RunningState.running ||
                        _currentState == RunningState.paused)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stop Button
                          GestureDetector(
                            onTap: _stopRun,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop_rounded, color: Colors.white, size: 32),
                                  Text(
                                    'STOP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Pause/Resume Button
                          _buildActionButton(),
                        ],
                      )
                    else
                      _buildActionButton(),

                    // Navigation hint for active runs
                    if (_currentState == RunningState.running ||
                        _currentState == RunningState.paused)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'GPS tracking continues in background',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(height: isSmallScreen ? 16 : 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
