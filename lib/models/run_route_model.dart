import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
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

    // Handle both Timestamp and ISO string for backward compatibility
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return RunRoute(
      id: id,
      coordinates: coordinates,
      startTime: parseDateTime(data['startTime']),
      endTime: data['endTime'] != null ? parseDateTime(data['endTime']) : null,
      totalDistanceMeters:
          (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
