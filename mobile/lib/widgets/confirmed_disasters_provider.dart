import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlternativeRoute {
  final String id;
  final String name;
  final String duration;
  final List<LatLng> points;
  final String delayAverted;

  AlternativeRoute({
    required this.id,
    required this.name,
    required this.duration,
    required this.points,
    required this.delayAverted,
  });
}

class ConfirmedDisaster {
  final String id;
  final String title;
  final String type;
  final String location;
  final LatLng latLng;
  final double confidenceScore;
  final int severity;
  final String status;
  final DateTime timestamp;
  final List<LatLng> blockedPoints;
  final String blockedRouteDescription;
  final List<AlternativeRoute> alternativeRoutes;

  ConfirmedDisaster({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.latLng,
    required this.confidenceScore,
    required this.severity,
    required this.status,
    required this.timestamp,
    required this.blockedPoints,
    required this.blockedRouteDescription,
    required this.alternativeRoutes,
  });

  ConfirmedDisaster copyWith({
    String? id,
    String? title,
    String? type,
    String? location,
    LatLng? latLng,
    double? confidenceScore,
    int? severity,
    String? status,
    DateTime? timestamp,
    List<LatLng>? blockedPoints,
    String? blockedRouteDescription,
    List<AlternativeRoute>? alternativeRoutes,
  }) {
    return ConfirmedDisaster(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      latLng: latLng ?? this.latLng,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      blockedPoints: blockedPoints ?? this.blockedPoints,
      blockedRouteDescription: blockedRouteDescription ?? this.blockedRouteDescription,
      alternativeRoutes: alternativeRoutes ?? this.alternativeRoutes,
    );
  }
}

class ConfirmedDisastersNotifier extends StateNotifier<List<ConfirmedDisaster>> {
  ConfirmedDisastersNotifier() : super([]);

  void addDisaster(ConfirmedDisaster disaster) {
    // Avoid duplicates
    if (state.any((d) => d.id == disaster.id)) {
      state = state.map((d) => d.id == disaster.id ? disaster : d).toList();
    } else {
      state = [disaster, ...state];
    }
  }

  void updateStatus(String id, String status) {
    state = state.map((d) {
      if (d.id == id) {
        return d.copyWith(status: status);
      }
      return d;
    }).toList();
  }

  void clearAll() {
    state = [];
  }
}

// Global Providers
final confirmedDisastersProvider = StateNotifierProvider<ConfirmedDisastersNotifier, List<ConfirmedDisaster>>((ref) {
  return ConfirmedDisastersNotifier();
});

final activeDisasterIdProvider = StateProvider<String?>((ref) => null);

final selectedRouteIdProvider = StateProvider<String>((ref) => 'alt_a');

// Seed/mock disaster helper
ConfirmedDisaster generateMockDisaster({
  required String id,
  required String title,
  required String type,
  required String location,
  required double lat,
  required double lng,
  required double confidence,
  required int severity,
  required String status,
}) {
  // Generate some realistic blocked segments and detour paths around the coordinate
  return ConfirmedDisaster(
    id: id,
    title: title,
    type: type,
    location: location,
    latLng: LatLng(lat, lng),
    confidenceScore: confidence,
    severity: severity,
    status: status,
    timestamp: DateTime.now(),
    blockedRouteDescription: 'Main intersection blocked due to critical incident',
    blockedPoints: [
      LatLng(lat + 0.001, lng - 0.001),
      LatLng(lat - 0.001, lng + 0.001),
    ],
    alternativeRoutes: [
      AlternativeRoute(
        id: 'alt_a',
        name: 'Route Alpha (Primary Bypass)',
        duration: '12 mins',
        delayAverted: '14 mins delay averted',
        points: [
          LatLng(lat + 0.002, lng - 0.002),
          LatLng(lat + 0.003, lng + 0.001),
          LatLng(lat - 0.002, lng + 0.003),
        ],
      ),
      AlternativeRoute(
        id: 'alt_b',
        name: 'Route Beta (Secondary Detour)',
        duration: '18 mins',
        delayAverted: '8 mins delay averted',
        points: [
          LatLng(lat - 0.003, lng - 0.002),
          LatLng(lat - 0.004, lng + 0.002),
          LatLng(lat - 0.001, lng + 0.003),
        ],
      ),
    ],
  );
}
