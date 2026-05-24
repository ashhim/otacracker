import 'dart:convert';

import '../models/ble_characteristic_info.dart';
import '../models/ble_device_record.dart';
import '../models/ble_service_info.dart';
import '../models/ota_channel.dart';
import 'ble_uuid_catalog.dart';

class BleProtocolAnalyzer {
  const BleProtocolAnalyzer();

  bool isWatchCandidate(BleDeviceRecord record) {
    if (BleUuidCatalog.isWatchLikeName(record.displayName)) {
      return true;
    }
    return record.serviceUuids.any((uuid) {
      final value = uuid.toLowerCase();
      return BleUuidCatalog.otaServiceKeywords.any(value.contains);
    });
  }

  List<OtaChannel> detectOtaChannels(List<BleServiceInfo> services) {
    final channels = <OtaChannel>[];
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final score = _scoreCharacteristic(service, characteristic);
        if (score <= 0) {
          continue;
        }
        channels.add(
          OtaChannel(
            characteristicId: characteristic.id,
            serviceUuid: service.uuid,
            characteristicUuid: characteristic.uuid,
            label: '${service.label} / ${characteristic.label}',
            score: score,
            supportsWriteWithResponse: characteristic.canWrite,
            supportsWriteWithoutResponse: characteristic.canWriteWithoutResponse,
            supportsNotify: characteristic.canNotify || characteristic.canIndicate,
            reasoning: _reasons(service, characteristic),
          ),
        );
      }
    }
    channels.sort((left, right) => right.score.compareTo(left.score));
    return channels;
  }

  List<String> detectDfuServices(List<BleServiceInfo> services) {
    return services
        .where((service) {
          final label = service.label.toLowerCase();
          final uuid = service.uuid.toLowerCase();
          return label.contains('dfu') || uuid.contains('1530') || uuid.contains('fe59');
        })
        .map((service) => service.uuid)
        .toList(growable: false);
  }

  List<String> detectUartServices(List<BleServiceInfo> services) {
    return services
        .where((service) {
          final label = service.label.toLowerCase();
          final uuid = service.uuid.toLowerCase();
          return label.contains('uart') || uuid.contains('6e400001') || uuid.contains('ffd0');
        })
        .map((service) => service.uuid)
        .toList(growable: false);
  }

  String buildTopologyJson(BleDeviceRecord device, List<BleServiceInfo> services) {
    final payload = {
      'device': device.toJson(),
      'services': services.map((value) => value.toJson()).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  int _scoreCharacteristic(BleServiceInfo service, BleCharacteristicInfo characteristic) {
    var score = 0;
    final merged = '${service.uuid} ${service.label} ${characteristic.uuid} ${characteristic.label}'.toLowerCase();
    if (characteristic.canWrite || characteristic.canWriteWithoutResponse) {
      score += 20;
    }
    if (characteristic.canNotify || characteristic.canIndicate) {
      score += 10;
    }
    for (final keyword in BleUuidCatalog.otaServiceKeywords) {
      if (merged.contains(keyword)) {
        score += 15;
      }
    }
    if (merged.contains('uart')) {
      score += 8;
    }
    if (merged.contains('ffd') || merged.contains('ffe')) {
      score += 6;
    }
    return score;
  }

  List<String> _reasons(BleServiceInfo service, BleCharacteristicInfo characteristic) {
    final reasons = <String>[];
    if (characteristic.canWrite) {
      reasons.add('Supports write with response');
    }
    if (characteristic.canWriteWithoutResponse) {
      reasons.add('Supports write without response');
    }
    if (characteristic.canNotify || characteristic.canIndicate) {
      reasons.add('Supports notification or indication');
    }
    final merged = '${service.label} ${characteristic.label}'.toLowerCase();
    for (final keyword in BleUuidCatalog.otaServiceKeywords) {
      if (merged.contains(keyword)) {
        reasons.add('Matches OTA keyword: $keyword');
      }
    }
    if (reasons.isEmpty) {
      reasons.add('Writable transport characteristic');
    }
    return reasons;
  }
}
