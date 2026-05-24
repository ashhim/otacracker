import 'package:uuid/uuid.dart';

import '../utils/hex_utils.dart';

enum BlePacketDirection { incoming, outgoing, system }

enum BlePacketKind { read, write, notify, indication, replay, descriptor, advertisement, otaHeader, metadata }

class BlePacket {
  BlePacket({
    String? id,
    required this.sequence,
    required this.direction,
    required this.kind,
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.timestamp,
    required this.bytes,
    this.note,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int sequence;
  final BlePacketDirection direction;
  final BlePacketKind kind;
  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final DateTime timestamp;
  final List<int> bytes;
  final String? note;

  String get hex => HexUtils.bytesToHex(bytes, spaced: true);
  String get ascii => HexUtils.bytesToAscii(bytes);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'direction': direction.name,
      'kind': kind.name,
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'timestamp': timestamp.toIso8601String(),
      'bytes': HexUtils.bytesToHex(bytes),
      'note': note,
    };
  }

  factory BlePacket.fromJson(Map<String, dynamic> json) {
    return BlePacket(
      id: json['id'] as String?,
      sequence: json['sequence'] as int? ?? 0,
      direction: BlePacketDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => BlePacketDirection.system,
      ),
      kind: BlePacketKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => BlePacketKind.metadata,
      ),
      deviceId: json['deviceId'] as String? ?? '',
      serviceUuid: json['serviceUuid'] as String? ?? '',
      characteristicUuid: json['characteristicUuid'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      bytes: HexUtils.hexToBytes(json['bytes'] as String? ?? '').toList(),
      note: json['note'] as String?,
    );
  }
}
