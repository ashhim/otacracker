enum OtaTransferStatus { idle, preparing, uploading, completed, cancelled, failed }

class OtaTransferState {
  const OtaTransferState({
    required this.status,
    required this.fileName,
    required this.totalBytes,
    required this.sentBytes,
    required this.chunkSize,
    required this.mtu,
    required this.retries,
    required this.bytesPerSecond,
    required this.startedAt,
    required this.lastUpdatedAt,
    required this.resumeOffset,
    this.error,
  });

  factory OtaTransferState.idle() {
    final now = DateTime.now();
    return OtaTransferState(
      status: OtaTransferStatus.idle,
      fileName: '',
      totalBytes: 0,
      sentBytes: 0,
      chunkSize: 0,
      mtu: 23,
      retries: 0,
      bytesPerSecond: 0,
      startedAt: now,
      lastUpdatedAt: now,
      resumeOffset: 0,
    );
  }

  final OtaTransferStatus status;
  final String fileName;
  final int totalBytes;
  final int sentBytes;
  final int chunkSize;
  final int mtu;
  final int retries;
  final double bytesPerSecond;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final int resumeOffset;
  final String? error;

  double get progress => totalBytes == 0 ? 0 : sentBytes / totalBytes;

  OtaTransferState copyWith({
    OtaTransferStatus? status,
    String? fileName,
    int? totalBytes,
    int? sentBytes,
    int? chunkSize,
    int? mtu,
    int? retries,
    double? bytesPerSecond,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    int? resumeOffset,
    String? error,
  }) {
    return OtaTransferState(
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      sentBytes: sentBytes ?? this.sentBytes,
      chunkSize: chunkSize ?? this.chunkSize,
      mtu: mtu ?? this.mtu,
      retries: retries ?? this.retries,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      resumeOffset: resumeOffset ?? this.resumeOffset,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'fileName': fileName,
      'totalBytes': totalBytes,
      'sentBytes': sentBytes,
      'chunkSize': chunkSize,
      'mtu': mtu,
      'retries': retries,
      'bytesPerSecond': bytesPerSecond,
      'startedAt': startedAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'resumeOffset': resumeOffset,
      'error': error,
    };
  }

  factory OtaTransferState.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return OtaTransferState(
      status: OtaTransferStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => OtaTransferStatus.idle,
      ),
      fileName: json['fileName'] as String? ?? '',
      totalBytes: json['totalBytes'] as int? ?? 0,
      sentBytes: json['sentBytes'] as int? ?? 0,
      chunkSize: json['chunkSize'] as int? ?? 0,
      mtu: json['mtu'] as int? ?? 23,
      retries: json['retries'] as int? ?? 0,
      bytesPerSecond: (json['bytesPerSecond'] as num?)?.toDouble() ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? now,
      lastUpdatedAt: DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ?? now,
      resumeOffset: json['resumeOffset'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}
