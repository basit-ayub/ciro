import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';

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
    // Seed initial high-contrast mock disaster so the map immediately shows active, road-aligned intelligence
    final defaultG10 = generateMockDisaster(
      id: 'g10_flood',
      title: 'G-10 Flash Flood',
      type: 'Urban Flooding',
      location: 'G-10 Markaz, Islamabad',
      lat: 33.67494,
      lng: 73.01734,
      confidence: 94.2,
      severity: 4,
      status: 'Sentinel Triaged',
    );
    state = [defaultG10];
    fetchRealRoadRoutes(defaultG10.id);

    // Attempt to listen to Firestore on creation (will fail gracefully if Firebase is unconfigured)
    listenToFirestore();
  }

  StreamSubscription? _firestoreSub;
  final Dio _dio = Dio();

  void addDisaster(ConfirmedDisaster disaster) {
    final exists = state.any((d) => d.id == disaster.id);
    if (exists) {
      // Check if the existing one already has road-following points
      final existing = state.firstWhere((d) => d.id == disaster.id);
      final hasRoadPoints = existing.alternativeRoutes.isNotEmpty &&
          existing.alternativeRoutes.first.points.length > 15;
      
      if (hasRoadPoints && disaster.alternativeRoutes.isNotEmpty && disaster.alternativeRoutes.first.points.length <= 10) {
        // Keep the existing high-fidelity road points and only update other fields!
        state = state.map((d) {
          if (d.id == disaster.id) {
            return disaster.copyWith(
              alternativeRoutes: existing.alternativeRoutes,
              blockedPoints: existing.blockedPoints,
              status: disaster.status,
              confidenceScore: disaster.confidenceScore,
              severity: disaster.severity,
              location: disaster.location,
            );
          }
          return d;
        }).toList();
      } else {
        state = state.map((d) => d.id == disaster.id ? disaster : d).toList();
      }
    } else {
      state = [disaster, ...state];
      fetchRealRoadRoutes(disaster.id);
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

  Future<void> fetchRealRoadRoutes(String disasterId) async {
    final disasterIndex = state.indexWhere((d) => d.id == disasterId);
    if (disasterIndex == -1) return;
    
    final disaster = state[disasterIndex];
    List<AlternativeRoute> updatedRoutes = [];
    
    for (var route in disaster.alternativeRoutes) {
      try {
        final start = disaster.emergencyDeptLatLng;
        final end = disaster.latLng;
        
        // Guide OSRM using a middle waypoint to force Route Alpha and Route Beta detours
        LatLng midWaypoint;
        if (route.points.length > 2) {
          midWaypoint = route.points[route.points.length ~/ 2];
        } else {
          midWaypoint = LatLng(
            (start.latitude + end.latitude) / 2,
            (start.longitude + end.longitude) / 2,
          );
        }
        
        final coords = '${start.longitude},${start.latitude};${midWaypoint.longitude},${midWaypoint.latitude};${end.longitude},${end.latitude}';
        final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
        
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data['code'] == 'Ok') {
          final routesData = response.data['routes'] as List;
          if (routesData.isNotEmpty) {
            final geom = routesData[0]['geometry'];
            final coordsList = geom['coordinates'] as List;
            final List<LatLng> roadPoints = coordsList.map((c) {
              return LatLng(c[1].toDouble(), c[0].toDouble());
            }).toList();
            
            updatedRoutes.add(AlternativeRoute(
              id: route.id,
              name: route.name,
              duration: route.duration,
              delayAverted: route.delayAverted,
              points: roadPoints,
            ));
            continue;
          }
        }
      } catch (e) {
        // Fall back gracefully to mock points
      }
      
      // Fallback
      updatedRoutes.add(route);
    }
    
    // Fetch road points for the blocked route too if possible!
    List<LatLng> updatedBlockedPoints = disaster.blockedPoints;
    try {
      if (disaster.blockedPoints.length >= 2) {
        final start = disaster.blockedPoints.first;
        final end = disaster.blockedPoints.last;
        final coords = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
        final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data['code'] == 'Ok') {
          final routesData = response.data['routes'] as List;
          if (routesData.isNotEmpty) {
            final geom = routesData[0]['geometry'];
            final coordsList = geom['coordinates'] as List;
            updatedBlockedPoints = coordsList.map((c) {
              return LatLng(c[1].toDouble(), c[0].toDouble());
            }).toList();
          }
        }
      }
    } catch (e) {
      // ignore
    }
    
    if (mounted) {
      state = state.map((d) {
        if (d.id == disasterId) {
          return d.copyWith(
            alternativeRoutes: updatedRoutes,
            blockedPoints: updatedBlockedPoints,
          );
        }
        return d;
      }).toList();
    }
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
            final lat = geo['lat']?.toDouble() ?? 33.67494;
            final lng = geo['lon']?.toDouble() ?? 73.01734;
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
class EmergencyDepartment {
  final String name;
  final LatLng latLng;
  final String city;

  const EmergencyDepartment({
    required this.name,
    required this.latLng,
    required this.city,
  });
}

const List<EmergencyDepartment> emergencyDepartments = [
  // Islamabad
  EmergencyDepartment(name: 'PIMS Hospital (Ibn-e-Sina Rd)', latLng: LatLng(33.7047, 73.0564), city: 'Islamabad'),
  EmergencyDepartment(name: 'Shifa International Hospital', latLng: LatLng(33.6811, 73.0906), city: 'Islamabad'),
  EmergencyDepartment(name: 'CDA Fire Headquarters (G-7)', latLng: LatLng(33.7077, 73.0785), city: 'Islamabad'),
  // Rawalpindi
  EmergencyDepartment(name: 'Holy Family Hospital', latLng: LatLng(33.6300, 73.0700), city: 'Rawalpindi'),
  EmergencyDepartment(name: 'Benazir Bhutto Hospital', latLng: LatLng(33.6150, 73.0780), city: 'Rawalpindi'),
  // Karachi
  EmergencyDepartment(name: 'South City Hospital (Clifton)', latLng: LatLng(24.8190, 67.0380), city: 'Karachi'),
  EmergencyDepartment(name: 'Jinnah Postgraduate Medical Centre (JPMC)', latLng: LatLng(24.8519, 67.0425), city: 'Karachi'),
  EmergencyDepartment(name: 'Aga Khan University Hospital', latLng: LatLng(24.8922, 67.0747), city: 'Karachi'),
  EmergencyDepartment(name: 'Civil Hospital Karachi', latLng: LatLng(24.8596, 67.0101), city: 'Karachi'),
  // Lahore
  EmergencyDepartment(name: 'Mayo Hospital Lahore', latLng: LatLng(31.5725, 74.3125), city: 'Lahore'),
  EmergencyDepartment(name: 'Jinnah Hospital Lahore', latLng: LatLng(31.4820, 74.3030), city: 'Lahore'),
  EmergencyDepartment(name: 'Services Hospital Lahore', latLng: LatLng(31.5430, 74.3370), city: 'Lahore'),
  // Peshawar
  EmergencyDepartment(name: 'Lady Reading Hospital', latLng: LatLng(34.0150, 71.5750), city: 'Peshawar'),
  EmergencyDepartment(name: 'Khyber Teaching Hospital', latLng: LatLng(33.9980, 71.4870), city: 'Peshawar'),
  // Quetta
  EmergencyDepartment(name: 'Sandeman Provincial Hospital', latLng: LatLng(30.1980, 66.9980), city: 'Quetta'),
  // Multan
  EmergencyDepartment(name: 'Nishtar Hospital Multan', latLng: LatLng(30.1990, 71.4420), city: 'Multan'),
  // Faisalabad
  EmergencyDepartment(name: 'Allied Hospital Faisalabad', latLng: LatLng(31.4280, 73.0680), city: 'Faisalabad'),
  // Gujranwala
  EmergencyDepartment(name: 'DHQ Hospital Gujranwala', latLng: LatLng(32.1610, 74.1850), city: 'Gujranwala'),
];

EmergencyDepartment findNearestEmergencyDepartment(LatLng disasterLatLng) {
  double minDistance = double.infinity;
  EmergencyDepartment nearest = emergencyDepartments.first;

  for (var dept in emergencyDepartments) {
    final double latDiff = dept.latLng.latitude - disasterLatLng.latitude;
    final double lngDiff = dept.latLng.longitude - disasterLatLng.longitude;
    final double distSq = latDiff * latDiff + lngDiff * lngDiff;
    if (distSq < minDistance) {
      minDistance = distSq;
      nearest = dept;
    }
  }
  return nearest;
}

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
  final LatLng disasterLatLng = LatLng(lat, lng);
  final nearestDept = findNearestEmergencyDepartment(disasterLatLng);
  final start = nearestDept.latLng;
  final end = disasterLatLng;

  // Compute dynamic detour waypoints for Alpha & Beta routes
  final midLat = (start.latitude + end.latitude) / 2;
  final midLng = (start.longitude + end.longitude) / 2;
  
  final latDiff = end.latitude - start.latitude;
  final lngDiff = end.longitude - start.longitude;

  // Perpendicular offsets for detour guidance
  final alphaMid = LatLng(
    midLat - lngDiff * 0.25,
    midLng + latDiff * 0.25,
  );
  final betaMid = LatLng(
    midLat + lngDiff * 0.25,
    midLng - latDiff * 0.25,
  );

  // Dynamic blocked route segment near the disaster zone
  final blockedStart = LatLng(
    end.latitude - latDiff * 0.15,
    end.longitude - lngDiff * 0.15,
  );
  final blockedEnd = LatLng(
    end.latitude - latDiff * 0.05,
    end.longitude - lngDiff * 0.05,
  );

  // Evacuation action time estimates based on distance
  final distanceSq = latDiff * latDiff + lngDiff * lngDiff;
  final double distanceEstKm = 111.0 * distanceSq * 100; // raw visual scaler
  final durationMinutes = (10 + (distanceEstKm * 1.5)).clamp(5.0, 45.0).toInt();
  final delayAvertedMinutes = (durationMinutes * 1.5).clamp(5.0, 60.0).toInt();

  return ConfirmedDisaster(
    id: id,
    title: title,
    type: type,
    location: location.isNotEmpty ? location : '${nearestDept.city} Crisis Hub',
    latLng: disasterLatLng,
    confidenceScore: confidence,
    severity: severity,
    status: status,
    timestamp: DateTime.now(),
    emergencyDeptName: nearestDept.name,
    emergencyDeptLatLng: nearestDept.latLng,
    blockedRouteDescription: 'Main access exit near the crisis hub is blocked due to active $type.',
    blockedPoints: [blockedStart, blockedEnd],
    alternativeRoutes: [
      AlternativeRoute(
        id: 'alt_a',
        name: 'Route Alpha (Primary Evacuation Corridor)',
        duration: '$durationMinutes mins',
        delayAverted: '$delayAvertedMinutes mins delay averted',
        points: [start, alphaMid, end],
      ),
      AlternativeRoute(
        id: 'alt_b',
        name: 'Route Beta (Secondary Tactical Detour)',
        duration: '${(durationMinutes * 1.3).toInt()} mins',
        delayAverted: '${(delayAvertedMinutes * 0.7).toInt()} mins delay averted',
        points: [start, betaMid, end],
      ),
    ],
  );
}

