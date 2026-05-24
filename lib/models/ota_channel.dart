class OtaChannel {
  const OtaChannel({
    required this.characteristicId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.label,
    required this.score,
    required this.supportsWriteWithResponse,
    required this.supportsWriteWithoutResponse,
    required this.supportsNotify,
    required this.reasoning,
  });

  final String characteristicId;
  final String serviceUuid;
  final String characteristicUuid;
  final String label;
  final int score;
  final bool supportsWriteWithResponse;
  final bool supportsWriteWithoutResponse;
  final bool supportsNotify;
  final List<String> reasoning;

  Map<String, dynamic> toJson() {
    return {
      'characteristicId': characteristicId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'label': label,
      'score': score,
      'supportsWriteWithResponse': supportsWriteWithResponse,
      'supportsWriteWithoutResponse': supportsWriteWithoutResponse,
      'supportsNotify': supportsNotify,
      'reasoning': reasoning,
    };
  }

  factory OtaChannel.fromJson(Map<String, dynamic> json) {
    return OtaChannel(
      characteristicId: json['characteristicId'] as String? ?? '',
      serviceUuid: json['serviceUuid'] as String? ?? '',
      characteristicUuid: json['characteristicUuid'] as String? ?? '',
      label: json['label'] as String? ?? 'Unknown channel',
      score: json['score'] as int? ?? 0,
      supportsWriteWithResponse: json['supportsWriteWithResponse'] as bool? ?? false,
      supportsWriteWithoutResponse: json['supportsWriteWithoutResponse'] as bool? ?? false,
      supportsNotify: json['supportsNotify'] as bool? ?? false,
      reasoning: (json['reasoning'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}
