import 'package:latlong2/latlong.dart';

class RunRoute {
  final String id;
  final List<LatLng> coordinates;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceMeters;
  final int durationSeconds;

  RunRoute({
    required this.id,
    required this.coordinates,
    required this.startTime,
    this.endTime,
    required this.totalDistanceMeters,
    required this.durationSeconds,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coordinates': coordinates
          .map((latLng) => {
                'latitude': latLng.latitude,
                'longitude': latLng.longitude,
              })
          .toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDistanceMeters': totalDistanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  // Create from map
  factory RunRoute.fromMap(Map<String, dynamic> data, {required String id}) {
    final coordsList = (data['coordinates'] as List<dynamic>?) ?? [];
    final coordinates = coordsList
        .map((coord) => LatLng(
              coord['latitude'] as double,
              coord['longitude'] as double,
            ))
        .toList();

    return RunRoute(
      id: id,
      coordinates: coordinates,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null ? DateTime.parse(data['endTime'] as String) : null,
      totalDistanceMeters: (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
