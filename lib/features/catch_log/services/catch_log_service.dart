import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocevara/core/models/catch_log.dart';
import 'package:ocevara/core/services/database_service.dart';

final catchLogServiceProvider = StateNotifierProvider<CatchLogService, List<CatchLog>>((ref) {
  return CatchLogService.instance;
});

class CatchLogService extends StateNotifier<List<CatchLog>> {
  static final CatchLogService instance = CatchLogService();

  CatchLogService() : super([]) {
    _loadLogs();
  }

  // Temporary species list, should ideally come from a SpeciesRepository
  final List<String> _speciesList = [
    'Red Snapper',
    'Grouper',
    'Tuna',
    'Tilapia',
    'Catfish',
    'Mackerel',
    'Salmon',
  ];

  List<String> get speciesList => _speciesList;

  Future<void> _loadLogs() async {
    final logs = await DatabaseService.instance.getAllCatches();
    state = logs;
  }

  int get totalLogs => state.length;
  int get totalFish => state.fold(0, (p, e) => p + e.quantity.toInt());
  double get totalWeightKg => state.fold(0.0, (p, e) => p + (e.avgWeight ?? 0.0) * e.quantity);
  int get speciesCount => state.map((e) => e.speciesId).toSet().length;

  Future<void> addLog(CatchLog log) async {
    await DatabaseService.instance.insertCatch(log);
    state = [log, ...state];
  }

  Future<void> deleteLog(String id) async {
    await DatabaseService.instance.deleteCatch(id);
    state = state.where((l) => l.id != id).toList();
  }

  Future<void> markSynced(String id) async {
    final index = state.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(synced: true);
      await DatabaseService.instance.insertCatch(updated);
      state = [
        for (final log in state)
          if (log.id == id) updated else log
      ];
    }
  }

  void clear() {
    state = [];
  }
}
