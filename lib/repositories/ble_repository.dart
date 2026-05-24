import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/ble_uuid_catalog.dart';
import '../logs/log_service.dart';
import '../models/app_settings.dart';
import '../models/ble_characteristic_info.dart';
import '../models/ble_service_info.dart';

class BleRepository {
  BleRepository(this._logService);

  final LogService _logService;

  final Map<String, BluetoothDevice> _devices = <String, BluetoothDevice>{};
  final Map<String, Map<String, BluetoothCharacteristic>> _characteristics = <String, Map<String, BluetoothCharacteristic>>{};
  final Map<String, Map<String, BluetoothDescriptor>> _descriptors = <String, Map<String, BluetoothDescriptor>>{};
  final Map<String, StreamSubscription<List<int>>> _notifySubscriptions = <String, StreamSubscription<List<int>>>{};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionSubscriptions =
      <String, StreamSubscription<BluetoothConnectionState>>{};
  final Map<String, StreamSubscription<int>> _mtuSubscriptions = <String, StreamSubscription<int>>{};
  final Map<String, String> _notifyOwners = <String, String>{};
  final Map<String, BluetoothConnectionState> _connectionStateCache = <String, BluetoothConnectionState>{};
  final Map<String, int> _mtuCache = <String, int>{};
  final Map<String, int> _rssiCache = <String, int>{};

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  final StreamController<BluetoothAdapterState> _adapterStateController =
      StreamController<BluetoothAdapterState>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<String>? _bleLogSubscription;
  bool _initialized = false;

  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  Stream<bool> get scanningState => _isScanningController.stream;
  Stream<BluetoothAdapterState> get adapterStates => _adapterStateController.stream;

  BluetoothConnectionState connectionStateOf(String deviceId) {
    return _connectionStateCache[deviceId] ?? BluetoothConnectionState.disconnected;
  }

  int mtuOf(String deviceId) => _mtuCache[deviceId] ?? 23;
  int? rssiOf(String deviceId) => _rssiCache[deviceId];
  Stream<BluetoothConnectionState> connectionStream(String deviceId) => _requireDevice(deviceId).connectionState;
  Stream<int> mtuStream(String deviceId) => _requireDevice(deviceId).mtu;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    FlutterBluePlus.setOperationQueueMode(OperationQueueMode.perDevice);
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _scanResultsController.add,
      onError: (Object error, StackTrace stackTrace) {
        _logService.error('Scan stream error: $error');
      },
    );
    _isScanningSubscription = FlutterBluePlus.isScanning.listen(_isScanningController.add);
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(_adapterStateController.add);
    _bleLogSubscription = FlutterBluePlus.logs.listen((message) {
      _logService.debug(message);
    });
  }

  Future<bool> isSupported() => FlutterBluePlus.isSupported;

  Future<void> ensureAdapterOn() async {
    if (Platform.isAndroid && FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      continuousUpdates: true,
      continuousDivisor: 1,
      removeIfGone: const Duration(seconds: 10),
      androidScanMode: AndroidScanMode.lowLatency,
      androidCheckLocationServices: true,
    );
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<void> connectToDevice(String deviceId, AppSettings settings) async {
    final device = _devices[deviceId] ?? BluetoothDevice.fromId(deviceId);
    _devices[deviceId] = device;

    await _connectionSubscriptions[deviceId]?.cancel();
    await _mtuSubscriptions[deviceId]?.cancel();

    final connectionSubscription = device.connectionState.listen((state) async {
      _connectionStateCache[deviceId] = state;
      if (state == BluetoothConnectionState.disconnected) {
        await _teardownDevice(deviceId, keepDevice: true);
      }
    });
    device.cancelWhenDisconnected(connectionSubscription, delayed: true, next: true);
    _connectionSubscriptions[deviceId] = connectionSubscription;

    final mtuSubscription = device.mtu.listen((mtu) {
      _mtuCache[deviceId] = mtu;
    });
    device.cancelWhenDisconnected(mtuSubscription, next: true);
    _mtuSubscriptions[deviceId] = mtuSubscription;

    await device.connect(
      license: settings.useCommercialLicense ? License.commercial : License.free,
      autoConnect: settings.autoReconnect,
      mtu: settings.autoReconnect ? null : settings.requestedMtu,
    );
  }

  Future<void> disconnectDevice(String deviceId) async {
    final device = _devices[deviceId];
    if (device == null) {
      return;
    }
    if (device.isConnected) {
      await device.disconnect();
    }
    await _teardownDevice(deviceId, keepDevice: true);
  }

  Future<List<BleServiceInfo>> discoverServices(String deviceId) async {
    final device = _requireDevice(deviceId);
    final services = await device.discoverServices();
    final characteristicMap = <String, BluetoothCharacteristic>{};
    final descriptorMap = <String, BluetoothDescriptor>{};
    final serviceModels = <BleServiceInfo>[];
    for (final service in services) {
      final characteristicModels = <BleCharacteristicInfo>[];
      for (final characteristic in service.characteristics) {
        final charId = BleUuidCatalog.composeCharacteristicId(
          service.uuid.str.toLowerCase(),
          characteristic.uuid.str.toLowerCase(),
          characteristic.instanceId,
        );
        characteristicMap[charId] = characteristic;
        for (final descriptor in characteristic.descriptors) {
          descriptorMap['$charId|${descriptor.uuid.str.toLowerCase()}|${descriptor.instanceId}'] = descriptor;
        }
        characteristicModels.add(
          BleCharacteristicInfo(
            id: charId,
            deviceId: deviceId,
            serviceUuid: service.uuid.str.toLowerCase(),
            uuid: characteristic.uuid.str.toLowerCase(),
            primaryServiceUuid: characteristic.primaryServiceUuid?.str.toLowerCase(),
            instanceId: characteristic.instanceId,
            canRead: characteristic.properties.read,
            canWrite: characteristic.properties.write,
            canWriteWithoutResponse: characteristic.properties.writeWithoutResponse,
            canNotify: characteristic.properties.notify,
            canIndicate: characteristic.properties.indicate,
            isNotifying: characteristic.isNotifying,
            descriptorUuids: characteristic.descriptors.map((descriptor) => descriptor.uuid.str.toLowerCase()).toList(),
            label: BleUuidCatalog.labelForCharacteristic(characteristic.uuid.str.toLowerCase()),
            lastValueHex: characteristic.lastValue.isEmpty
                ? null
                : characteristic.lastValue.map((value) => value.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
          ),
        );
      }
      serviceModels.add(
        BleServiceInfo(
          deviceId: deviceId,
          uuid: service.uuid.str.toLowerCase(),
          isPrimary: service.isPrimary,
          label: BleUuidCatalog.labelForService(service.uuid.str.toLowerCase()),
          characteristics: characteristicModels,
        ),
      );
    }
    _characteristics[deviceId] = characteristicMap;
    _descriptors[deviceId] = descriptorMap;
    return serviceModels;
  }

  Future<int> requestMtu(String deviceId, int requestedMtu) async {
    final device = _requireDevice(deviceId);
    final mtu = await device.requestMtu(requestedMtu);
    _mtuCache[deviceId] = mtu;
    return mtu;
  }

  Future<int> readRssi(String deviceId) async {
    final device = _requireDevice(deviceId);
    final rssi = await device.readRssi();
    _rssiCache[deviceId] = rssi;
    return rssi;
  }

  Future<List<int>> readCharacteristic(String characteristicId) async {
    final characteristic = _requireCharacteristic(characteristicId);
    return characteristic.read();
  }

  Future<void> writeCharacteristic(
    String characteristicId,
    List<int> bytes, {
    required bool withoutResponse,
  }) async {
    final characteristic = _requireCharacteristic(characteristicId);
    await characteristic.write(bytes, withoutResponse: withoutResponse);
  }

  Future<void> setNotify(
    String characteristicId,
    bool enabled, {
    required void Function(List<int> bytes) onValue,
  }) async {
    final characteristic = _requireCharacteristic(characteristicId);
    await _notifySubscriptions[characteristicId]?.cancel();
    _notifySubscriptions.remove(characteristicId);
    if (!enabled) {
      await characteristic.setNotifyValue(false);
      return;
    }
    await characteristic.setNotifyValue(true);
    final subscription = characteristic.onValueReceived.listen(onValue);
    characteristic.device.cancelWhenDisconnected(subscription, next: true);
    _notifySubscriptions[characteristicId] = subscription;
    _notifyOwners[characteristicId] = characteristic.remoteId.str;
  }

  Future<Map<String, List<int>>> readDescriptors(String characteristicId) async {
    final results = <String, List<int>>{};
    final descriptors = _descriptors.entries
        .expand((entry) => entry.value.entries)
        .where((entry) => entry.key.startsWith('$characteristicId|'))
        .map((entry) => entry.value);
    for (final descriptor in descriptors) {
      final data = await descriptor.read();
      results[descriptor.uuid.str.toLowerCase()] = data;
    }
    return results;
  }

  Future<void> ensureNotificationsEnabled(String characteristicId) async {
    final characteristic = _requireCharacteristic(characteristicId);
    if (!characteristic.isNotifying) {
      await characteristic.setNotifyValue(true);
    }
  }

  Future<List<int>> waitForNotification(String characteristicId, {required Duration timeout}) async {
    final characteristic = _requireCharacteristic(characteristicId);
    if (!characteristic.isNotifying) {
      await characteristic.setNotifyValue(true);
    }
    return characteristic.onValueReceived.first.timeout(timeout);
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _isScanningSubscription?.cancel();
    await _adapterStateSubscription?.cancel();
    await _bleLogSubscription?.cancel();
    for (final subscription in _notifySubscriptions.values) {
      await subscription.cancel();
    }
    for (final subscription in _connectionSubscriptions.values) {
      await subscription.cancel();
    }
    for (final subscription in _mtuSubscriptions.values) {
      await subscription.cancel();
    }
    await _scanResultsController.close();
    await _isScanningController.close();
    await _adapterStateController.close();
  }

  BluetoothDevice _requireDevice(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) {
      throw StateError('Unknown BLE device: $deviceId');
    }
    return device;
  }

  BluetoothCharacteristic _requireCharacteristic(String characteristicId) {
    for (final deviceMap in _characteristics.values) {
      final characteristic = deviceMap[characteristicId];
      if (characteristic != null) {
        return characteristic;
      }
    }
    throw StateError('Unknown characteristic: $characteristicId');
  }

  Future<void> _teardownDevice(String deviceId, {required bool keepDevice}) async {
    final keys = _notifyOwners.entries
        .where((entry) => entry.value == deviceId)
        .map((entry) => entry.key)
        .toList();
    for (final key in keys) {
      await _notifySubscriptions.remove(key)?.cancel();
      _notifyOwners.remove(key);
    }
    _characteristics.remove(deviceId);
    _descriptors.remove(deviceId);
    _mtuCache.remove(deviceId);
    if (!keepDevice) {
      _devices.remove(deviceId);
      _connectionStateCache.remove(deviceId);
    }
  }
}
