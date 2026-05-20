import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ciro_mobile/widgets/confirmed_disasters_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  String? _previousActiveId;

  // Initial map center
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6938, 72.9910), // G-10 Markaz, Islamabad
    zoom: 14.2,
  );

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeDisasterIdProvider);
    final disasters = ref.watch(confirmedDisastersProvider);
    final selectedRouteId = ref.watch(selectedRouteIdProvider);

    // Dynamic map overlay assembly based on active disaster
    _markers.clear();
    _polylines.clear();
    _polygons.clear();

    if (activeId == null) {
      _previousActiveId = null;
    }

    ConfirmedDisaster? activeDisaster;
    if (activeId != null) {
      activeDisaster = disasters.firstWhere(
        (d) => d.id == activeId,
        orElse: () => generateMockDisaster(
          id: 'g10_flood',
          title: 'G-10 Flash Flood',
          type: 'Urban Flooding',
          location: 'G-10 Markaz, Islamabad',
          lat: 33.6938,
          lng: 72.9910,
          confidence: 94.2,
          severity: 4,
          status: 'Sentinel Triaged',
        ),
      );
    }

    if (activeDisaster != null) {
      // 1. Fit bounds to contain both Emergency Department and Disaster Zone
      if (activeId != _previousActiveId) {
        _previousActiveId = activeId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds(activeDisaster!.emergencyDeptLatLng, activeDisaster.latLng);
        });
      }

      // 2. Plot Blocked Segment (Thick Red Polyline)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('blocked_route'),
          points: activeDisaster.blockedPoints,
          color: Colors.redAccent,
          width: 7,
          patterns: [PatternItem.dash(12), PatternItem.gap(8)],
        ),
      );

      // 3. Emergency Dept Marker
      _markers.add(
        Marker(
          markerId: const MarkerId('emergency_dept'),
          position: activeDisaster.emergencyDeptLatLng,
          infoWindow: InfoWindow(
            title: '🏥 EMERGENCY DEPT: ${activeDisaster.emergencyDeptName}',
            snippet: 'Origin point for first responder dispatch.',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      // 4. Blocked warning icon marker
      _markers.add(
        Marker(
          markerId: const MarkerId('blocked_warning'),
          position: activeDisaster.latLng,
          infoWindow: InfoWindow(
            title: '⚠️ EMERGENCY BLOCKED ROUTE',
            snippet: activeDisaster.blockedRouteDescription,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // 5. Plot Alternative routes
      for (final route in activeDisaster.alternativeRoutes) {
        final isSelected = selectedRouteId == route.id;
        final routeColor = route.id == 'alt_a'
            ? const Color(0xFF39FF14) // Lime Green
            : const Color(0xFF00E5FF); // Cyber Cyan

        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_${route.id}'),
            points: route.points,
            color: isSelected ? routeColor : routeColor.withOpacity(0.35),
            width: isSelected ? 6 : 4,
            patterns: isSelected ? [] : [PatternItem.dash(8), PatternItem.gap(8)],
          ),
        );

        // Put a descriptive marker near the route midpoint
        if (route.points.isNotEmpty) {
          final midpoint = route.points[route.points.length ~/ 2];
          _markers.add(
            Marker(
              markerId: MarkerId('marker_route_${route.id}'),
              position: midpoint,
              infoWindow: InfoWindow(
                title: route.name,
                snippet: 'Est. duration: ${route.duration} (${route.delayAverted})',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                route.id == 'alt_a' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueCyan,
              ),
            ),
          );
        }
      }
    } else {
      // Seed default marker when no disaster is active
      _markers.add(
        const Marker(
          markerId: MarkerId('default_center'),
          position: LatLng(33.6938, 72.9910),
          infoWindow: InfoWindow(
            title: 'CIRO MONITORING STATION',
            snippet: 'Islamabad HQ Hub - All quiet.',
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            polygons: _polygons,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusPill(activeDisaster != null),
                      if (activeDisaster != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                          onPressed: () {
                            ref.read(activeDisasterIdProvider.notifier).state = null;
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (activeDisaster != null) _buildRoutingSelectorDrawer(ref, activeDisaster, selectedRouteId),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: activeDisaster != null ? 180.0 : 0.0),
        child: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          onPressed: _triggerMockHellModeAlert,
          child: const Icon(Icons.local_fire_department, color: Colors.white),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final activeId = ref.read(activeDisasterIdProvider);
    final disasters = ref.read(confirmedDisastersProvider);
    if (activeId != null) {
      final activeDisaster = disasters.firstWhere(
        (d) => d.id == activeId,
        orElse: () => generateMockDisaster(
          id: 'g10_flood',
          title: 'G-10 Flash Flood',
          type: 'Urban Flooding',
          location: 'G-10 Markaz, Islamabad',
          lat: 33.6938,
          lng: 72.9910,
          confidence: 94.2,
          severity: 4,
          status: 'Sentinel Triaged',
        ),
      );
      _fitBounds(activeDisaster.emergencyDeptLatLng, activeDisaster.latLng);
    }
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final double southLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    final double northLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    final double westLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    final double eastLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(southLat, westLng),
      northeast: LatLng(northLat, eastLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80.0), // Padding of 80.0
    );
  }

  void _triggerMockHellModeAlert() {
    // Generate a fresh disaster and set it as active
    final manualCrisis = generateMockDisaster(
      id: 'g10_flood',
      title: 'Manual Flood Report',
      type: 'Urban Flooding',
      location: 'Sector G-10, Islamabad',
      lat: 33.6938,
      lng: 72.9910,
      confidence: 99.1,
      severity: 5,
      status: 'Commander Verified',
    );
    ref.read(confirmedDisastersProvider.notifier).addDisaster(manualCrisis);
    ref.read(activeDisasterIdProvider.notifier).state = 'g10_flood';
  }

  Widget _buildStatusPill(bool hasActiveAlert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasActiveAlert ? Colors.redAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hasActiveAlert ? Colors.redAccent : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasActiveAlert ? 'ACTIVE INCIDENT IN PROGRESS' : 'CIRO MONITORING NORMAL',
            style: TextStyle(
              color: hasActiveAlert ? Colors.redAccent : Colors.greenAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutingSelectorDrawer(WidgetRef ref, ConfirmedDisaster disaster, String selectedId) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151515).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ROUTING CONTROLLER: ${disaster.title.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: disaster.alternativeRoutes.map((route) {
                final isSelected = selectedId == route.id;
                final routeColor = route.id == 'alt_a' ? const Color(0xFF39FF14) : const Color(0xFF00E5FF);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(selectedRouteIdProvider.notifier).state = route.id;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? routeColor.withOpacity(0.2) : const Color(0xFF222222),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? routeColor : Colors.white.withOpacity(0.05),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            route.id == 'alt_a' ? 'ALPHA ROUTE' : 'BETA ROUTE',
                            style: TextStyle(
                              color: isSelected ? routeColor : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${route.duration} (${route.delayAverted.replaceAll(" delay averted", "")})',
                            style: const TextStyle(color: Colors.white38, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info, size: 14, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alternative detours bypass active flood boundaries and are synchronized with localized city graphs.',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
