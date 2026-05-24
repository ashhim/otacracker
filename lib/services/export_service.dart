import 'dart:convert';
import 'dart:typed_data';

import '../core/app_constants.dart';
import '../models/app_log_entry.dart';
import '../models/ble_device_record.dart';
import '../models/ble_packet.dart';
import '../models/ble_service_info.dart';
import '../models/device_session.dart';
import '../models/device_insights.dart';
import '../models/firmware_metadata.dart';
import '../utils/binary_utils.dart';
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

  Future<String> exportTopologyLog(String content, {String prefix = 'topology'}) async {
    final name = '${AppConstants.exportsDirectory}/${prefix}_${FormatUtils.fileStamp(DateTime.now())}.log';
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

  Future<String> exportScanResultsJson(List<BleDeviceRecord> devices) async {
    final name = '${AppConstants.exportsDirectory}/scan_results_${FormatUtils.fileStamp(DateTime.now())}.json';
    final content = const JsonEncoder.withIndent('  ').convert(
      {
        'generatedAt': DateTime.now().toIso8601String(),
        'deviceCount': devices.length,
        'devices': devices.map((device) => device.toJson()).toList(),
      },
    );
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportScanResultsText(List<BleDeviceRecord> devices) async {
    final name = '${AppConstants.exportsDirectory}/scan_results_${FormatUtils.fileStamp(DateTime.now())}.txt';
    final lines = <String>[
      'Generated: ${DateTime.now().toIso8601String()}',
      'Devices: ${devices.length}',
      '',
      ...devices.map(
        (device) =>
            '${device.displayName} | ${device.id} | RSSI ${device.rssi} | Seen ${device.advertisementCount} | '
            '${device.advertisementSummary}',
      ),
    ];
    final file = await _storageService.writeText(name, lines.join('\n'));
    return file.path;
  }

  Future<String> exportScanResultsLog(List<BleDeviceRecord> devices) async {
    final name = '${AppConstants.exportsDirectory}/scan_results_${FormatUtils.fileStamp(DateTime.now())}.log';
    final lines = devices.map(
      (device) =>
          '[${device.lastSeen.toIso8601String()}] ${device.displayName} ${device.id} RSSI=${device.rssi} '
          'WATCH=${device.isWatchCandidate} ${device.advertisementSummary}',
    );
    final file = await _storageService.writeText(name, lines.join('\n'));
    return file.path;
  }

  Future<String> exportDeviceProfile({
    required BleDeviceRecord device,
    required DeviceInsights insights,
    required List<BleServiceInfo> services,
    required Map<String, Map<String, List<int>>> descriptorValues,
  }) async {
    final fingerprint = BinaryUtils.sha256Hex(
      utf8.encode([
        device.id,
        device.displayName,
        ...device.serviceUuids,
        ...device.manufacturerData.entries.map((entry) => '${entry.key}:${entry.value}'),
      ].join('|')),
    );
    final name = '${AppConstants.exportsDirectory}/device_profile_${device.displayName.replaceAll(' ', '_')}_${FormatUtils.fileStamp(DateTime.now())}.json';
    final content = const JsonEncoder.withIndent('  ').convert(
      {
        'generatedAt': DateTime.now().toIso8601String(),
        'fingerprint': fingerprint,
        'device': device.toJson(),
        'insights': insights.toJson(),
        'services': services.map((service) => service.toJson()).toList(),
        'descriptorValues': descriptorValues.map(
          (key, value) => MapEntry(
            key,
            value.map(
              (descriptorUuid, bytes) => MapEntry(
                descriptorUuid,
                bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
              ),
            ),
          ),
        ),
      },
    );
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportFirmwareMetadata(FirmwareMetadata metadata) async {
    final name = '${AppConstants.exportsDirectory}/firmware_metadata_${FormatUtils.fileStamp(DateTime.now())}.json';
    final content = const JsonEncoder.withIndent('  ').convert(metadata.toJson());
    final file = await _storageService.writeText(name, content);
    return file.path;
  }

  Future<String> exportFirmwareMetadataText(FirmwareMetadata metadata) async {
    final name = '${AppConstants.exportsDirectory}/firmware_metadata_${FormatUtils.fileStamp(DateTime.now())}.txt';
    final lines = <String>[
      'File: ${metadata.fileName}',
      'Size: ${metadata.sizeBytes}',
      'SHA-256: ${metadata.sha256}',
      'CRC32: ${metadata.crc32Hex}',
      'OTA Format: ${metadata.possibleOtaFormat}',
      'Entropy: ${metadata.entropy.toStringAsFixed(3)}',
      'Signatures: ${metadata.signatures.join(', ')}',
      '',
      'Header Fields:',
      ...metadata.headerFields.entries.map((entry) => '  ${entry.key}: ${entry.value}'),
      '',
      'Embedded Strings:',
      ...metadata.asciiStrings.map((value) => '  $value'),
    ];
    final file = await _storageService.writeText(name, lines.join('\n'));
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
