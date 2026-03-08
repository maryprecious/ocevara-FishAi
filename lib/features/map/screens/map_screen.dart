import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocevara/core/models/restricted_zone.dart';
import 'package:ocevara/core/models/fishing_hotspot.dart';
import 'package:ocevara/core/theme/app_colors.dart';
import 'package:ocevara/features/map/viewmodels/map_state.dart';
import 'package:ocevara/features/map/viewmodels/map_view_model.dart';
import 'package:ocevara/features/map/widgets/pulse_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? zoneName;

  const MapScreen({super.key, this.initialLat, this.initialLng, this.zoneName});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    final userLoc = ref.read(mapViewModelProvider).userLocation;
    if (userLoc != null) {
      _mapController.move(userLoc, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final viewModel = ref.read(mapViewModelProvider.notifier);

    // Auto-center on initial position if provided
    if (widget.initialLat != null && widget.initialLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(widget.initialLat!, widget.initialLng!), 15);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.userLocation ?? const LatLng(6.5244, 3.3792),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ocevara.app',
              ),
              
              // Zone circles
              CircleLayer(
                circles: mapState.zones.map((zone) {
                  return CircleMarker(
                    point: LatLng(zone.centerLat, zone.centerLng),
                    radius: zone.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: _getZoneColor(zone.severity).withOpacity(0.3),
                    borderColor: _getZoneColor(zone.severity),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

              // Catch Markers (Toggleable)
              if (mapState.showCatches)
                MarkerLayer(
                  markers: mapState.catchLogs.map((log) {
                    return Marker(
                      point: LatLng(log.lat, log.lng),
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.location_on, color: Color(0xFF1CB5AC), size: 24),
                    );
                  }).toList(),
                ),

              // Hotspots (Toggleable)
              if (mapState.showHotspots)
                MarkerLayer(
                  markers: mapState.hotspots.map((spot) {
                    return Marker(
                      point: LatLng(spot.latitude, spot.longitude),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showHotspotSheet(context, spot),
                        child: PulseMarker(
                          color: const Color(0xFF1CB5AC),
                          child: const Icon(Icons.waves, color: Color(0xFF1CB5AC), size: 30),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // User location marker
              if (mapState.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapState.userLocation!,
                      width: 80,
                      height: 80,
                      child: PulseMarker(
                         color: mapState.safetyStatus == MapSafetyStatus.danger 
                            ? Colors.red 
                            : mapState.safetyStatus == MapSafetyStatus.warning 
                                ? Colors.yellow 
                                : Colors.blue,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. Warning UI (Blinking border / Red overlay)
          if (mapState.safetyStatus == MapSafetyStatus.warning)
            _WarningBorder(color: Colors.yellow.withOpacity(0.4)),
          if (mapState.safetyStatus == MapSafetyStatus.danger)
            Container(color: Colors.red.withOpacity(0.2)),

          // 3. Top Controls (Back, Legend, Toggle)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circularButton(Icons.arrow_back, () => Navigator.pop(context)),
                Row(
                  children: [
                    _circularButton(
                      mapState.showHotspots ? Icons.layers : Icons.layers_outlined,
                      () => viewModel.toggleHotspots(),
                    ),
                    const SizedBox(width: 12),
                    _circularButton(Icons.info_outline, () => _showLegend(context)),
                  ],
                ),
              ],
            ),
          ),

          // 4. Bottom Warning Banner
          if (mapState.safetyStatus == MapSafetyStatus.warning)
            Positioned(
              bottom: 180,
              left: 20,
              right: 20,
              child: _WarningBanner(
                title: '⚠ Danger zone ahead',
                subtitle: '${(mapState.distanceToDanger! / 1000).toStringAsFixed(1)}km away',
                color: Colors.yellow.shade800,
              ),
            ),

          // 5. Danger Modal (Full Screen Overlay style)
          if (mapState.safetyStatus == MapSafetyStatus.danger)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'HIGH RISK ZONE',
                      style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are inside a restricted fishing area. Please leave immediately for your safety.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                        onPressed: () => _recenter(),
                        child: const Text('VIEW SAFE ROUTE', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Right Side Controls
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                _circularButton(Icons.my_location, _recenter),
                if (mapState.userLocation == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Locating...', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                const SizedBox(height: 16),
                _sosButton(() async {
                  final success = await viewModel.sendSOS();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location shared successfully')),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getZoneColor(String severity) {
    switch (severity) {
      case 'SAFE': return Colors.green;
      case 'ADVISORY': return Colors.orange;
      case 'DANGER': return Colors.red;
      case 'CLOSED': return Colors.grey.shade800;
      default: return Colors.blue;
    }
  }

  Widget _circularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Icon(icon, color: AppColors.primaryTeal),
      ),
    );
  }

  Widget _sosButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 65,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 15)]),
        child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Map Legend', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.green, 'SAFE', 'Good for fishing'),
            _legendItem(Colors.orange, 'CAREFUL', 'Advisory zone'),
            _legendItem(Colors.red, 'DANGER', 'Restricted area'),
            _legendItem(Colors.grey.shade800, 'CLOSED', 'No fishing allowed'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT'))],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  void _showHotspotSheet(BuildContext context, FishingHotspot spot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spot.name, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow(Icons.set_meal, 'Top Species', spot.topSpecies),
            _infoRow(Icons.trending_up, 'Activity Level', '${spot.activityLevel}/5'),
            _infoRow(Icons.anchor, 'Best Lure', spot.bestLure),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1CB5AC), padding: const EdgeInsets.all(16)),
                onPressed: () => Navigator.pop(context),
                child: const Text('SET AS DESTINATION', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _WarningBorder extends StatefulWidget {
  final Color color;
  const _WarningBorder({required this.color});

  @override
  State<_WarningBorder> createState() => _WarningBorderState();
}

class _WarningBorderState extends State<_WarningBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.color.withOpacity(_controller.value), width: 10),
          ),
        );
      },
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  const _WarningBanner({required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
