import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../logs/log_service.dart';
import '../models/app_settings.dart';
import '../models/file_payload.dart';
import '../models/ota_transfer_state.dart';
import '../ota/ota_transfer_engine.dart';
import '../providers/ble_controller.dart';
import '../services/file_service.dart';

class OtaController extends ChangeNotifier {
  OtaController(
    this._fileService,
    this._engine,
    this._logService,
  );

  final FileService _fileService;
  final OtaTransferEngine _engine;
  final LogService _logService;

  FilePayload? _payload;
  OtaTransferState _state = OtaTransferState.idle();
  String? _selectedChannelId;
  String? _selectedAckCharacteristicId;
  String? _error;

  FilePayload? get payload => _payload;
  OtaTransferState get state => _state;
  String? get selectedChannelId => _selectedChannelId;
  String? get selectedAckCharacteristicId => _selectedAckCharacteristicId;
  String? get error => _error;

  Future<void> pickFile() async {
    _error = null;
    notifyListeners();
    final selected = await _fileService.pickSingle(
      type: FileType.custom,
      allowedExtensions: const ['bin', 'zip', 'dat', 'res'],
    );
    if (selected != null) {
      _payload = selected;
      _state = OtaTransferState.idle();
      notifyListeners();
    }
  }

  void usePayload(String name, Uint8List bytes) {
    _payload = FilePayload(name: name, bytes: bytes, path: null);
    _state = OtaTransferState.idle();
    notifyListeners();
  }

  void selectChannel(String? characteristicId) {
    _selectedChannelId = characteristicId;
    notifyListeners();
  }

  void selectAckChannel(String? characteristicId) {
    _selectedAckCharacteristicId = characteristicId;
    notifyListeners();
  }

  Future<void> startUpload({
    required BleController bleController,
    required AppSettings settings,
  }) async {
    final currentPayload = _payload;
    final selectedDeviceId = bleController.selectedDeviceId;
    final txCharacteristicId = _selectedChannelId;
    if (currentPayload == null || selectedDeviceId == null || txCharacteristicId == null) {
      return;
    }
    _error = null;
    notifyListeners();

    final requestedMtu = await bleController.optimizeMtu(settings.requestedMtu);
    final resumeOffset = _state.status == OtaTransferStatus.failed || _state.status == OtaTransferStatus.cancelled
        ? _state.resumeOffset
        : 0;

    final nextState = await _engine.transfer(
      deviceId: selectedDeviceId,
      txCharacteristicId: txCharacteristicId,
      ackCharacteristicId: _selectedAckCharacteristicId,
      bytes: currentPayload.bytes,
      fileName: currentPayload.name,
      mtu: requestedMtu,
      preferredChunkSize: settings.chunkSize,
      delayMs: settings.packetDelayMs,
      maxRetries: settings.maxRetries,
      timeoutMs: 1400,
      withoutResponse: settings.useWriteWithoutResponse,
      requireAck: settings.requireAck,
      resumeOffset: resumeOffset,
      onProgress: (state) {
        _state = state;
        notifyListeners();
      },
    );
    _state = nextState;
    if (nextState.status == OtaTransferStatus.failed) {
      _error = nextState.error;
      _logService.error('OTA upload failed: ${nextState.error}');
    }
    notifyListeners();
  }

  void cancel() {
    _engine.cancel();
  }

  void clear() {
    _payload = null;
    _selectedChannelId = null;
    _selectedAckCharacteristicId = null;
    _state = OtaTransferState.idle();
    _error = null;
    notifyListeners();
  }
}
