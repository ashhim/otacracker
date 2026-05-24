import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../models/app_log_entry.dart';
import '../models/ble_packet.dart';

class LogService extends ChangeNotifier {
  final List<AppLogEntry> _entries = <AppLogEntry>[];
  final List<BlePacket> _packets = <BlePacket>[];
  BlePacket? _selectedPacket;
  int _packetSequence = 0;

  List<AppLogEntry> get entries => List.unmodifiable(_entries.reversed);
  List<BlePacket> get packets => List.unmodifiable(_packets.reversed);
  BlePacket? get selectedPacket => _selectedPacket;

  void info(String message) => _append(AppLogLevel.info, message);
  void warning(String message) => _append(AppLogLevel.warning, message);
  void error(String message) => _append(AppLogLevel.error, message);
  void debug(String message) => _append(AppLogLevel.debug, message);

  void _append(AppLogLevel level, String message) {
    _entries.add(AppLogEntry(timestamp: DateTime.now(), level: level, message: message));
    if (_entries.length > AppConstants.appLogBufferLimit) {
      _entries.removeRange(0, _entries.length - AppConstants.appLogBufferLimit);
    }
    notifyListeners();
  }

  BlePacket recordPacket({
    required BlePacketDirection direction,
    required BlePacketKind kind,
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> bytes,
    String? note,
  }) {
    final packet = BlePacket(
      sequence: ++_packetSequence,
      direction: direction,
      kind: kind,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      timestamp: DateTime.now(),
      bytes: List<int>.from(bytes),
      note: note,
    );
    _packets.add(packet);
    if (_packets.length > AppConstants.packetBufferLimit) {
      _packets.removeRange(0, _packets.length - AppConstants.packetBufferLimit);
    }
    notifyListeners();
    return packet;
  }

  void selectPacket(BlePacket? packet) {
    _selectedPacket = packet;
    notifyListeners();
  }

  void clearPackets() {
    _packets.clear();
    _selectedPacket = null;
    notifyListeners();
  }

  void clearLogs() {
    _entries.clear();
    notifyListeners();
  }

  List<BlePacket> packetsForDevice(String deviceId) {
    return _packets.where((packet) => packet.deviceId == deviceId).toList(growable: false);
  }
}
