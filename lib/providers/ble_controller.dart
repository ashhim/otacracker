import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';

import '../ble/ble_protocol_analyzer.dart';
import '../core/app_constants.dart';
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
import '../utils/hex_utils.dart';

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
  Timer? _scanRestartTimer;
  Timer? _scanWatchdogTimer;
  final Map<String, Timer> _reconnectTimers = <String, Timer>{};
  final Map<String, int> _reconnectAttempts = <String, int>{};
  final Map<String, DateTime> _advertisementLogWindows = <String, DateTime>{};
  final Set<String> _manualDisconnects = <String>{};
  final Set<String> _discoveryInProgress = <String>{};
  final Set<String> _announcedDevices = <String>{};

  bool _initialized = false;
  bool _permissionsGranted = false;
  bool _loading = false;
  bool _isScanning = false;
  bool _continuousScanRequested = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  DateTime? _lastScanActivityAt;
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
  int get descriptorValueCount => _descriptorValues.values.fold<int>(0, (sum, value) => sum + value.length);

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
              device.serviceUuids.any((uuid) => uuid.toLowerCase().contains(query)) ||
              device.serviceData.keys.any((uuid) => uuid.toLowerCase().contains(query)) ||
              device.manufacturerData.keys.any((vendor) => vendor.toLowerCase().contains(query)),
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
    for (final device in _settingsRepository.history) {
      _devices[device.id] = device;
    }
    await _repository.initialize();
    await _hydrateSystemDevices();
    _scanSubscription = _repository.scanResults.listen(_handleScanResults);
    _scanStateSubscription = _repository.scanningState.listen((value) {
      _isScanning = value;
      if (!_isScanning && _continuousScanRequested && _adapterState == BluetoothAdapterState.on) {
        _scheduleScanRestart();
      }
      notifyListeners();
    });
    _adapterSubscription = _repository.adapterStates.listen((value) {
      _adapterState = value;
      if (_continuousScanRequested && value == BluetoothAdapterState.on && !_isScanning) {
        _scheduleScanRestart(immediate: true);
      }
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> startScan() async {
    _error = null;
    _loading = true;
    _continuousScanRequested = true;
    _cancelScanTimers();
    notifyListeners();
    try {
      _permissionsGranted = await _permissionService.ensureBlePermissions();
      await _repository.ensureAdapterOn();
      await _hydrateSystemDevices();
      await _startAggressiveScanCycle(forceRestart: true);
      _startScanWatchdog();
      _logService.info('BLE aggressive discovery started');
    } catch (error) {
      _error = error.toString();
      _continuousScanRequested = false;
      _logService.error('Failed to start scan: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    _continuousScanRequested = false;
    _cancelScanTimers();
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
    _manualDisconnects.remove(record.id);
    _cancelReconnect(record.id);
    notifyListeners();
    try {
      await _repository.connectToDevice(record.id, _settingsRepository.current);
      await _bindSelectedDevice(record.id);
      _devices[record.id] = record.copyWith(isConnected: true, lastSeen: DateTime.now());
      await _runDeepDiscovery(record.id, reason: 'manual-connect', force: true);
      await _settingsRepository.saveDeviceHistory(_sortedDevices(_devices.values.toList()));
      _logService.info('Connected to ${record.displayName}');
    } catch (error) {
      _error = error.toString();
      _scheduleReconnect(record.id, record: record, reason: 'initial connect failure');
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
    _manualDisconnects.add(deviceId);
    _cancelReconnect(deviceId);
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
    if (deviceId == null) {
      return;
    }
    await _runDeepDiscovery(deviceId, reason: 'manual-refresh', force: true);
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

  Future<void> toggleNotify(
    BleCharacteristicInfo characteristic,
    bool enabled, {
    bool quiet = false,
    bool refreshUi = true,
  }) async {
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
          note: 'Notification',
        );
        _patchCharacteristic(characteristic.id, bytes, isNotifying: enabled);
        notifyListeners();
      },
    );
    _patchCharacteristic(characteristic.id, const [], isNotifying: enabled, preserveLastValue: true);
    if (!quiet) {
      _logService.info('${enabled ? 'Enabled' : 'Disabled'} notifications for ${characteristic.uuid}');
    }
    if (refreshUi) {
      notifyListeners();
    }
  }

  Future<void> armNotificationLogger() async {
    for (final characteristic in notifiableCharacteristics) {
      try {
        await toggleNotify(characteristic, true, quiet: true, refreshUi: false);
      } catch (error) {
        _logService.warning('Unable to subscribe ${characteristic.uuid}: $error');
      }
    }
    _logService.info('Notification logger armed across ${notifiableCharacteristics.length} endpoints');
    notifyListeners();
  }

  Future<Map<String, List<int>>> readDescriptors(
    BleCharacteristicInfo characteristic, {
    bool quiet = false,
    bool refreshUi = true,
  }) async {
    final descriptors = await _repository.readDescriptors(characteristic.id);
    _descriptorValues[characteristic.id] = descriptors;
    for (final entry in descriptors.entries) {
      _logService.recordPacket(
        direction: BlePacketDirection.incoming,
        kind: BlePacketKind.descriptor,
        deviceId: characteristic.deviceId,
        serviceUuid: characteristic.serviceUuid,
        characteristicUuid: '${characteristic.uuid}::${entry.key}',
        bytes: entry.value,
        note: 'Descriptor read',
      );
    }
    if (!quiet) {
      _logService.info('Read ${descriptors.length} descriptors for ${characteristic.uuid}');
    }
    if (refreshUi) {
      notifyListeners();
    }
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
      _insights = _copyInsights(mtu: mtu, lastRefresh: DateTime.now());
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

  Future<String?> exportSelectedDeviceProfile() async {
    final record = selectedDevice;
    if (record == null || _services.isEmpty) {
      return null;
    }
    final descriptorValues = <String, Map<String, List<int>>>{};
    for (final entry in _descriptorValues.entries) {
      final characteristic = _services
          .expand((service) => service.characteristics)
          .firstWhereOrNull((item) => item.id == entry.key);
      if (characteristic?.deviceId == record.id) {
        descriptorValues[entry.key] = entry.value;
      }
    }
    final path = await _exportService.exportDeviceProfile(
      device: record,
      insights: _insights,
      services: _services,
      descriptorValues: descriptorValues,
    );
    _logService.info('Device profile exported to $path');
    return path;
  }

  Future<String> exportScanResultsJson() async {
    final path = await _exportService.exportScanResultsJson(allDevices);
    _logService.info('Scan results exported to $path');
    return path;
  }

  Future<String> exportScanResultsText() async {
    final path = await _exportService.exportScanResultsText(allDevices);
    _logService.info('Scan results exported to $path');
    return path;
  }

  Future<String> exportScanResultsLog() async {
    final path = await _exportService.exportScanResultsLog(allDevices);
    _logService.info('Scan results log exported to $path');
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
    _cancelScanTimers();
    _scanSubscription?.cancel();
    _scanStateSubscription?.cancel();
    _adapterSubscription?.cancel();
    _selectedConnectionSubscription?.cancel();
    _selectedMtuSubscription?.cancel();
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }
    _reconnectTimers.clear();
    super.dispose();
  }

  Future<void> _hydrateSystemDevices() async {
    final devices = await _repository.loadSystemDevices();
    for (final device in devices) {
      final id = device.remoteId.str;
      _devices[id] = (_devices[id] ?? _placeholderRecord(device)).copyWith(
        platformName: device.platformName,
      );
    }
  }

  BleDeviceRecord _placeholderRecord(BluetoothDevice device) {
    return BleDeviceRecord(
      id: device.remoteId.str,
      advName: '',
      platformName: device.platformName,
      rssi: -100,
      connectable: true,
      lastSeen: DateTime.now(),
      manufacturerData: const {},
      serviceData: const {},
      serviceUuids: const [],
      txPowerLevel: null,
      appearance: null,
      isConnected: _repository.connectionStateOf(device.remoteId.str) == BluetoothConnectionState.connected,
      isWatchCandidate: _analyzer.isWatchCandidate(
        BleDeviceRecord(
          id: device.remoteId.str,
          advName: '',
          platformName: device.platformName,
          rssi: -100,
          connectable: true,
          lastSeen: DateTime.now(),
          manufacturerData: const {},
          serviceData: const {},
          serviceUuids: const [],
          txPowerLevel: null,
          appearance: null,
          isConnected: false,
          isWatchCandidate: false,
          advertisementCount: 0,
          rssiHistory: const [],
        ),
      ),
      advertisementCount: 0,
      rssiHistory: const [],
    );
  }

  Future<void> _startAggressiveScanCycle({bool forceRestart = false}) async {
    if (forceRestart && _isScanning) {
      try {
        await _repository.stopScan();
      } catch (_) {
        // ignore stop race
      }
    } else if (_isScanning) {
      return;
    }
    _lastScanActivityAt = DateTime.now();
    await _repository.startScan(
      timeout: const Duration(seconds: AppConstants.scanCycleSeconds),
    );
  }

  void _startScanWatchdog() {
    _scanWatchdogTimer?.cancel();
    _scanWatchdogTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_continuousScanRequested) {
        return;
      }
      final lastActivity = _lastScanActivityAt;
      if (lastActivity == null) {
        return;
      }
      final staleFor = DateTime.now().difference(lastActivity).inMilliseconds;
      if (staleFor > AppConstants.scanStallTimeoutMs) {
        _logService.warning('Scan watchdog restarting stalled scan cycle');
        _scheduleScanRestart(immediate: true);
      }
    });
  }

  void _scheduleScanRestart({bool immediate = false}) {
    if (!_continuousScanRequested) {
      return;
    }
    _scanRestartTimer?.cancel();
    _scanRestartTimer = Timer(
      Duration(milliseconds: immediate ? 50 : AppConstants.scanRestartDelayMs),
      () async {
        if (!_continuousScanRequested || _adapterState != BluetoothAdapterState.on) {
          return;
        }
        try {
          await _startAggressiveScanCycle(forceRestart: true);
        } catch (error) {
          _logService.warning('Scan restart failed: $error');
        }
      },
    );
  }

  void _cancelScanTimers() {
    _scanRestartTimer?.cancel();
    _scanWatchdogTimer?.cancel();
    _scanRestartTimer = null;
    _scanWatchdogTimer = null;
  }

  Future<void> _bindSelectedDevice(String deviceId) async {
    await _selectedConnectionSubscription?.cancel();
    await _selectedMtuSubscription?.cancel();
    _selectedConnectionSubscription = _repository.connectionStream(deviceId).listen((state) {
      final device = _devices[deviceId];
      if (device != null) {
        _devices[deviceId] = device.copyWith(isConnected: state == BluetoothConnectionState.connected);
      }
      if (state == BluetoothConnectionState.connected) {
        _manualDisconnects.remove(deviceId);
        _cancelReconnect(deviceId);
        unawaited(_runDeepDiscovery(deviceId, reason: 'connection-stream'));
      } else {
        if (_selectedDeviceId == deviceId) {
          _services = const [];
          _selectedCharacteristicId = null;
        }
        if (!_manualDisconnects.remove(deviceId)) {
          _scheduleReconnect(deviceId, record: _devices[deviceId], reason: 'disconnect');
        }
      }
      notifyListeners();
    });
    _selectedMtuSubscription = _repository.mtuStream(deviceId).listen((mtu) {
      if (_selectedDeviceId == deviceId) {
        _insights = _copyInsights(mtu: mtu, lastRefresh: DateTime.now());
        notifyListeners();
      }
    });
  }

  Future<void> _runDeepDiscovery(
    String deviceId, {
    required String reason,
    bool force = false,
  }) async {
    if (_discoveryInProgress.contains(deviceId) && !force) {
      return;
    }
    final record = _devices[deviceId];
    if (record == null) {
      return;
    }
    _discoveryInProgress.add(deviceId);
    if (_selectedDeviceId == deviceId) {
      _loading = true;
      notifyListeners();
    }
    try {
      await _repository.preferFastPhy(deviceId);
      try {
        await _repository.requestMtu(deviceId, _settingsRepository.current.requestedMtu);
      } catch (error) {
        _logService.debug('MTU expansion failed during deep discovery: $error');
      }
      final services = await _repository.discoverServices(deviceId);
      if (_selectedDeviceId == deviceId) {
        _services = services;
      }
      final rssi = await _repository.readRssi(deviceId).catchError((_) => record.rssi);
      await _warmDescriptorCache(services);
      await _autoSubscribeNotifications();
      final insights = await _buildInsights(
        record.copyWith(
          isConnected: true,
          rssi: rssi,
          serviceUuids: services.map((service) => service.uuid).toList(),
        ),
        services,
        mtu: _repository.mtuOf(deviceId),
        rssi: rssi,
        phySupportLabel: await _repository.getPhySupportLabel(),
      );
      _devices[deviceId] = record.copyWith(
        isConnected: true,
        rssi: rssi,
        serviceUuids: services.map((service) => service.uuid).toList(),
      );
      if (_selectedDeviceId == deviceId) {
        _insights = insights;
      }
      _logService.info('Deep BLE discovery complete for ${record.displayName} [$reason]');
    } catch (error) {
      _error = error.toString();
      _logService.error('Deep BLE discovery failed for ${record.displayName}: $error');
    } finally {
      _discoveryInProgress.remove(deviceId);
      if (_selectedDeviceId == deviceId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _warmDescriptorCache(List<BleServiceInfo> services) async {
    for (final characteristic in services.expand((service) => service.characteristics)) {
      if (characteristic.descriptorUuids.isEmpty) {
        continue;
      }
      try {
        await readDescriptors(characteristic, quiet: true, refreshUi: false);
      } catch (error) {
        _logService.debug('Descriptor sweep failed for ${characteristic.uuid}: $error');
      }
    }
    notifyListeners();
  }

  Future<void> _autoSubscribeNotifications() async {
    for (final characteristic in notifiableCharacteristics) {
      try {
        await toggleNotify(characteristic, true, quiet: true, refreshUi: false);
      } catch (error) {
        _logService.debug('Auto notify failed for ${characteristic.uuid}: $error');
      }
    }
    notifyListeners();
  }

  Future<DeviceInsights> _buildInsights(
    BleDeviceRecord record,
    List<BleServiceInfo> services, {
    required int mtu,
    required int rssi,
    required String phySupportLabel,
  }) async {
    final batteryLevel = await _readBatteryLevel();
    final manufacturer = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardManufacturerCharacteristic,
    );
    final model = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardModelCharacteristic,
    );
    final serial = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardSerialCharacteristic,
    );
    final firmware = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardFirmwareCharacteristic,
    );
    final hardware = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardHardwareCharacteristic,
    );
    final software = await _readUtf8Characteristic(
      serviceUuid: AppConstants.standardDeviceInfoService,
      characteristicUuid: AppConstants.standardSoftwareCharacteristic,
    );
    final descriptorCount = services.fold<int>(
      0,
      (sum, service) =>
          sum + service.characteristics.fold<int>(0, (inner, characteristic) => inner + characteristic.descriptorUuids.length),
    );
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
      phySupportLabel: phySupportLabel,
      otaChannels: _analyzer.detectOtaChannels(services),
      dfuServices: _analyzer.detectDfuServices(services),
      uartServices: _analyzer.detectUartServices(services),
      vendorHints: _analyzer.detectVendorHints(record, services: services),
      serviceCount: services.length,
      characteristicCount: services.fold<int>(0, (sum, service) => sum + service.characteristics.length),
      descriptorCount: descriptorCount,
      manufacturerData: record.manufacturerData,
      serviceDataKeys: record.serviceData.keys.toList()..sort(),
      writableCharacteristics: writableCharacteristics.map((value) => value.id).toList(),
      notifyCharacteristics: notifiableCharacteristics.map((value) => value.id).toList(),
      advertisementSummary: record.advertisementSummary,
      lastRefresh: DateTime.now(),
    );
  }

  Future<int?> _readBatteryLevel() async {
    final characteristic = _findCharacteristicByUuid(
      serviceUuid: AppConstants.standardBatteryService,
      characteristicUuid: AppConstants.standardBatteryLevelCharacteristic,
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
    _lastScanActivityAt = DateTime.now();
    for (final result in results) {
      final id = result.device.remoteId.str;
      final previous = _devices[id];
      final manufacturerData = result.advertisementData.manufacturerData.map(
        (key, value) => MapEntry(
          key.toRadixString(16).padLeft(4, '0').toUpperCase(),
          value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase(),
        ),
      );
      final serviceData = result.advertisementData.serviceData.map(
        (key, value) => MapEntry(
          key.str.toLowerCase(),
          HexUtils.bytesToHex(value),
        ),
      );
      final rssiHistory = <int>[
        ...(previous?.rssiHistory ?? const <int>[]),
        result.rssi,
      ];
      final trimmedHistory = rssiHistory.length > AppConstants.maxRssiSamples
          ? rssiHistory.sublist(rssiHistory.length - AppConstants.maxRssiSamples)
          : rssiHistory;
      final record = BleDeviceRecord(
        id: id,
        advName: result.advertisementData.advName,
        platformName: result.device.platformName,
        rssi: result.rssi,
        connectable: result.advertisementData.connectable,
        lastSeen: result.timeStamp,
        manufacturerData: manufacturerData,
        serviceData: serviceData,
        serviceUuids: result.advertisementData.serviceUuids.map((uuid) => uuid.str.toLowerCase()).toList(),
        txPowerLevel: result.advertisementData.txPowerLevel,
        appearance: result.advertisementData.appearance,
        isConnected: _repository.connectionStateOf(id) == BluetoothConnectionState.connected,
        isWatchCandidate: false,
        advertisementCount: (previous?.advertisementCount ?? 0) + 1,
        rssiHistory: trimmedHistory,
      );
      final enriched = record.copyWith(
        isWatchCandidate: _analyzer.isWatchCandidate(record) || _matchesCustomKeyword(record),
      );
      _devices[id] = enriched;
      if (_announcedDevices.add(id) && enriched.isWatchCandidate) {
        _logService.info('Detected smartwatch candidate ${enriched.displayName} [$id]');
      }
      _captureAdvertisement(enriched);
    }
    notifyListeners();
  }

  void _scheduleReconnect(
    String deviceId, {
    required String reason,
    BleDeviceRecord? record,
  }) {
    if (!_settingsRepository.current.autoReconnect) {
      return;
    }
    if (_reconnectTimers.containsKey(deviceId)) {
      return;
    }
    final attempt = (_reconnectAttempts[deviceId] ?? 0) + 1;
    _reconnectAttempts[deviceId] = attempt;
    final delayMs = math.min(
      AppConstants.reconnectInitialDelayMs * math.max(1, attempt),
      AppConstants.reconnectMaxDelayMs,
    ).toInt();
    _logService.warning('Scheduling reconnect for $deviceId in ${delayMs}ms [$reason]');
    _reconnectTimers[deviceId] = Timer(Duration(milliseconds: delayMs), () async {
      _reconnectTimers.remove(deviceId);
      final target = record ?? _devices[deviceId];
      if (target == null) {
        return;
      }
      try {
        await _repository.connectToDevice(deviceId, _settingsRepository.current);
        await _bindSelectedDevice(deviceId);
        await _runDeepDiscovery(deviceId, reason: 'reconnect', force: true);
        _reconnectAttempts.remove(deviceId);
        _logService.info('Reconnect successful for ${target.displayName}');
      } catch (error) {
        _logService.warning('Reconnect attempt failed for ${target.displayName}: $error');
        _scheduleReconnect(deviceId, reason: 'retry', record: target);
      }
    });
  }

  void _cancelReconnect(String deviceId) {
    _reconnectTimers.remove(deviceId)?.cancel();
    _reconnectAttempts.remove(deviceId);
  }

  bool _matchesCustomKeyword(BleDeviceRecord record) {
    final surface = [
      record.displayName,
      record.platformName,
      record.id,
      record.serviceUuids.join(' '),
      record.serviceData.keys.join(' '),
      record.manufacturerData.keys.join(' '),
      record.manufacturerData.values.join(' '),
    ].join(' ').toLowerCase();
    return _settingsRepository.current.scanKeywords.any(
      (keyword) => keyword.trim().isNotEmpty && surface.contains(keyword.toLowerCase()),
    );
  }

  void _captureAdvertisement(BleDeviceRecord record) {
    final lastCapturedAt = _advertisementLogWindows[record.id];
    final now = DateTime.now();
    if (lastCapturedAt != null && now.difference(lastCapturedAt).inMilliseconds < 1100) {
      return;
    }
    _advertisementLogWindows[record.id] = now;
    final payload = _advertisementBytes(record);
    if (payload.isEmpty) {
      return;
    }
    _logService.recordPacket(
      direction: BlePacketDirection.system,
      kind: BlePacketKind.advertisement,
      deviceId: record.id,
      serviceUuid: 'advertisement',
      characteristicUuid: 'payload',
      bytes: payload,
      note: 'RSSI ${record.rssi} | ${record.advertisementSummary}',
    );
  }

  List<int> _advertisementBytes(BleDeviceRecord record) {
    final payload = <int>[];
    for (final entry in record.manufacturerData.entries) {
      payload
        ..addAll(HexUtils.hexToBytes(entry.key))
        ..addAll(HexUtils.hexToBytes(entry.value));
    }
    for (final entry in record.serviceData.entries) {
      payload
        ..addAll(HexUtils.hexToBytes(entry.key.replaceAll('-', '')))
        ..addAll(HexUtils.hexToBytes(entry.value));
    }
    if (payload.isEmpty) {
      payload.addAll(record.displayName.codeUnits.take(24));
    }
    return payload;
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

  DeviceInsights _copyInsights({
    int? mtu,
    int? rssi,
    int? batteryLevel,
    String? phySupportLabel,
    DateTime? lastRefresh,
  }) {
    return DeviceInsights(
      deviceId: _insights.deviceId,
      deviceName: _insights.deviceName,
      mtu: mtu ?? _insights.mtu,
      rssi: rssi ?? _insights.rssi,
      batteryLevel: batteryLevel ?? _insights.batteryLevel,
      manufacturerName: _insights.manufacturerName,
      modelNumber: _insights.modelNumber,
      serialNumber: _insights.serialNumber,
      firmwareVersion: _insights.firmwareVersion,
      hardwareVersion: _insights.hardwareVersion,
      softwareVersion: _insights.softwareVersion,
      connectionIntervalLabel: _insights.connectionIntervalLabel,
      phySupportLabel: phySupportLabel ?? _insights.phySupportLabel,
      otaChannels: _insights.otaChannels,
      dfuServices: _insights.dfuServices,
      uartServices: _insights.uartServices,
      vendorHints: _insights.vendorHints,
      serviceCount: _insights.serviceCount,
      characteristicCount: _insights.characteristicCount,
      descriptorCount: _insights.descriptorCount,
      manufacturerData: _insights.manufacturerData,
      serviceDataKeys: _insights.serviceDataKeys,
      writableCharacteristics: _insights.writableCharacteristics,
      notifyCharacteristics: _insights.notifyCharacteristics,
      advertisementSummary: _insights.advertisementSummary,
      lastRefresh: lastRefresh ?? _insights.lastRefresh,
    );
  }
}
