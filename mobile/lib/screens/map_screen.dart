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
  int _selectedDrawerTab = 0; // 0 = Dispatch Routing, 1 = Tactical SOPs, 2 = Spread Risks

  // Initial map center
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.67494, 73.01734), // G-10 Markaz, Islamabad
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
          lat: 33.67494,
          lng: 73.01734,
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
          position: LatLng(33.67494, 73.01734),
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
          lat: 33.67494,
          lng: 73.01734,
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
      lat: 33.67494,
      lng: 73.01734,
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
            // Drawer Header
            Row(
              children: [
                const Icon(Icons.dashboard_customize_rounded, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TACTICAL CONTROL CONSOLE: ${disaster.title.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Premium Glassmorphic Tab Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton(0, 'Dispatch & Routing', Icons.navigation_rounded),
                _buildTabButton(1, 'Tactical SOPs', Icons.fact_check_rounded),
                _buildTabButton(2, 'Spread Threat', Icons.radar_rounded),
              ],
            ),
            const SizedBox(height: 12),
            // Tab Content Rendering
            if (_selectedDrawerTab == 0) ...[
              _buildRoutingTab(ref, disaster, selectedId),
            ] else if (_selectedDrawerTab == 1) ...[
              _buildSOPsTab(disaster),
            ] else ...[
              _buildSpreadRisksTab(disaster),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedDrawerTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDrawerTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.greenAccent : Colors.white38),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingTab(WidgetRef ref, ConfirmedDisaster disaster, String selectedId) {
    final isFlooding = disaster.type.toLowerCase().contains('flood') || disaster.title.toLowerCase().contains('flood');
    final isHeatwave = disaster.type.toLowerCase().contains('heat') || disaster.title.toLowerCase().contains('heat');
    
    // Dynamic evacuation/relief directive messages based on route selection
    String alphaDirective = "Use this route to dispatch emergency medical responders (Fastest Roadway)";
    String betaDirective = "Use this route to evacuate people (Secondary Safe Detour)";
    
    if (isFlooding) {
      alphaDirective = "📦 ALPHA DIRECTIVE: Use this route to deliver relief packages to affected civilians (Fastest snaps).";
      betaDirective = "🏃 BETA DIRECTIVE: Use this route to evacuate stranded citizens (Secondary Safe Detour).";
    } else if (isHeatwave) {
      alphaDirective = "❄️ ALPHA DIRECTIVE: Use this route to dispatch cooling payloads and EMS medics (Fastest snaps).";
      betaDirective = "🏥 BETA DIRECTIVE: Use this route to transport hyperthermia victims to cooling centers.";
    } else {
      alphaDirective = "🛡️ ALPHA DIRECTIVE: Use this route to dispatch responders and deliver initial relief.";
      betaDirective = "🏃 BETA DIRECTIVE: Use this route to evacuate people and move critical casualties.";
    }

    final activeDirective = selectedId == 'alt_a' ? alphaDirective : betaDirective;
    final routeColor = selectedId == 'alt_a' ? const Color(0xFF39FF14) : const Color(0xFF00E5FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Source and Destination Routing Deck
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              // Pickup / Source Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'PICKUP / SOURCE',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disaster.emergencyDeptName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Emergency dispatch origin department hub',
                          style: TextStyle(color: Colors.white38, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.local_hospital_rounded, size: 14, color: Colors.cyan),
                ],
              ),
              // Connecting Visual Line
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.cyan.withOpacity(0.5),
                            Colors.redAccent.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Destination / Drop Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'DROP / DESTINATION',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${disaster.title} Zone',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          disaster.location,
                          style: const TextStyle(color: Colors.white38, fontSize: 8),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Route Buttons (Alpha and Beta)
        Row(
          children: disaster.alternativeRoutes.map((route) {
            final isSelected = selectedId == route.id;
            final buttonColor = route.id == 'alt_a' ? const Color(0xFF39FF14) : const Color(0xFF00E5FF);

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(selectedRouteIdProvider.notifier).state = route.id;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? buttonColor.withOpacity(0.15) : const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? buttonColor : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        route.id == 'alt_a' ? 'ALPHA ROUTE (PRIMARY)' : 'BETA ROUTE (SECONDARY)',
                        style: TextStyle(
                          color: isSelected ? buttonColor : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${route.duration} (${route.delayAverted.replaceAll(" delay averted", "")})',
                        style: const TextStyle(color: Colors.white30, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Evacuation/Evac directive box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: routeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: routeColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.assignment_turned_in, size: 14, color: routeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeDirective,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSOPsTab(ConfirmedDisaster disaster) {
    final isFlooding = disaster.type.toLowerCase().contains('flood') || disaster.title.toLowerCase().contains('flood');
    final isHeatwave = disaster.type.toLowerCase().contains('heat') || disaster.title.toLowerCase().contains('heat');
    
    List<String> sops = [];
    Color themeColor = Colors.orangeAccent;
    
    if (isFlooding) {
      themeColor = const Color(0xFF39FF14);
      sops = [
        "De-energize submerged electrical sub-stations in affected sectors.",
        "Deploy high-clearance inflatable rescue boats to G-10 Service roads.",
        "Establish dry medical triage center at PIMS Emergency entrance.",
        "Block all access roads within a 500m radius of G-10 Markaz."
      ];
    } else if (isHeatwave) {
      themeColor = const Color(0xFF00E5FF);
      sops = [
        "Establish cooling & hydration hubs in Clifton Block 5.",
        "Dispatch mobile EMS units with ice packs and cooling fluids.",
        "Broadcast bilingual heatwave advisories to regional SMS subscribers.",
        "Monitor backup generator fuel levels at South City Hospital."
      ];
    } else {
      themeColor = Colors.redAccent;
      sops = [
        "Establish secure perimeter and clear traffic channels for responders.",
        "Coordinate joint command between Civil Defense and Local EMS.",
        "Broaden sensory monitoring via CCTV and drone streams.",
        "Stream real-time situation reports directly to the NDMA hub."
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'TACTICAL COMMAND STANDING ORDERS (SOPs)',
            style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        ...sops.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final sop = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SOP-0$index',
                    style: TextStyle(color: themeColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sop,
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSpreadRisksTab(ConfirmedDisaster disaster) {
    final isIslamabad = disaster.location.toLowerCase().contains('islamabad') || disaster.emergencyDeptName.toLowerCase().contains('pims');
    final isFlooding = disaster.type.toLowerCase().contains('flood') || disaster.title.toLowerCase().contains('flood');
    final isHeatwave = disaster.type.toLowerCase().contains('heat') || disaster.title.toLowerCase().contains('heat');
    
    List<Map<String, String>> spreadRisks = [];
    Color themeColor = Colors.redAccent;
    
    if (isIslamabad) {
      if (isFlooding) {
        spreadRisks = [
          {"area": "Sector G-9 (East)", "risk": "High risk of flood run-off. Sector drains backing up.", "status": "🚨 HIGH ALERT"},
          {"area": "Sector G-11 (West)", "risk": "Water levels rising. Low-lying residential areas vulnerable.", "status": "⚠️ MONITOR"},
          {"area": "Sector F-10 (North)", "risk": "Traffic bottleneck from Srinagar Highway diversion.", "status": "⚠️ MONITOR"},
          {"area": "Sector H-10 (South)", "risk": "Srinagar Highway exit blocked. Heavy water pooling.", "status": "🚨 HIGH ALERT"},
        ];
      } else if (isHeatwave) {
        spreadRisks = [
          {"area": "Sector G-9 (East)", "risk": "High concrete density heat island. Power grid overloaded.", "status": "🚨 HIGH ALERT"},
          {"area": "Sector G-11 (West)", "risk": "Secondary clinic heatstroke admissions rising rapidly.", "status": "⚠️ MONITOR"},
          {"area": "Sector F-10 (North)", "risk": "Dense commercial sector. Hydration resources low.", "status": "⚠️ MONITOR"},
          {"area": "Sector H-10 (South)", "risk": "Unscheduled load-shedding warning. Vulnerable populations at risk.", "status": "🚨 HIGH ALERT"},
        ];
      } else {
        spreadRisks = [
          {"area": "Sector G-9 (East)", "risk": "Severe traffic gridlock & emergency spillover risk.", "status": "🚨 HIGH ALERT"},
          {"area": "Sector G-11 (West)", "risk": "Secondary run-off alert. Storm drains overflow.", "status": "⚠️ MONITOR"},
          {"area": "Sector F-10 (North)", "risk": "Commercial sector safety advisory. High crowd density.", "status": "⚠️ MONITOR"},
          {"area": "Sector H-10 (South)", "risk": "Highway blockages spreading. Potential backup.", "status": "🚨 HIGH ALERT"},
        ];
      }
    } else {
      if (isFlooding) {
        spreadRisks = [
          {"area": "Clifton Block 4", "risk": "Low-lying coastline sector. Sea breeze blocked, severe water stagnation.", "status": "🚨 HIGH ALERT"},
          {"area": "Clifton Block 9", "risk": "Severe urban drainage backlog. Main boulevard water logged.", "status": "⚠️ MONITOR"},
          {"area": "Khayaban-e-Saadi", "risk": "Roadway fully submerged. Inundation blocking emergency vehicles.", "status": "⚠️ MONITOR"},
          {"area": "Boat Basin", "risk": "Severe storm drain backflow. Food street area flooded.", "status": "🚨 HIGH ALERT"},
        ];
      } else if (isHeatwave) {
        spreadRisks = [
          {"area": "Clifton Block 4", "risk": "Severe high heat index zone. Residential high-rises trapping heat.", "status": "🚨 HIGH ALERT"},
          {"area": "Clifton Block 9", "risk": "Heat exhaustion clinic overflow. Extra fluid packages dispatched.", "status": "⚠️ MONITOR"},
          {"area": "Khayaban-e-Saadi", "risk": "Major asphalt corridor heat-sink. Avoid pedestrian movement.", "status": "⚠️ MONITOR"},
          {"area": "Boat Basin", "risk": "High tourist/crowd density. Cool water hubs established.", "status": "🚨 HIGH ALERT"},
        ];
      } else {
        spreadRisks = [
          {"area": "Clifton Block 4 (North)", "risk": "Severe urban heat corridor. Packed housing risk.", "status": "🚨 HIGH ALERT"},
          {"area": "Clifton Block 9 (East)", "risk": "Emergency clinic pressures. Regional clinics full.", "status": "⚠️ MONITOR"},
          {"area": "Khayaban-e-Saadi (South)", "risk": "Gridlocked rescue lanes. Key responder routes bottleneck.", "status": "⚠️ MONITOR"},
          {"area": "Boat Basin (West)", "risk": "High crowd density congestion. Extreme crowd safety threat.", "status": "🚨 HIGH ALERT"},
        ];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'REGIONAL THREAT SPREAD ANALYSIS (ADJACENT ZONES)',
            style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: spreadRisks.take(2).map((item) => _buildSpreadRiskCard(item)).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: spreadRisks.skip(2).take(2).map((item) => _buildSpreadRiskCard(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildSpreadRiskCard(Map<String, String> item) {
    final isHigh = item['status'] == '🚨 HIGH ALERT';
    final cardColor = isHigh ? Colors.redAccent : Colors.orangeAccent;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['area']!,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item['status']!.replaceAll("🚨 ", "").replaceAll("⚠️ ", ""),
                  style: TextStyle(color: cardColor, fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['risk']!,
              style: const TextStyle(color: Colors.white60, fontSize: 8),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
