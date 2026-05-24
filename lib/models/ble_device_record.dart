class BleDeviceRecord {
  const BleDeviceRecord({
    required this.id,
    required this.advName,
    required this.platformName,
    required this.rssi,
    required this.connectable,
    required this.lastSeen,
    required this.manufacturerData,
    required this.serviceData,
    required this.serviceUuids,
    required this.txPowerLevel,
    required this.appearance,
    required this.isConnected,
    required this.isWatchCandidate,
    required this.advertisementCount,
    required this.rssiHistory,
  });

  final String id;
  final String advName;
  final String platformName;
  final int rssi;
  final bool connectable;
  final DateTime lastSeen;
  final Map<String, String> manufacturerData;
  final Map<String, String> serviceData;
  final List<String> serviceUuids;
  final int? txPowerLevel;
  final int? appearance;
  final bool isConnected;
  final bool isWatchCandidate;
  final int advertisementCount;
  final List<int> rssiHistory;

  String get displayName {
    final preferred = advName.trim().isNotEmpty ? advName.trim() : platformName.trim();
    return preferred.isEmpty ? 'Unknown BLE Device' : preferred;
  }

  double get signalScore {
    final normalized = ((rssi + 100) / 60).clamp(0.0, 1.0);
    return normalized.toDouble();
  }

  double get averageRssi {
    if (rssiHistory.isEmpty) {
      return rssi.toDouble();
    }
    final total = rssiHistory.fold<int>(0, (sum, value) => sum + value);
    return total / rssiHistory.length;
  }

  String get advertisementSummary {
    final manufacturer = manufacturerData.entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
    final service = serviceData.entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
    return [
      if (manufacturer.isNotEmpty) 'MSD[$manufacturer]',
      if (service.isNotEmpty) 'SD[$service]',
      if (serviceUuids.isNotEmpty) 'UUIDS[${serviceUuids.take(4).join(', ')}${serviceUuids.length > 4 ? ', ...' : ''}]',
      if (appearance != null) 'APP:$appearance',
      if (txPowerLevel != null) 'TX:$txPowerLevel',
    ].join(' | ');
  }

  BleDeviceRecord copyWith({
    String? advName,
    String? platformName,
    int? rssi,
    bool? connectable,
    DateTime? lastSeen,
    Map<String, String>? manufacturerData,
    Map<String, String>? serviceData,
    List<String>? serviceUuids,
    int? txPowerLevel,
    int? appearance,
    bool? isConnected,
    bool? isWatchCandidate,
    int? advertisementCount,
    List<int>? rssiHistory,
  }) {
    return BleDeviceRecord(
      id: id,
      advName: advName ?? this.advName,
      platformName: platformName ?? this.platformName,
      rssi: rssi ?? this.rssi,
      connectable: connectable ?? this.connectable,
      lastSeen: lastSeen ?? this.lastSeen,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      serviceData: serviceData ?? this.serviceData,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      txPowerLevel: txPowerLevel ?? this.txPowerLevel,
      appearance: appearance ?? this.appearance,
      isConnected: isConnected ?? this.isConnected,
      isWatchCandidate: isWatchCandidate ?? this.isWatchCandidate,
      advertisementCount: advertisementCount ?? this.advertisementCount,
      rssiHistory: rssiHistory ?? this.rssiHistory,
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
      'serviceData': serviceData,
      'serviceUuids': serviceUuids,
      'txPowerLevel': txPowerLevel,
      'appearance': appearance,
      'isConnected': isConnected,
      'isWatchCandidate': isWatchCandidate,
      'advertisementCount': advertisementCount,
      'rssiHistory': rssiHistory,
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
      serviceData: (json['serviceData'] as Map<dynamic, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
      serviceUuids: (json['serviceUuids'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      txPowerLevel: json['txPowerLevel'] as int?,
      appearance: json['appearance'] as int?,
      isConnected: json['isConnected'] as bool? ?? false,
      isWatchCandidate: json['isWatchCandidate'] as bool? ?? false,
      advertisementCount: json['advertisementCount'] as int? ?? 0,
      rssiHistory: (json['rssiHistory'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
    );
  }
}
