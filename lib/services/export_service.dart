import 'dart:convert';
import 'dart:typed_data';

import '../core/app_constants.dart';
import '../models/app_log_entry.dart';
import '../models/ble_packet.dart';
import '../models/device_session.dart';
import '../utils/format_utils.dart';
import 'storage_service.dart';

class ExportService {
  const ExportService(this._storageService);

  final StorageService _storageService;

  Future<String> exportPacketsJson(List<BlePacket> packets, {String prefix = 'packets'}) async {
    final name = '${AppConstants.exportsDirectory}/${prefix}_${FormatUtils.fileStamp(DateTime.now())}.json';
    final content = const JsonEncoder.withIndent('  ').convert(
      packets.map((value) => value.toJson()).toList(),
    );
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportPacketsText(List<BlePacket> packets, {String prefix = 'packets'}) async {
    final name = '${AppConstants.exportsDirectory}/${prefix}_${FormatUtils.fileStamp(DateTime.now())}.txt';
    final lines = packets.map(
      (packet) =>
          '${packet.sequence.toString().padLeft(5, '0')} '
          '${packet.timestamp.toIso8601String()} '
          '${packet.direction.name.toUpperCase()} '
          '${packet.kind.name.toUpperCase()} '
          '${packet.serviceUuid}/${packet.characteristicUuid} '
          '${packet.hex}'
          '${packet.note == null ? '' : ' | ${packet.note}'}',
    );
    final file = await _storageService.writeText(name, lines.join('\n'));
    return file.path;
  }

  Future<String> exportTopology(String content, {String prefix = 'topology'}) async {
    final name = '${AppConstants.exportsDirectory}/${prefix}_${FormatUtils.fileStamp(DateTime.now())}.json';
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportLogs(List<AppLogEntry> entries) async {
    final name = '${AppConstants.logsDirectory}/app_log_${FormatUtils.fileStamp(DateTime.now())}.json';
    final content = const JsonEncoder.withIndent('  ').convert(
      entries.map((entry) => entry.toJson()).toList(),
    );
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportSession(DeviceSession session) async {
    final name =
        '${AppConstants.sessionsDirectory}/session_${session.device.displayName.replaceAll(' ', '_')}_${FormatUtils.fileStamp(session.createdAt)}.json';
    final content = const JsonEncoder.withIndent('  ').convert(session.toJson());
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportBytes(Uint8List bytes, String fileName, String subDirectory) async {
    final path = '$subDirectory/$fileName';
    final file = await _storageService.writeBytes(path, bytes);
    return file.path;
  }
}
