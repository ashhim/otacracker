class BleUuidCatalog {
  const BleUuidCatalog._();

  static const Map<String, String> serviceLabels = {
    '00001800-0000-1000-8000-00805f9b34fb': 'Generic Access',
    '00001801-0000-1000-8000-00805f9b34fb': 'Generic Attribute',
    '0000180a-0000-1000-8000-00805f9b34fb': 'Device Information',
    '0000180f-0000-1000-8000-00805f9b34fb': 'Battery Service',
    '00001530-1212-efde-1523-785feabcd123': 'Nordic DFU',
    '0000fe59-0000-1000-8000-00805f9b34fb': 'Secure DFU',
    '0000fee7-0000-1000-8000-00805f9b34fb': 'Xiaomi Transport',
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e': 'Nordic UART',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455': 'Telink OTA',
    'a6ed0401-d344-460a-8075-b9e8ec90d71b': 'Goodix DFU',
    '0000d0ff-3c17-d293-8e48-14fe2e4da212': 'Realtek OTA',
    '0000ffd0-0000-1000-8000-00805f9b34fb': 'Vendor Data Transport',
    '0000ffb0-0000-1000-8000-00805f9b34fb': 'Vendor Resource Service',
    '0000fef5-0000-1000-8000-00805f9b34fb': 'Vendor OTA Control',
  };

  static const Map<String, String> characteristicLabels = {
    '00002a00-0000-1000-8000-00805f9b34fb': 'Device Name',
    '00002a19-0000-1000-8000-00805f9b34fb': 'Battery Level',
    '00002a24-0000-1000-8000-00805f9b34fb': 'Model Number',
    '00002a25-0000-1000-8000-00805f9b34fb': 'Serial Number',
    '00002a26-0000-1000-8000-00805f9b34fb': 'Firmware Revision',
    '00002a27-0000-1000-8000-00805f9b34fb': 'Hardware Revision',
    '00002a28-0000-1000-8000-00805f9b34fb': 'Software Revision',
    '00002a29-0000-1000-8000-00805f9b34fb': 'Manufacturer Name',
    '00001531-1212-efde-1523-785feabcd123': 'DFU Control Point',
    '00001532-1212-efde-1523-785feabcd123': 'DFU Packet',
    'a6ed0402-d344-460a-8075-b9e8ec90d71b': 'Goodix DFU Receive',
    'a6ed0403-d344-460a-8075-b9e8ec90d71b': 'Goodix DFU Notify',
    '0000d0ff-3c17-d293-8e48-14fe2e4da213': 'Realtek OTA Control',
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e': 'UART RX',
    '6e400003-b5a3-f393-e0a9-e50e24dcca9e': 'UART TX',
    '0000ffd1-0000-1000-8000-00805f9b34fb': 'Vendor Command RX',
    '0000ffd2-0000-1000-8000-00805f9b34fb': 'Vendor Command TX',
    '0000ffb1-0000-1000-8000-00805f9b34fb': 'Vendor Resource RX',
    '0000ffb2-0000-1000-8000-00805f9b34fb': 'Vendor Resource TX',
  };

  static const otaServiceKeywords = [
    'dfu',
    'ota',
    'firmware',
    'update',
    'resource',
    'transfer',
    'uart',
    'transport',
    'control',
    'resource',
    'fota',
    'rx',
    'tx',
    'goodix',
    'realtek',
    'nordic',
    'telink',
  ];

  static const watchKeywords = [
    't800',
    'ultra',
    'watch',
    'hw',
    'fit',
    'hiwatch',
    'pro',
    'wear',
    'wearable',
    'bracelet',
    'band',
    'fitpro',
    'goodix',
    'realtek',
    'clone',
  ];

  static String labelForService(String uuid) {
    return serviceLabels[uuid.toLowerCase()] ?? 'Unknown Service';
  }

  static String labelForCharacteristic(String uuid) {
    return characteristicLabels[uuid.toLowerCase()] ?? 'Unknown Characteristic';
  }

  static bool isWatchLikeName(String value) {
    final normalized = value.toLowerCase();
    return watchKeywords.any(normalized.contains);
  }

  static String composeCharacteristicId(String serviceUuid, String characteristicUuid, int instanceId) {
    return '$serviceUuid|$characteristicUuid|$instanceId';
  }
}
