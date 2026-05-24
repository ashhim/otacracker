class OtaJobConfig {
  const OtaJobConfig({
    required this.deviceId,
    required this.channelCharacteristicId,
    required this.ackCharacteristicId,
    required this.chunkSize,
    required this.delayMs,
    required this.maxRetries,
    required this.timeoutMs,
    required this.requestedMtu,
    required this.useWriteWithoutResponse,
    required this.requireAck,
    required this.resumeOffset,
  });

  final String deviceId;
  final String channelCharacteristicId;
  final String? ackCharacteristicId;
  final int chunkSize;
  final int delayMs;
  final int maxRetries;
  final int timeoutMs;
  final int requestedMtu;
  final bool useWriteWithoutResponse;
  final bool requireAck;
  final int resumeOffset;

  OtaJobConfig copyWith({
    String? channelCharacteristicId,
    String? ackCharacteristicId,
    int? chunkSize,
    int? delayMs,
    int? maxRetries,
    int? timeoutMs,
    int? requestedMtu,
    bool? useWriteWithoutResponse,
    bool? requireAck,
    int? resumeOffset,
  }) {
    return OtaJobConfig(
      deviceId: deviceId,
      channelCharacteristicId: channelCharacteristicId ?? this.channelCharacteristicId,
      ackCharacteristicId: ackCharacteristicId ?? this.ackCharacteristicId,
      chunkSize: chunkSize ?? this.chunkSize,
      delayMs: delayMs ?? this.delayMs,
      maxRetries: maxRetries ?? this.maxRetries,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      requestedMtu: requestedMtu ?? this.requestedMtu,
      useWriteWithoutResponse: useWriteWithoutResponse ?? this.useWriteWithoutResponse,
      requireAck: requireAck ?? this.requireAck,
      resumeOffset: resumeOffset ?? this.resumeOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'channelCharacteristicId': channelCharacteristicId,
      'ackCharacteristicId': ackCharacteristicId,
      'chunkSize': chunkSize,
      'delayMs': delayMs,
      'maxRetries': maxRetries,
      'timeoutMs': timeoutMs,
      'requestedMtu': requestedMtu,
      'useWriteWithoutResponse': useWriteWithoutResponse,
      'requireAck': requireAck,
      'resumeOffset': resumeOffset,
    };
  }

  factory OtaJobConfig.fromJson(Map<String, dynamic> json) {
    return OtaJobConfig(
      deviceId: json['deviceId'] as String? ?? '',
      channelCharacteristicId: json['channelCharacteristicId'] as String? ?? '',
      ackCharacteristicId: json['ackCharacteristicId'] as String?,
      chunkSize: json['chunkSize'] as int? ?? 180,
      delayMs: json['delayMs'] as int? ?? 12,
      maxRetries: json['maxRetries'] as int? ?? 4,
      timeoutMs: json['timeoutMs'] as int? ?? 1200,
      requestedMtu: json['requestedMtu'] as int? ?? 247,
      useWriteWithoutResponse: json['useWriteWithoutResponse'] as bool? ?? true,
      requireAck: json['requireAck'] as bool? ?? false,
      resumeOffset: json['resumeOffset'] as int? ?? 0,
    );
  }
}
