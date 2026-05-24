import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';

import '../ble/ble_protocol_analyzer.dart';
import '../logs/log_service.dart';
import '../models/ble_characteristic_info.dart';
import '../models/ble_device_record.dart';
import '../models/ble_packet.dart';
import '../models/ble_service_info.dart';
import '../models/device_insights.dart';
import '../models/device_session.dart';
import '../repositories/ble_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/export_service.dart';
import '../services/permission_service.dart';

class BleController extends ChangeNotifier {
  BleController(
    this._permissionService,
    this._repository,
    this._analyzer,
    this._settingsRepository,
    this._logService,
    this._exportService,
    this._sessionRepository,
  );

  final PermissionService _permissionService;
  final BleRepository _repository;
  final BleProtocolAnalyzer _analyzer;
  final SettingsRepository _settingsRepository;
  final LogService _logService;
  final ExportService _exportService;
  final SessionRepository _sessionRepository;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _scanStateSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<BluetoothConnectionState>? _selectedConnectionSubscription;
  StreamSubscription<int>? _selectedMtuSubscription;

  bool _initialized = false;
  bool _permissionsGranted = false;
  bool _loading = false;
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  final Map<String, BleDeviceRecord> _devices = <String, BleDeviceRecord>{};
  List<BleServiceInfo> _services = const [];
  DeviceInsights _insights = DeviceInsights.empty();
  final Map<String, Map<String, List<int>>> _descriptorValues = <String, Map<String, List<int>>>{};
  String _scanFilter = '';
  String? _selectedDeviceId;
  String? _selectedCharacteristicId;
  String? _error;

  bool get initialized => _initialized;
  bool get permissionsGranted => _permissionsGranted;
  bool get loading => _loading;
  bool get isScanning => _isScanning;
  BluetoothAdapterState get adapterState => _adapterState;
  List<BleDeviceRecord> get allDevices => _sortedDevices(_devices.values.toList());
  List<BleServiceInfo> get services => _services;
  DeviceInsights get insights => _insights;
  String get scanFilter => _scanFilter;
  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedCharacteristicId => _selectedCharacteristicId;
  String? get error => _error;

  BleDeviceRecord? get selectedDevice => _selectedDeviceId == null ? null : _devices[_selectedDeviceId];

  BleCharacteristicInfo? get selectedCharacteristic {
    if (_selectedCharacteristicId == null) {
      return null;
    }
    return _services
        .expand((service) => service.characteristics)
        .firstWhereOrNull((characteristic) => characteristic.id == _selectedCharacteristicId);
  }

  List<BleDeviceRecord> get filteredDevices {
    if (_scanFilter.trim().isEmpty) {
      return allDevices;
    }
    final query = _scanFilter.toLowerCase();
    return allDevices
        .where(
          (device) =>
              device.displayName.toLowerCase().contains(query) ||
              device.id.toLowerCase().contains(query) ||
              device.serviceUuids.any((uuid) => uuid.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  List<BleCharacteristicInfo> get writableCharacteristics {
    return _services
        .expand((service) => service.characteristics)
        .where((characteristic) => characteristic.isWritable)
        .toList(growable: false);
  }

  List<BleCharacteristicInfo> get notifiableCharacteristics {
    return _services
        .expand((service) => service.characteristics)
        .where((characteristic) => characteristic.canNotify || characteristic.canIndicate)
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _permissionsGranted = await _permissionService.ensureBlePermissions();
    await _repository.initialize();
    _scanSubscription = _repository.scanResults.listen(_handleScanResults);
    _scanStateSubscription = _repository.scanningState.listen((value) {
      _isScanning = value;
      notifyListeners();
    });
    _adapterSubscription = _repository.adapterStates.listen((value) {
      _adapterState = value;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> startScan() async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      _permissionsGranted = await _permissionService.ensureBlePermissions();
      await _repository.ensureAdapterOn();
      await _repository.startScan();
      _logService.info('BLE scan started');
    } catch (error) {
      _error = error.toString();
      _logService.error('Failed to start scan: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await _repository.stopScan();
      await _settingsRepository.saveDeviceHistory(allDevices);
      _logService.info('BLE scan stopped');
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  void updateScanFilter(String value) {
    _scanFilter = value;
    notifyListeners();
  }

  Future<void> connectToDevice(BleDeviceRecord record) async {
    _error = null;
    _loading = true;
    _selectedDeviceId = record.id;
    notifyListeners();
    try {
      await _repository.connectToDevice(record.id, _settingsRepository.current);
      await _bindSelectedDevice(record.id);
      final updated = record.copyWith(isConnected: true, lastSeen: DateTime.now());
      _devices[record.id] = updated;
      await _settingsRepository.saveDeviceHistory(_sortedDevices(_devices.values.toList()));
      _logService.info('Connected to ${record.displayName}');
    } catch (error) {
      _error = error.toString();
      _logService.error('Failed to connect to ${record.displayName}: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> disconnectSelected() async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null) {
      return;
    }
    await _repository.disconnectDevice(deviceId);
    final selected = _devices[deviceId];
    if (selected != null) {
      _devices[deviceId] = selected.copyWith(isConnected: false);
    }
    _services = const [];
    _insights = DeviceInsights.empty();
    notifyListeners();
  }

  Future<void> refreshSelectedDevice() async {
    final deviceId = _selectedDeviceId;
    final record = selectedDevice;
    if (deviceId == null || record == null) {
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final services = await _repository.discoverServices(deviceId);
      _services = services;
      final rssi = await _repository.readRssi(deviceId).catchError((_) => record.rssi);
      final mtu = _repository.mtuOf(deviceId);
      _insights = await _buildInsights(record, services, mtu: mtu, rssi: rssi);
      _devices[deviceId] = record.copyWith(
        isConnected: true,
        rssi: rssi,
        serviceUuids: services.map((service) => service.uuid).toList(),
      );
      _logService.info('Refreshed GATT topology for ${record.displayName}');
    } catch (error) {
      _error = error.toString();
      _logService.error('Failed to refresh device: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCharacteristic(String characteristicId) async {
    _selectedCharacteristicId = characteristicId;
    notifyListeners();
  }

  Future<List<int>> readCharacteristic(BleCharacteristicInfo characteristic) async {
    final data = await _repository.readCharacteristic(characteristic.id);
    _logService.recordPacket(
      direction: BlePacketDirection.incoming,
      kind: BlePacketKind.read,
      deviceId: characteristic.deviceId,
      serviceUuid: characteristic.serviceUuid,
      characteristicUuid: characteristic.uuid,
      bytes: data,
      note: 'Read response',
    );
    _patchCharacteristic(characteristic.id, data);
    notifyListeners();
    return data;
  }

  Future<void> writeCharacteristic(
    BleCharacteristicInfo characteristic,
    List<int> bytes, {
    required bool withoutResponse,
    BlePacketKind kind = BlePacketKind.write,
  }) async {
    await _repository.writeCharacteristic(
      characteristic.id,
      bytes,
      withoutResponse: withoutResponse,
    );
    _logService.recordPacket(
      direction: BlePacketDirection.outgoing,
      kind: kind,
      deviceId: characteristic.deviceId,
      serviceUuid: characteristic.serviceUuid,
      characteristicUuid: characteristic.uuid,
      bytes: bytes,
      note: withoutResponse ? 'writeWithoutResponse' : 'writeWithResponse',
    );
    _patchCharacteristic(characteristic.id, bytes);
    notifyListeners();
  }

  Future<void> toggleNotify(BleCharacteristicInfo characteristic, bool enabled) async {
    await _repository.setNotify(
      characteristic.id,
      enabled,
      onValue: (bytes) {
        _logService.recordPacket(
          direction: BlePacketDirection.incoming,
          kind: characteristic.canIndicate ? BlePacketKind.indication : BlePacketKind.notify,
          deviceId: characteristic.deviceId,
          serviceUuid: characteristic.serviceUuid,
          characteristicUuid: characteristic.uuid,
          bytes: bytes,
          note: enabled ? 'Notification' : 'Notification disabled',
        );
        _patchCharacteristic(characteristic.id, bytes, isNotifying: enabled);
        notifyListeners();
      },
    );
    _patchCharacteristic(characteristic.id, const [], isNotifying: enabled, preserveLastValue: true);
    _logService.info('${enabled ? 'Enabled' : 'Disabled'} notifications for ${characteristic.uuid}');
    notifyListeners();
  }

  Future<void> armNotificationLogger() async {
    for (final characteristic in notifiableCharacteristics) {
      try {
        await toggleNotify(characteristic, true);
      } catch (error) {
        _logService.warning('Unable to subscribe ${characteristic.uuid}: $error');
      }
    }
  }

  Future<Map<String, List<int>>> readDescriptors(BleCharacteristicInfo characteristic) async {
    final descriptors = await _repository.readDescriptors(characteristic.id);
    _descriptorValues[characteristic.id] = descriptors;
    notifyListeners();
    return descriptors;
  }

  Map<String, List<int>> descriptorValuesFor(String characteristicId) {
    return _descriptorValues[characteristicId] ?? const {};
  }

  Future<int> optimizeMtu(int requested) async {
    final deviceId = _selectedDeviceId;
    if (deviceId == null) {
      return 23;
    }
    try {
      final mtu = await _repository.requestMtu(deviceId, requested);
      _insights = DeviceInsights(
        deviceId: _insights.deviceId,
        deviceName: _insights.deviceName,
        mtu: mtu,
        rssi: _insights.rssi,
        batteryLevel: _insights.batteryLevel,
        manufacturerName: _insights.manufacturerName,
        modelNumber: _insights.modelNumber,
        serialNumber: _insights.serialNumber,
        firmwareVersion: _insights.firmwareVersion,
        hardwareVersion: _insights.hardwareVersion,
        softwareVersion: _insights.softwareVersion,
        connectionIntervalLabel: _insights.connectionIntervalLabel,
        otaChannels: _insights.otaChannels,
        dfuServices: _insights.dfuServices,
        uartServices: _insights.uartServices,
        writableCharacteristics: _insights.writableCharacteristics,
        notifyCharacteristics: _insights.notifyCharacteristics,
        lastRefresh: DateTime.now(),
      );
      notifyListeners();
      return mtu;
    } catch (error) {
      _logService.warning('MTU request failed: $error');
      return _repository.mtuOf(deviceId);
    }
  }

  Future<String?> exportTopology() async {
    final record = selectedDevice;
    if (record == null || _services.isEmpty) {
      return null;
    }
    final topology = _analyzer.buildTopologyJson(record, _services);
    final path = await _exportService.exportTopology(topology, prefix: 'ble_topology');
    _logService.info('Topology exported to $path');
    return path;
  }

  Future<String?> saveCurrentSession({String notes = ''}) async {
    final record = selectedDevice;
    if (record == null) {
      return null;
    }
    final topology = _analyzer.buildTopologyJson(record, _services);
    final session = DeviceSession(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      device: record,
      topologyJson: topology,
      packets: _logService.packetsForDevice(record.id),
      notes: notes,
    );
    await _sessionRepository.save(session);
    final exportPath = await _exportService.exportSession(session);
    _logService.info('Session saved to $exportPath');
    return exportPath;
  }

  Future<void> replayPacket(BlePacket packet, {String? characteristicId}) async {
    final targetId = characteristicId ?? _selectedCharacteristicId;
    final characteristic = writableCharacteristics.firstWhereOrNull((value) => value.id == targetId);
    if (characteristic == null) {
      throw StateError('Select a writable characteristic before replaying packets.');
    }
    await writeCharacteristic(
      characteristic,
      packet.bytes,
      withoutResponse: _settingsRepository.current.useWriteWithoutResponse,
      kind: BlePacketKind.replay,
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanStateSubscription?.cancel();
    _adapterSubscription?.cancel();
    _selectedConnectionSubscription?.cancel();
    _selectedMtuSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bindSelectedDevice(String deviceId) async {
    await _selectedConnectionSubscription?.cancel();
    await _selectedMtuSubscription?.cancel();
    _selectedConnectionSubscription = _repository.connectionStream(deviceId).listen((state) async {
      final device = _devices[deviceId];
      if (device != null) {
        _devices[deviceId] = device.copyWith(isConnected: state == BluetoothConnectionState.connected);
      }
      if (state == BluetoothConnectionState.connected) {
        await refreshSelectedDevice();
      }
      notifyListeners();
    });
    _selectedMtuSubscription = _repository.mtuStream(deviceId).listen((_) {
      notifyListeners();
    });
  }

  Future<DeviceInsights> _buildInsights(
    BleDeviceRecord record,
    List<BleServiceInfo> services, {
    required int mtu,
    required int rssi,
  }) async {
    final batteryLevel = await _readBatteryLevel();
    final manufacturer = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a29-0000-1000-8000-00805f9b34fb',
    );
    final model = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a24-0000-1000-8000-00805f9b34fb',
    );
    final serial = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a25-0000-1000-8000-00805f9b34fb',
    );
    final firmware = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a26-0000-1000-8000-00805f9b34fb',
    );
    final hardware = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a27-0000-1000-8000-00805f9b34fb',
    );
    final software = await _readUtf8Characteristic(
      serviceUuid: '0000180a-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a28-0000-1000-8000-00805f9b34fb',
    );
    final otaChannels = _analyzer.detectOtaChannels(services);
    return DeviceInsights(
      deviceId: record.id,
      deviceName: record.displayName,
      mtu: mtu,
      rssi: rssi,
      batteryLevel: batteryLevel,
      manufacturerName: manufacturer,
      modelNumber: model,
      serialNumber: serial,
      firmwareVersion: firmware,
      hardwareVersion: hardware,
      softwareVersion: software,
      connectionIntervalLabel: 'Unavailable via public BLE API',
      otaChannels: otaChannels,
      dfuServices: _analyzer.detectDfuServices(services),
      uartServices: _analyzer.detectUartServices(services),
      writableCharacteristics: writableCharacteristics.map((value) => value.id).toList(),
      notifyCharacteristics: notifiableCharacteristics.map((value) => value.id).toList(),
      lastRefresh: DateTime.now(),
    );
  }

  Future<int?> _readBatteryLevel() async {
    final characteristic = _findCharacteristicByUuid(
      serviceUuid: '0000180f-0000-1000-8000-00805f9b34fb',
      characteristicUuid: '00002a19-0000-1000-8000-00805f9b34fb',
    );
    if (characteristic == null) {
      return null;
    }
    final data = await readCharacteristic(characteristic);
    return data.isEmpty ? null : data.first;
  }

  Future<String?> _readUtf8Characteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final characteristic = _findCharacteristicByUuid(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
    if (characteristic == null) {
      return null;
    }
    final data = await readCharacteristic(characteristic);
    if (data.isEmpty) {
      return null;
    }
    return String.fromCharCodes(data).replaceAll('\u0000', '').trim();
  }

  BleCharacteristicInfo? _findCharacteristicByUuid({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _services
        .where((service) => service.uuid == serviceUuid)
        .expand((service) => service.characteristics)
        .firstWhereOrNull((characteristic) => characteristic.uuid == characteristicUuid);
  }

  void _handleScanResults(List<ScanResult> results) {
    for (final result in results) {
      final id = result.device.remoteId.str;
      final manufacturerData = result.advertisementData.manufacturerData.map(
        (key, value) => MapEntry(
          key.toRadixString(16).padLeft(4, '0').toUpperCase(),
          value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
        ),
      );
      final record = BleDeviceRecord(
        id: id,
        advName: result.advertisementData.advName,
        platformName: result.device.platformName,
        rssi: result.rssi,
        connectable: result.advertisementData.connectable,
        lastSeen: result.timeStamp,
        manufacturerData: manufacturerData,
        serviceUuids: result.advertisementData.serviceUuids.map((uuid) => uuid.str.toLowerCase()).toList(),
        txPowerLevel: result.advertisementData.txPowerLevel,
        isConnected: _repository.connectionStateOf(id) == BluetoothConnectionState.connected,
        isWatchCandidate: false,
        advertisementCount: (_devices[id]?.advertisementCount ?? 0) + 1,
      );
      final enriched = record.copyWith(isWatchCandidate: _analyzer.isWatchCandidate(record));
      _devices[id] = enriched;
    }
    notifyListeners();
  }

  List<BleDeviceRecord> _sortedDevices(List<BleDeviceRecord> devices) {
    devices.sort((left, right) {
      if (left.isConnected != right.isConnected) {
        return right.isConnected ? 1 : -1;
      }
      if (left.isWatchCandidate != right.isWatchCandidate) {
        return right.isWatchCandidate ? 1 : -1;
      }
      return right.rssi.compareTo(left.rssi);
    });
    return devices;
  }

  void _patchCharacteristic(
    String characteristicId,
    List<int> bytes, {
    bool? isNotifying,
    bool preserveLastValue = false,
  }) {
    _services = _services
        .map(
          (service) => BleServiceInfo(
            deviceId: service.deviceId,
            uuid: service.uuid,
            isPrimary: service.isPrimary,
            label: service.label,
            characteristics: service.characteristics
                .map(
                  (characteristic) => characteristic.id == characteristicId
                      ? characteristic.copyWith(
                          isNotifying: isNotifying,
                          lastValueHex: preserveLastValue && bytes.isEmpty
                              ? characteristic.lastValueHex
                              : bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
                        )
                      : characteristic,
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }
}
