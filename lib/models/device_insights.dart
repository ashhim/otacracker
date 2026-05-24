import 'ota_channel.dart';

class DeviceInsights {
  const DeviceInsights({
    required this.deviceId,
    required this.deviceName,
    required this.mtu,
    required this.rssi,
    required this.batteryLevel,
    required this.manufacturerName,
    required this.modelNumber,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.softwareVersion,
    required this.connectionIntervalLabel,
    required this.otaChannels,
    required this.dfuServices,
    required this.uartServices,
    required this.writableCharacteristics,
    required this.notifyCharacteristics,
    required this.lastRefresh,
  });

  factory DeviceInsights.empty() {
    return DeviceInsights(
      deviceId: '',
      deviceName: 'No device selected',
      mtu: 23,
      rssi: null,
      batteryLevel: null,
      manufacturerName: null,
      modelNumber: null,
      serialNumber: null,
      firmwareVersion: null,
      hardwareVersion: null,
      softwareVersion: null,
      connectionIntervalLabel: 'Unavailable via public BLE API',
      otaChannels: const [],
      dfuServices: const [],
      uartServices: const [],
      writableCharacteristics: const [],
      notifyCharacteristics: const [],
      lastRefresh: DateTime.now(),
    );
  }

  final String deviceId;
  final String deviceName;
  final int mtu;
  final int? rssi;
  final int? batteryLevel;
  final String? manufacturerName;
  final String? modelNumber;
  final String? serialNumber;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? softwareVersion;
  final String connectionIntervalLabel;
  final List<OtaChannel> otaChannels;
  final List<String> dfuServices;
  final List<String> uartServices;
  final List<String> writableCharacteristics;
  final List<String> notifyCharacteristics;
  final DateTime lastRefresh;
}
