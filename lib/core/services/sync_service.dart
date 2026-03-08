import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocevara/core/models/catch_log.dart';
import 'package:ocevara/core/services/catch_log_repository.dart';
import 'package:ocevara/core/services/database_service.dart';

final syncServiceProvider = Provider((ref) => SyncService(ref.read(catchLogRepositoryProvider)));

class SyncService {
  final CatchLogRepository _repository;

  SyncService(this._repository);

  Future<void> performSync() async {
    final unsyncedLogs = await _getUnsyncedLogs();
    
    for (final log in unsyncedLogs) {
      try {
        final success = await _repository.uploadCatch(log.userId, log);
        if (success) {
          await _markLogAsSynced(log.id);
        }
      } catch (e) {
        
        continue;
      }
    }
  }

  Future<List<CatchLog>> _getUnsyncedLogs() async {
    final allLogs = await DatabaseService.instance.getAllCatches();
    return allLogs.where((log) => !log.synced).toList();
  }

  Future<void> _markLogAsSynced(String id) async {
    final logs = await DatabaseService.instance.getAllCatches();
    final log = logs.firstWhere((l) => l.id == id);
    
    final updatedLog = log.copyWith(synced: true);
    await DatabaseService.instance.insertCatch(updatedLog);
  }
}
