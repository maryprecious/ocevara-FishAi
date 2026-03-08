import 'package:latlong2/latlong.dart';
import 'package:ocevara/core/models/restricted_zone.dart';
import 'package:ocevara/core/models/fishing_hotspot.dart';
import 'package:ocevara/core/models/catch_log.dart';

enum MapSafetyStatus { safe, warning, danger }

class MapState {
  final LatLng? userLocation;
  final List<RestrictedZone> zones;
  final List<FishingHotspot> hotspots;
  final List<CatchLog> catchLogs;
  final bool showHotspots;
  final bool showCatches;
  final MapSafetyStatus safetyStatus;
  final RestrictedZone? activeWarningZone;
  final double? distanceToDanger;
  final bool isSOSActive;
  final bool isLoading;

  MapState({
    this.userLocation,
    this.zones = const [],
    this.hotspots = const [],
    this.catchLogs = const [],
    this.showHotspots = true,
    this.showCatches = true,
    this.safetyStatus = MapSafetyStatus.safe,
    this.activeWarningZone,
    this.distanceToDanger,
    this.isSOSActive = false,
    this.isLoading = true,
  });

  MapState copyWith({
    LatLng? userLocation,
    List<RestrictedZone>? zones,
    List<FishingHotspot>? hotspots,
    List<CatchLog>? catchLogs,
    bool? showHotspots,
    bool? showCatches,
    MapSafetyStatus? safetyStatus,
    RestrictedZone? activeWarningZone,
    double? distanceToDanger,
    bool? isSOSActive,
    bool? isLoading,
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      zones: zones ?? this.zones,
      hotspots: hotspots ?? this.hotspots,
      catchLogs: catchLogs ?? this.catchLogs,
      showHotspots: showHotspots ?? this.showHotspots,
      showCatches: showCatches ?? this.showCatches,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      activeWarningZone: activeWarningZone ?? this.activeWarningZone,
      distanceToDanger: distanceToDanger ?? this.distanceToDanger,
      isSOSActive: isSOSActive ?? this.isSOSActive,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
