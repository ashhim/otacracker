import 'ble_characteristic_info.dart';

class BleServiceInfo {
  const BleServiceInfo({
    required this.deviceId,
    required this.uuid,
    required this.isPrimary,
    required this.label,
    required this.characteristics,
  });

  final String deviceId;
  final String uuid;
  final bool isPrimary;
  final String label;
  final List<BleCharacteristicInfo> characteristics;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'uuid': uuid,
      'isPrimary': isPrimary,
      'label': label,
      'characteristics': characteristics.map((value) => value.toJson()).toList(),
    };
  }
}
