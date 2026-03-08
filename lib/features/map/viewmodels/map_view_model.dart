import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocevara/core/models/restricted_zone.dart';
import 'package:ocevara/features/map/repositories/map_repository.dart';
import 'package:ocevara/features/map/viewmodels/map_state.dart';
import 'package:vibration/vibration.dart';

final mapViewModelProvider = StateNotifierProvider<MapViewModel, MapState>((ref) {
  return MapViewModel(ref.read(mapRepositoryProvider));
});

class MapViewModel extends StateNotifier<MapState> {
  final MapRepository _repository;
  StreamSubscription<Position>? _positionSubscription;

  MapViewModel(this._repository) : super(MapState()) {
    _init();
  }

  Future<void> _init() async {
    final status = await _checkPermissions();
    if (status) {
      await _loadInitialData();
      _startLocationUpdates();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);
    final zones = await _repository.getZones();
    final hotspots = await _repository.getHotspots();
    final catches = await _repository.getCatchLogs();
    state = state.copyWith(
      zones: zones,
      hotspots: hotspots,
      catchLogs: catches,
      isLoading: false,
    );
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final userLoc = LatLng(position.latitude, position.longitude);
      _updateLocation(userLoc);
    });
  }

  void _updateLocation(LatLng location) {
    state = state.copyWith(userLocation: location);
    _checkDangerZones(location);
  }

  void _checkDangerZones(LatLng userLoc) {
    MapSafetyStatus worstStatus = MapSafetyStatus.safe;
    RestrictedZone? worstZone;
    double? minDistance;

    for (final zone in state.zones) {
      if (zone.severity == 'DANGER' || zone.severity == 'CLOSED') {
        final distance = Geolocator.distanceBetween(
          userLoc.latitude,
          userLoc.longitude,
          zone.centerLat,
          zone.centerLng,
        );

        final radiusInMeters = zone.radiusKm * 1000;
        if (distance <= radiusInMeters) {
          worstStatus = MapSafetyStatus.danger;
          worstZone = zone;
          minDistance = distance;
          break; // Already in danger
        } else if (distance <= radiusInMeters + 1000) {
          if (worstStatus != MapSafetyStatus.danger) {
            worstStatus = MapSafetyStatus.warning;
            worstZone = zone;
            minDistance = distance;
          }
        }
      }
    }

    if (state.safetyStatus != worstStatus) {
      _triggerAlertFeedback(worstStatus);
    }

    state = state.copyWith(
      safetyStatus: worstStatus,
      activeWarningZone: worstZone,
      distanceToDanger: minDistance,
    );
  }

  Future<void> _triggerAlertFeedback(MapSafetyStatus status) async {
    if (status == MapSafetyStatus.warning) {
      Vibration.vibrate(duration: 500);
    } else if (status == MapSafetyStatus.danger) {
      Vibration.vibrate(pattern: [500, 200, 500, 200, 500]);
    }
  }

  void toggleHotspots() {
    state = state.copyWith(showHotspots: !state.showHotspots);
  }

  void toggleCatches() {
    state = state.copyWith(showCatches: !state.showCatches);
  }

  Future<bool> sendSOS() async {
    if (state.userLocation == null) return false;
    
    state = state.copyWith(isSOSActive: true);
    final success = await _repository.sendSOS(
      state.userLocation!.latitude,
      state.userLocation!.longitude,
    );
    
    if (success) {
      // Keep it active for visual effect
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) state = state.copyWith(isSOSActive: false);
      });
    } else {
      state = state.copyWith(isSOSActive: false);
    }
    return success;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
