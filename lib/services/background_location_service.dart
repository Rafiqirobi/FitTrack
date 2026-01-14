import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global variables to track location in background
double _backgroundDistanceMeters = 0.0;
Position? _lastBackgroundPosition;

@pragma('vm:entry-point')
void startLocationTracking() {
  // Start listening to position updates
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5, // Update every 5 meters
  );

  Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
    if (_lastBackgroundPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastBackgroundPosition!.latitude,
        _lastBackgroundPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      _backgroundDistanceMeters += delta;
    }
    _lastBackgroundPosition = pos;

    // Update foreground task notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'FitTrack Running',
      notificationText: '${(_backgroundDistanceMeters / 1000).toStringAsFixed(2)} km',
    );

    // Periodically save to SharedPreferences
    _saveLocationData();
  }, onError: (e) {
    print('Background location error: $e');
  });
}

void stopLocationTracking() {
  _backgroundDistanceMeters = 0.0;
  _lastBackgroundPosition = null;
  FlutterForegroundTask.updateService(
    notificationTitle: 'FitTrack',
    notificationText: 'Run stopped',
  );
}

Future<void> _saveLocationData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('backgroundDistance', _backgroundDistanceMeters);
}

Future<double> getBackgroundDistance() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('backgroundDistance') ?? 0.0;
}

Future<void> clearBackgroundDistance() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('backgroundDistance');
  _backgroundDistanceMeters = 0.0;
  _lastBackgroundPosition = null;
}

// Initialize foreground task
Future<void> initializeForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'fittrack_location_tracking',
      channelName: 'FitTrack Location Tracking',
      channelDescription: 'Notification for tracking runs in background',
      showBadge: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
}

// Start the foreground task
Future<void> startForegroundTask() async {
  if (await FlutterForegroundTask.isRunningService) {
    return;
  }

  await FlutterForegroundTask.startService(
    notificationTitle: 'FitTrack Running',
    notificationText: 'Location tracking active',
    callback: startLocationTracking,
  );
}

// Stop the foreground task
Future<void> stopForegroundTask() async {
  await FlutterForegroundTask.stopService();
}

// Check if foreground task is running
Future<bool> isForegroundTaskRunning() async {
  return await FlutterForegroundTask.isRunningService;
}
