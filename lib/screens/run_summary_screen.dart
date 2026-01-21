import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:confetti/confetti.dart';
import '../models/run_route_model.dart';
import '../services/firestore_service.dart';

class RunSummaryScreen extends StatefulWidget {
  final List<LatLng> routeCoordinates;
  final double distanceMeters;
  final Duration duration;
  final int paceSeconds; // seconds per km
  final DateTime startTime;

  const RunSummaryScreen({
    super.key,
    required this.routeCoordinates,
    required this.distanceMeters,
    required this.duration,
    required this.paceSeconds,
    required this.startTime,
  });

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final MapController _mapController = MapController();
  
  bool _isSaving = false;
  bool _showSuccess = false;
  
  // Animation controllers
  late AnimationController _checkAnimationController;
  late Animation<double> _checkScaleAnimation;
  late Animation<double> _checkOpacityAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    
    // Initialize check animation
    _checkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _checkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _checkOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Initialize confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _captionController.dispose();
    _checkAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatPace(int paceSeconds) {
    if (paceSeconds <= 0) return '--:--';
    final minutes = paceSeconds ~/ 60;
    final seconds = paceSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _calculateCalories() {
    // Rough estimate: ~60 calories per km for running
    final km = widget.distanceMeters / 1000;
    return km * 60;
  }

  LatLng _getMapCenter() {
    if (widget.routeCoordinates.isEmpty) {
      return const LatLng(40.7128, -74.0060); // Default NYC
    }
    
    double minLat = widget.routeCoordinates.first.latitude;
    double maxLat = widget.routeCoordinates.first.latitude;
    double minLng = widget.routeCoordinates.first.longitude;
    double maxLng = widget.routeCoordinates.first.longitude;
    
    for (var coord in widget.routeCoordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }
    
    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  Future<void> _confirmAndSave() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final runRoute = RunRoute(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        coordinates: widget.routeCoordinates,
        startTime: widget.startTime,
        endTime: DateTime.now(),
        totalDistanceMeters: widget.distanceMeters,
        durationSeconds: widget.duration.inSeconds,
        caption: _captionController.text.trim().isEmpty 
            ? null 
            : _captionController.text.trim(),
      );

      final firestoreService = FirestoreService();
      await firestoreService.saveRun(runRoute);

      // Show success animation
      setState(() {
        _showSuccess = true;
      });
      
      _checkAnimationController.forward();
      _confettiController.play();

      // Wait for animation then navigate
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/navBottomBar', (route) => false);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving run: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _discardRun() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Discard Run?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to discard this run? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/navBottomBar', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final distanceKm = widget.distanceMeters / 1000;
    final calories = _calculateCalories();

    if (_showSuccess) {
      return _buildSuccessScreen(isDarkMode);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).primaryColor),
          onPressed: _discardRun,
        ),
        title: Text(
          'Run Complete! 🎉',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map showing route
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.routeCoordinates.isEmpty
                  ? Center(
                      child: Text(
                        'No route recorded',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _getMapCenter(),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDarkMode
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: widget.routeCoordinates,
                              color: Colors.blue,
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            if (widget.routeCoordinates.isNotEmpty) ...[
                              // Start marker
                              Marker(
                                point: widget.routeCoordinates.first,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              // End marker
                              Marker(
                                point: widget.routeCoordinates.last,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${distanceKm.toStringAsFixed(2)} km',
                    color: Colors.blue,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(widget.duration),
                    color: Colors.orange,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.speed,
                    label: 'Avg Pace',
                    value: '${_formatPace(widget.paceSeconds)}/km',
                    color: Colors.purple,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${calories.toStringAsFixed(0)} kcal',
                    color: Colors.red,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Caption Input
            Text(
              'Add a caption (optional)',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'How was your run? 🏃‍♂️',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _confirmAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Save Run',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Discard Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _discardRun,
                child: Text(
                  'Discard Run',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[isDarkMode ? 400 : 600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDarkMode) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
          
          // Success Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Check Icon
                AnimatedBuilder(
                  animation: _checkAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _checkOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _checkScaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Success Text
                Text(
                  'Run Saved! 🎉',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Great job on completing your run!',
                  style: TextStyle(
                    color: Colors.grey[isDarkMode ? 400 : 600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(widget.distanceMeters / 1000).toStringAsFixed(2)} km in ${_formatDuration(widget.duration)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
