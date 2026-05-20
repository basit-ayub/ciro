import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
  final String emergencyDeptName;
  final LatLng emergencyDeptLatLng;

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
    required this.emergencyDeptName,
    required this.emergencyDeptLatLng,
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
    String? emergencyDeptName,
    LatLng? emergencyDeptLatLng,
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
      emergencyDeptName: emergencyDeptName ?? this.emergencyDeptName,
      emergencyDeptLatLng: emergencyDeptLatLng ?? this.emergencyDeptLatLng,
    );
  }
}

class ConfirmedDisastersNotifier extends StateNotifier<List<ConfirmedDisaster>> {
  ConfirmedDisastersNotifier() : super([]) {
    // Attempt to listen to Firestore on creation (will fail gracefully if Firebase is unconfigured)
    listenToFirestore();
  }

  StreamSubscription? _firestoreSub;

  void addDisaster(ConfirmedDisaster disaster) {
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

  void listenToFirestore() {
    _firestoreSub?.cancel();
    try {
      // Check if Firebase is initialized.
      if (Firebase.apps.isNotEmpty) {
        _firestoreSub = FirebaseFirestore.instance
            .collection('situations')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final id = doc.id;
            final title = data['incident_type'] ?? 'Urban Flooding';
            final type = data['incident_type'] ?? 'Emergency';
            final geo = data['geo'] as Map<dynamic, dynamic>? ?? {};
            final lat = geo['lat']?.toDouble() ?? 33.6938;
            final lng = geo['lon']?.toDouble() ?? 72.9910;
            final confidence = ((data['confidence'] ?? 0.8) as num).toDouble() * 100.0;
            final severity = (data['severity'] ?? 4) as int;
            final status = data['status'] ?? 'assessed';
            final reasoning = data['reasoning_trace'] ?? 'Heavy urban emergency reported';

            final disaster = generateMockDisaster(
              id: id,
              title: title,
              type: type,
              location: reasoning,
              lat: lat,
              lng: lng,
              confidence: confidence,
              severity: severity,
              status: status,
            );
            addDisaster(disaster);
          }
        }, onError: (err) {
          // print silently - don't crash
        });
      }
    } catch (e) {
      // Unconfigured or no Firebase, run gracefully in offline/stadium mock mode
    }
  }

  void clearAll() {
    state = [];
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }
}

// Global Providers
final confirmedDisastersProvider = StateNotifierProvider<ConfirmedDisastersNotifier, List<ConfirmedDisaster>>((ref) {
  return ConfirmedDisastersNotifier();
});

final activeDisasterIdProvider = StateProvider<String?>((ref) => null);

final selectedRouteIdProvider = StateProvider<String>((ref) => 'alt_a');

// Seed/mock disaster helper with highly realistic road-following coordinates
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
  final isIslamabad = (lat - 33.69).abs() < 0.1;

  if (isIslamabad) {
    // Islamabad Grid (G-8/G-9/G-10) - PIMS Hospital to G-10 Markaz Emergency Routing
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
      emergencyDeptName: 'PIMS Hospital (G-8/3 Emergency)',
      emergencyDeptLatLng: const LatLng(33.6980, 73.0450),
      blockedRouteDescription: 'Srinagar Highway exit to G-10 Service Road East completely flooded',
      blockedPoints: const [
        LatLng(33.6820, 73.0000),
        LatLng(33.6860, 73.0010),
      ],
      alternativeRoutes: [
        AlternativeRoute(
          id: 'alt_a',
          name: 'Route Alpha (Ibn-e-Sina Bypass)',
          duration: '11 mins',
          delayAverted: '15 mins delay averted',
          points: const [
            LatLng(33.6980, 73.0450), // PIMS Emergency
            LatLng(33.7010, 73.0450), // Ibn-e-Sina Road East
            LatLng(33.7000, 73.0300), // Ibn-e-Sina Road Mid
            LatLng(33.6990, 73.0100), // Ibn-e-Sina Road West
            LatLng(33.6980, 72.9980), // Ibn-e-Sina Road Sector Entrance
            LatLng(33.6975, 72.9920), // G-10 Service Road North
            LatLng(33.6938, 72.9910), // G-10 Markaz (Crisis Hub)
          ],
        ),
        AlternativeRoute(
          id: 'alt_b',
          name: 'Route Beta (Kashmir Hwy Detour)',
          duration: '16 mins',
          delayAverted: '10 mins delay averted',
          points: const [
            LatLng(33.6980, 73.0450), // PIMS Emergency
            LatLng(33.6890, 73.0420), // Srinagar Highway G-8
            LatLng(33.6850, 73.0200), // Srinagar Highway G-9
            LatLng(33.6820, 73.0000), // Srinagar Highway G-10 exit (Bypass Start)
            LatLng(33.6850, 73.0050), // Detour via G-9 Service Rd West
            LatLng(33.6900, 73.0060), // G-9 Service Rd North
            LatLng(33.6920, 73.0020), // G-10 Sumbal Road East gate
            LatLng(33.6935, 72.9950), // Sumbal Road Mid
            LatLng(33.6938, 72.9910), // G-10 Markaz (Crisis Hub)
          ],
        ),
      ],
    );
  } else {
    // Karachi Grid (Clifton) - South City Hospital to Clifton Block 5 Emergency Routing
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
      emergencyDeptName: 'South City Hospital (Clifton)',
      emergencyDeptLatLng: const LatLng(24.8190, 67.0380),
      blockedRouteDescription: 'Khayaban-e-Jami near Clifton Bridge is blocked',
      blockedPoints: const [
        LatLng(24.8220, 67.0340),
        LatLng(24.8250, 67.0330),
      ],
      alternativeRoutes: [
        AlternativeRoute(
          id: 'alt_a',
          name: 'Route Alpha (Marine Promenade)',
          duration: '9 mins',
          delayAverted: '12 mins delay averted',
          points: const [
            LatLng(24.8190, 67.0380), // South City Hospital
            LatLng(24.8170, 67.0330), // Marine Promenade East
            LatLng(24.8200, 67.0280), // Marine Promenade West
            LatLng(24.8238, 67.0310), // Clifton Block 5 (Crisis Hub)
          ],
        ),
        AlternativeRoute(
          id: 'alt_b',
          name: 'Route Beta (Khayaban-e-Saadi Bypass)',
          duration: '14 mins',
          delayAverted: '7 mins delay averted',
          points: const [
            LatLng(24.8190, 67.0380), // South City Hospital
            LatLng(24.8260, 67.0420), // Khayaban-e-Saadi East
            LatLng(24.8310, 67.0360), // Sunset Boulevard
            LatLng(24.8280, 67.0290), // Clifton Block 4
            LatLng(24.8238, 67.0310), // Clifton Block 5 (Crisis Hub)
          ],
        ),
      ],
    );
  }
}

