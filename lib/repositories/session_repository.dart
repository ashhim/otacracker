import 'dart:convert';
import 'dart:io';

import '../core/app_constants.dart';
import '../models/device_session.dart';
import '../services/storage_service.dart';

class SessionRepository {
  const SessionRepository(this._storageService);

  final StorageService _storageService;

  Future<List<DeviceSession>> listSessions() async {
    final files = await _storageService.listFiles(AppConstants.sessionsDirectory);
    final sessions = <DeviceSession>[];
    for (final entity in files.whereType<File>()) {
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is Map<String, dynamic>) {
          sessions.add(DeviceSession.fromJson(decoded));
        } else if (decoded is Map) {
          sessions.add(DeviceSession.fromJson(decoded.map((key, value) => MapEntry(key.toString(), value))));
        }
      } catch (_) {
        continue;
      }
    }
    sessions.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return sessions;
  }

  Future<void> save(DeviceSession session) async {
    final name = '${AppConstants.sessionsDirectory}/${session.id}.json';
    await _storageService.writeText(name, const JsonEncoder.withIndent('  ').convert(session.toJson()));
  }
}
