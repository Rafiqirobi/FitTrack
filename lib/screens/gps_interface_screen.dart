import 'package:flutter/material.dart';

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
  
  // Placeholder data for the interface
  final double _distanceKm = 0.0;
  final String _timeElapsed = '00:00:00';

  // --- State Management Functions ---

  void _startRun() {
    setState(() {
      _currentState = RunningState.running;
      _currentStatusText = 'RUNNING';
      // In a real app, start geolocator stream and timer here
    });
  }

  void _pauseRun() {
    setState(() {
      _currentState = RunningState.paused;
      _currentStatusText = 'PAUSED';
      // In a real app, pause timer and geolocator subscription here
    });
  }

  void _resumeRun() {
    setState(() {
      _currentState = RunningState.running;
      _currentStatusText = 'RUNNING';
      // In a real app, resume timer and geolocator subscription here
    });
  }

  void _stopRun() {
    setState(() {
      _currentState = RunningState.stopped;
      _currentStatusText = 'STOPPED';
      // In a real app, save data, stop timer, and reset state for next run
    });
    // Navigate back or show a summary modal after stopping
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }
  
  // --- UI Builders ---

  Widget _buildActionButton() {
    IconData icon;
    String tooltip;
    VoidCallback onPressed;
    Color backgroundColor = Theme.of(context).colorScheme.primary;

    if (_currentState == RunningState.notStarted || _currentState == RunningState.stopped) {
      icon = Icons.directions_run_rounded;
      tooltip = 'Start Run';
      onPressed = _startRun;
    } else if (_currentState == RunningState.running) {
      icon = Icons.pause_rounded;
      tooltip = 'Pause Run';
      onPressed = _pauseRun;
      backgroundColor = Colors.amber; // Change color when running
    } else { // Paused
      icon = Icons.play_arrow_rounded;
      tooltip = 'Resume Run';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
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
                        _distanceKm.toStringAsFixed(2),
                        style: theme.textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Distance (km)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Dumb Map Placeholder Interface
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Light grey for map background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 60, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Live Map Placeholder',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        Text(
                          '(Actual map integration coming soon)',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
    );
  }
}