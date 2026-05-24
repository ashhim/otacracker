class AppSettings {
  const AppSettings({
    required this.scanKeywords,
    required this.autoReconnect,
    required this.requestedMtu,
    required this.chunkSize,
    required this.packetDelayMs,
    required this.maxRetries,
    required this.useWriteWithoutResponse,
    required this.requireAck,
    required this.useCommercialLicense,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      scanKeywords: [
        't800',
        'ultra',
        'watch',
        'smartwatch',
        'hiwatch',
        'hiwatchpro',
      ],
      autoReconnect: false,
      requestedMtu: 247,
      chunkSize: 180,
      packetDelayMs: 12,
      maxRetries: 4,
      useWriteWithoutResponse: true,
      requireAck: false,
      useCommercialLicense: false,
    );
  }

  final List<String> scanKeywords;
  final bool autoReconnect;
  final int requestedMtu;
  final int chunkSize;
  final int packetDelayMs;
  final int maxRetries;
  final bool useWriteWithoutResponse;
  final bool requireAck;
  final bool useCommercialLicense;

  AppSettings copyWith({
    List<String>? scanKeywords,
    bool? autoReconnect,
    int? requestedMtu,
    int? chunkSize,
    int? packetDelayMs,
    int? maxRetries,
    bool? useWriteWithoutResponse,
    bool? requireAck,
    bool? useCommercialLicense,
  }) {
    return AppSettings(
      scanKeywords: scanKeywords ?? this.scanKeywords,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      requestedMtu: requestedMtu ?? this.requestedMtu,
      chunkSize: chunkSize ?? this.chunkSize,
      packetDelayMs: packetDelayMs ?? this.packetDelayMs,
      maxRetries: maxRetries ?? this.maxRetries,
      useWriteWithoutResponse: useWriteWithoutResponse ?? this.useWriteWithoutResponse,
      requireAck: requireAck ?? this.requireAck,
      useCommercialLicense: useCommercialLicense ?? this.useCommercialLicense,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanKeywords': scanKeywords,
      'autoReconnect': autoReconnect,
      'requestedMtu': requestedMtu,
      'chunkSize': chunkSize,
      'packetDelayMs': packetDelayMs,
      'maxRetries': maxRetries,
      'useWriteWithoutResponse': useWriteWithoutResponse,
      'requireAck': requireAck,
      'useCommercialLicense': useCommercialLicense,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      scanKeywords: (json['scanKeywords'] as List<dynamic>? ?? defaults.scanKeywords)
          .map((value) => value.toString())
          .toList(),
      autoReconnect: json['autoReconnect'] as bool? ?? defaults.autoReconnect,
      requestedMtu: json['requestedMtu'] as int? ?? defaults.requestedMtu,
      chunkSize: json['chunkSize'] as int? ?? defaults.chunkSize,
      packetDelayMs: json['packetDelayMs'] as int? ?? defaults.packetDelayMs,
      maxRetries: json['maxRetries'] as int? ?? defaults.maxRetries,
      useWriteWithoutResponse:
          json['useWriteWithoutResponse'] as bool? ?? defaults.useWriteWithoutResponse,
      requireAck: json['requireAck'] as bool? ?? defaults.requireAck,
      useCommercialLicense: json['useCommercialLicense'] as bool? ?? defaults.useCommercialLicense,
    );
  }
}
