import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/live_reasoning_stadium.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;

  // Center of Pakistan (roughly Islamabad for demo)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6938, 72.9910), // G-10 Markaz
    zoom: 13.0,
  );

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};

  void _triggerHellMode() {
    setState(() {
      // 5 colored zones for Hell Mode
      _polygons.addAll([
        Polygon(
          polygonId: const PolygonId('g10_flood'),
          points: const [LatLng(33.695, 72.990), LatLng(33.695, 72.993), LatLng(33.691, 72.993), LatLng(33.691, 72.990)],
          fillColor: Colors.blue.withOpacity(0.4),
          strokeColor: Colors.blueAccent,
          strokeWidth: 2,
        ),
        Polygon(
          polygonId: const PolygonId('khi_heatwave'),
          points: const [LatLng(24.862, 67.000), LatLng(24.862, 67.003), LatLng(24.859, 67.003), LatLng(24.859, 67.000)],
          fillColor: Colors.orange.withOpacity(0.4),
          strokeColor: Colors.orangeAccent,
          strokeWidth: 2,
        ),
        Polygon(
          polygonId: const PolygonId('m11_accident'),
          points: const [LatLng(31.635, 74.261), LatLng(31.635, 74.264), LatLng(31.633, 74.264), LatLng(31.633, 74.261)],
          fillColor: Colors.red.withOpacity(0.4),
          strokeColor: Colors.redAccent,
          strokeWidth: 2,
        ),
        Polygon(
          polygonId: const PolygonId('pindi_fire'),
          points: const [LatLng(33.598, 73.047), LatLng(33.598, 73.049), LatLng(33.596, 73.049), LatLng(33.596, 73.047)],
          fillColor: Colors.deepOrange.withOpacity(0.4),
          strokeColor: Colors.deepOrangeAccent,
          strokeWidth: 2,
        ),
        Polygon(
          polygonId: const PolygonId('kkh_landslide'),
          points: const [LatLng(36.318, 74.649), LatLng(36.318, 74.652), LatLng(36.315, 74.652), LatLng(36.315, 74.649)],
          fillColor: Colors.brown.withOpacity(0.4),
          strokeColor: Colors.brown,
          strokeWidth: 2,
        ),
      ]);

      // Example rerouting polyline for G-10 flood detour
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('g10_detour'),
          points: const [
            LatLng(33.696, 72.989),
            LatLng(33.696, 72.994),
            LatLng(33.690, 72.994),
          ],
          color: Colors.greenAccent,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)], // Simulated animated/dash look
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // We would apply a dark map style here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),
          
          // 2. Safe Area overlay for UI elements
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusPill(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: _triggerHellMode,
        child: const Icon(Icons.local_fire_department, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CIRO ACTIVE',
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
