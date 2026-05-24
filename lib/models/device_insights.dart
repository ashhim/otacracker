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
    required this.phySupportLabel,
    required this.otaChannels,
    required this.dfuServices,
    required this.uartServices,
    required this.vendorHints,
    required this.serviceCount,
    required this.characteristicCount,
    required this.descriptorCount,
    required this.manufacturerData,
    required this.serviceDataKeys,
    required this.writableCharacteristics,
    required this.notifyCharacteristics,
    required this.advertisementSummary,
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
      phySupportLabel: 'Unknown',
      otaChannels: const [],
      dfuServices: const [],
      uartServices: const [],
      vendorHints: const [],
      serviceCount: 0,
      characteristicCount: 0,
      descriptorCount: 0,
      manufacturerData: const {},
      serviceDataKeys: const [],
      writableCharacteristics: const [],
      notifyCharacteristics: const [],
      advertisementSummary: '',
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
  final String phySupportLabel;
  final List<OtaChannel> otaChannels;
  final List<String> dfuServices;
  final List<String> uartServices;
  final List<String> vendorHints;
  final int serviceCount;
  final int characteristicCount;
  final int descriptorCount;
  final Map<String, String> manufacturerData;
  final List<String> serviceDataKeys;
  final List<String> writableCharacteristics;
  final List<String> notifyCharacteristics;
  final String advertisementSummary;
  final DateTime lastRefresh;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'mtu': mtu,
      'rssi': rssi,
      'batteryLevel': batteryLevel,
      'manufacturerName': manufacturerName,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'softwareVersion': softwareVersion,
      'connectionIntervalLabel': connectionIntervalLabel,
      'phySupportLabel': phySupportLabel,
      'otaChannels': otaChannels.map((value) => value.toJson()).toList(),
      'dfuServices': dfuServices,
      'uartServices': uartServices,
      'vendorHints': vendorHints,
      'serviceCount': serviceCount,
      'characteristicCount': characteristicCount,
      'descriptorCount': descriptorCount,
      'manufacturerData': manufacturerData,
      'serviceDataKeys': serviceDataKeys,
      'writableCharacteristics': writableCharacteristics,
      'notifyCharacteristics': notifyCharacteristics,
      'advertisementSummary': advertisementSummary,
      'lastRefresh': lastRefresh.toIso8601String(),
    };
  }
}
