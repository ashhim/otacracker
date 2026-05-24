class AppConstants {
  const AppConstants._();

  static const appName = 'OTACracker';
  static const appTagline = 'BLE smartwatch protocol and OTA workbench';

  static const sessionsDirectory = 'sessions';
  static const exportsDirectory = 'exports';
  static const logsDirectory = 'logs';
  static const watchfaceDirectory = 'watchfaces';

  static const splashDelayMs = 1400;
  static const packetBufferLimit = 2500;
  static const appLogBufferLimit = 1200;

  static const standardBatteryService = '0000180f-0000-1000-8000-00805f9b34fb';
  static const standardBatteryLevelCharacteristic = '00002a19-0000-1000-8000-00805f9b34fb';
  static const standardDeviceInfoService = '0000180a-0000-1000-8000-00805f9b34fb';
  static const standardGapService = '00001800-0000-1000-8000-00805f9b34fb';
  static const standardDeviceNameCharacteristic = '00002a00-0000-1000-8000-00805f9b34fb';
  static const standardManufacturerCharacteristic = '00002a29-0000-1000-8000-00805f9b34fb';
  static const standardModelCharacteristic = '00002a24-0000-1000-8000-00805f9b34fb';
  static const standardSerialCharacteristic = '00002a25-0000-1000-8000-00805f9b34fb';
  static const standardFirmwareCharacteristic = '00002a26-0000-1000-8000-00805f9b34fb';
  static const standardHardwareCharacteristic = '00002a27-0000-1000-8000-00805f9b34fb';
  static const standardSoftwareCharacteristic = '00002a28-0000-1000-8000-00805f9b34fb';
}
