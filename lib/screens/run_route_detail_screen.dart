import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/run_route_model.dart';

/// Detailed screen showing the run route on a map with stats
class RunRouteDetailScreen extends StatefulWidget {
  final RunRoute run;

  const RunRouteDetailScreen({super.key, required this.run});

  @override
  State<RunRouteDetailScreen> createState() => _RunRouteDetailScreenState();
}

class _RunRouteDetailScreenState extends State<RunRouteDetailScreen> {
  final MapController _mapController = MapController();
  String _locationName = 'Loading...';
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    if (widget.run.coordinates.isEmpty) {
      setState(() => _locationName = 'Unknown Location');
      return;
    }

    try {
      final startPoint = widget.run.coordinates.first;
      final placemarks = await placemarkFromCoordinates(
        startPoint.latitude,
        startPoint.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        String name = '';

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          name = place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          name = name.isEmpty ? place.locality! : '$name, ${place.locality}';
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          name = name.isEmpty
              ? place.administrativeArea!
              : '$name, ${place.administrativeArea}';
        }

        setState(
            () => _locationName = name.isEmpty ? 'Unknown Location' : name);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationName = 'Unknown Location');
      }
    }
  }

  /// Calculate the bounds of the route to fit the map
  LatLngBounds? _getRouteBounds() {
    if (widget.run.coordinates.isEmpty) return null;

    double minLat = widget.run.coordinates.first.latitude;
    double maxLat = widget.run.coordinates.first.latitude;
    double minLng = widget.run.coordinates.first.longitude;
    double maxLng = widget.run.coordinates.first.longitude;

    for (var coord in widget.run.coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    // Add some padding
    const padding = 0.002;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatPace(Duration pace) {
    final minutes = pace.inMinutes;
    final seconds = pace.inSeconds.remainder(60);
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final run = widget.run;

    // Calculate stats
    final distance = run.totalDistanceMeters / 1000;
    final duration = Duration(seconds: run.durationSeconds);
    final pace = run.totalDistanceMeters > 0
        ? Duration(
            seconds: ((run.durationSeconds * 1000) / run.totalDistanceMeters)
                .toInt())
        : Duration.zero;
    final avgSpeed = run.durationSeconds > 0
        ? (run.totalDistanceMeters / run.durationSeconds) * 3.6 // km/h
        : 0.0;
    final calories = (distance * 60).round(); // ~60 cal/km estimate

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Map
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: theme.primaryColor),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share, color: theme.primaryColor),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMap(isDarkMode),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_run,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Running',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(run.startTime),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Main Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                            : [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        // Distance - Large Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              distance.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'km',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 16),

                        // Secondary Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.timer,
                              label: 'Duration',
                              value: _formatDuration(duration),
                              color: Colors.blue,
                            ),
                            _buildStatItem(
                              icon: Icons.speed,
                              label: 'Pace',
                              value: '${_formatPace(pace)}/km',
                              color: Colors.orange,
                            ),
                            _buildStatItem(
                              icon: Icons.local_fire_department,
                              label: 'Calories',
                              value: '$calories kcal',
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Additional Stats
                  Text(
                    'Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Details Grid
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          icon: Icons.play_arrow,
                          label: 'Start Time',
                          value: DateFormat('HH:mm:ss').format(run.startTime),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        _buildDetailRow(
                          context,
                          icon: Icons.stop,
                          label: 'End Time',
                          value: run.endTime != null
                              ? DateFormat('HH:mm:ss').format(run.endTime!)
                              : 'N/A',
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        _buildDetailRow(
                          context,
                          icon: Icons.speed,
                          label: 'Avg Speed',
                          value: '${avgSpeed.toStringAsFixed(1)} km/h',
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                        _buildDetailRow(
                          context,
                          icon: Icons.route,
                          label: 'GPS Points',
                          value: '${run.coordinates.length} points',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // View Full Map Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showFullScreenMap(context),
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      label: const Text(
                        'View Full Map',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FACFE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDarkMode) {
    if (widget.run.coordinates.isEmpty) {
      return Container(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No route data available',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final bounds = _getRouteBounds();
    final startPoint = widget.run.coordinates.first;
    final endPoint = widget.run.coordinates.last;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: startPoint,
        initialZoom: 15,
        onMapReady: () {
          if (bounds != null) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
          setState(() => _isMapReady = true);
        },
      ),
      children: [
        // Map tiles
        TileLayer(
          urlTemplate: isDarkMode
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),

        // Route polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.run.coordinates,
              color: const Color(0xFF4FACFE),
              strokeWidth: 5,
            ),
          ],
        ),

        // Start and End markers
        MarkerLayer(
          markers: [
            // Start marker (green)
            Marker(
              point: startPoint,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ),
            // End marker (red)
            Marker(
              point: endPoint,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenMapView(run: widget.run),
      ),
    );
  }
}

/// Full screen map view
class _FullScreenMapView extends StatefulWidget {
  final RunRoute run;

  const _FullScreenMapView({required this.run});

  @override
  State<_FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<_FullScreenMapView> {
  final MapController _mapController = MapController();

  LatLngBounds? _getRouteBounds() {
    if (widget.run.coordinates.isEmpty) return null;

    double minLat = widget.run.coordinates.first.latitude;
    double maxLat = widget.run.coordinates.first.latitude;
    double minLng = widget.run.coordinates.first.longitude;
    double maxLng = widget.run.coordinates.first.longitude;

    for (var coord in widget.run.coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    const padding = 0.002;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bounds = _getRouteBounds();
    final startPoint = widget.run.coordinates.isNotEmpty
        ? widget.run.coordinates.first
        : const LatLng(0, 0);
    final endPoint = widget.run.coordinates.isNotEmpty
        ? widget.run.coordinates.last
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              if (bounds != null) {
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                );
              }
            },
            tooltip: 'Fit route',
          ),
        ],
      ),
      body: widget.run.coordinates.isEmpty
          ? const Center(child: Text('No route data available'))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: startPoint,
                initialZoom: 15,
                onMapReady: () {
                  if (bounds != null) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                      ),
                    );
                  }
                },
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
                      points: widget.run.coordinates,
                      color: const Color(0xFF4FACFE),
                      strokeWidth: 6,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startPoint,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    Marker(
                      point: endPoint,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.stop,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
