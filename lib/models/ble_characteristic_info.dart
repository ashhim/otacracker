class BleCharacteristicInfo {
  const BleCharacteristicInfo({
    required this.id,
    required this.deviceId,
    required this.serviceUuid,
    required this.uuid,
    required this.primaryServiceUuid,
    required this.instanceId,
    required this.canRead,
    required this.canWrite,
    required this.canWriteWithoutResponse,
    required this.canNotify,
    required this.canIndicate,
    required this.isNotifying,
    required this.descriptorUuids,
    required this.label,
    this.lastValueHex,
  });

  final String id;
  final String deviceId;
  final String serviceUuid;
  final String uuid;
  final String? primaryServiceUuid;
  final int instanceId;
  final bool canRead;
  final bool canWrite;
  final bool canWriteWithoutResponse;
  final bool canNotify;
  final bool canIndicate;
  final bool isNotifying;
  final List<String> descriptorUuids;
  final String label;
  final String? lastValueHex;

  bool get isWritable => canWrite || canWriteWithoutResponse;

  BleCharacteristicInfo copyWith({
    bool? isNotifying,
    String? lastValueHex,
  }) {
    return BleCharacteristicInfo(
      id: id,
      deviceId: deviceId,
      serviceUuid: serviceUuid,
      uuid: uuid,
      primaryServiceUuid: primaryServiceUuid,
      instanceId: instanceId,
      canRead: canRead,
      canWrite: canWrite,
      canWriteWithoutResponse: canWriteWithoutResponse,
      canNotify: canNotify,
      canIndicate: canIndicate,
      isNotifying: isNotifying ?? this.isNotifying,
      descriptorUuids: descriptorUuids,
      label: label,
      lastValueHex: lastValueHex ?? this.lastValueHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'uuid': uuid,
      'primaryServiceUuid': primaryServiceUuid,
      'instanceId': instanceId,
      'canRead': canRead,
      'canWrite': canWrite,
      'canWriteWithoutResponse': canWriteWithoutResponse,
      'canNotify': canNotify,
      'canIndicate': canIndicate,
      'isNotifying': isNotifying,
      'descriptorUuids': descriptorUuids,
      'label': label,
      'lastValueHex': lastValueHex,
    };
  }
}
