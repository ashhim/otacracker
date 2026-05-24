import 'ble_device_record.dart';
import 'ble_packet.dart';

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.createdAt,
    required this.device,
    required this.topologyJson,
    required this.packets,
    required this.notes,
  });

  final String id;
  final DateTime createdAt;
  final BleDeviceRecord device;
  final String topologyJson;
  final List<BlePacket> packets;
  final String notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'device': device.toJson(),
      'topologyJson': topologyJson,
      'packets': packets.map((value) => value.toJson()).toList(),
      'notes': notes,
    };
  }

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      device: BleDeviceRecord.fromJson((json['device'] as Map<dynamic, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key.toString(), value))),
      topologyJson: json['topologyJson'] as String? ?? '{}',
      packets: (json['packets'] as List<dynamic>? ?? const [])
          .map((value) => BlePacket.fromJson(
                (value as Map<dynamic, dynamic>).map((key, nested) => MapEntry(key.toString(), nested)),
              ))
          .toList(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
