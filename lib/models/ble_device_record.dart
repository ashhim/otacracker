class BleDeviceRecord {
  const BleDeviceRecord({
    required this.id,
    required this.advName,
    required this.platformName,
    required this.rssi,
    required this.connectable,
    required this.lastSeen,
    required this.manufacturerData,
    required this.serviceUuids,
    required this.txPowerLevel,
    required this.isConnected,
    required this.isWatchCandidate,
    required this.advertisementCount,
  });

  final String id;
  final String advName;
  final String platformName;
  final int rssi;
  final bool connectable;
  final DateTime lastSeen;
  final Map<String, String> manufacturerData;
  final List<String> serviceUuids;
  final int? txPowerLevel;
  final bool isConnected;
  final bool isWatchCandidate;
  final int advertisementCount;

  String get displayName {
    final preferred = advName.trim().isNotEmpty ? advName.trim() : platformName.trim();
    return preferred.isEmpty ? 'Unknown BLE Device' : preferred;
  }

  double get signalScore {
    final normalized = ((rssi + 100) / 60).clamp(0.0, 1.0);
    return normalized.toDouble();
  }

  BleDeviceRecord copyWith({
    String? advName,
    String? platformName,
    int? rssi,
    bool? connectable,
    DateTime? lastSeen,
    Map<String, String>? manufacturerData,
    List<String>? serviceUuids,
    int? txPowerLevel,
    bool? isConnected,
    bool? isWatchCandidate,
    int? advertisementCount,
  }) {
    return BleDeviceRecord(
      id: id,
      advName: advName ?? this.advName,
      platformName: platformName ?? this.platformName,
      rssi: rssi ?? this.rssi,
      connectable: connectable ?? this.connectable,
      lastSeen: lastSeen ?? this.lastSeen,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      txPowerLevel: txPowerLevel ?? this.txPowerLevel,
      isConnected: isConnected ?? this.isConnected,
      isWatchCandidate: isWatchCandidate ?? this.isWatchCandidate,
      advertisementCount: advertisementCount ?? this.advertisementCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advName': advName,
      'platformName': platformName,
      'rssi': rssi,
      'connectable': connectable,
      'lastSeen': lastSeen.toIso8601String(),
      'manufacturerData': manufacturerData,
      'serviceUuids': serviceUuids,
      'txPowerLevel': txPowerLevel,
      'isConnected': isConnected,
      'isWatchCandidate': isWatchCandidate,
      'advertisementCount': advertisementCount,
    };
  }

  factory BleDeviceRecord.fromJson(Map<String, dynamic> json) {
    return BleDeviceRecord(
      id: json['id'] as String? ?? '',
      advName: json['advName'] as String? ?? '',
      platformName: json['platformName'] as String? ?? '',
      rssi: json['rssi'] as int? ?? -100,
      connectable: json['connectable'] as bool? ?? false,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
      manufacturerData: (json['manufacturerData'] as Map<dynamic, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
      serviceUuids: (json['serviceUuids'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      txPowerLevel: json['txPowerLevel'] as int?,
      isConnected: json['isConnected'] as bool? ?? false,
      isWatchCandidate: json['isWatchCandidate'] as bool? ?? false,
      advertisementCount: json['advertisementCount'] as int? ?? 0,
    );
  }
}
