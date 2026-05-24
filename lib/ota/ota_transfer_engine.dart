import 'dart:async';
import 'dart:typed_data';

import '../logs/log_service.dart';
import '../models/ble_packet.dart';
import '../models/ota_transfer_state.dart';
import '../repositories/ble_repository.dart';
import '../utils/crc_utils.dart';

class OtaTransferEngine {
  OtaTransferEngine(this._repository, this._logService);

  final BleRepository _repository;
  final LogService _logService;
  bool _cancelRequested = false;

  void cancel() {
    _cancelRequested = true;
  }

  Future<OtaTransferState> transfer({
    required String deviceId,
    required String txCharacteristicId,
    required String? ackCharacteristicId,
    required Uint8List bytes,
    required String fileName,
    required int mtu,
    required int preferredChunkSize,
    required int delayMs,
    required int maxRetries,
    required int timeoutMs,
    required bool withoutResponse,
    required bool requireAck,
    required int resumeOffset,
    required void Function(OtaTransferState state) onProgress,
  }) async {
    _cancelRequested = false;
    final startedAt = DateTime.now();
    if (bytes.isEmpty) {
      final failedState = OtaTransferState(
        status: OtaTransferStatus.failed,
        fileName: fileName,
        totalBytes: 0,
        sentBytes: 0,
        chunkSize: 0,
        mtu: mtu,
        retries: 0,
        bytesPerSecond: 0,
        startedAt: startedAt,
        lastUpdatedAt: startedAt,
        resumeOffset: resumeOffset,
        error: 'Selected OTA payload is empty.',
      );
      onProgress(failedState);
      return failedState;
    }
    if (requireAck && ackCharacteristicId == null) {
      final failedState = OtaTransferState(
        status: OtaTransferStatus.failed,
        fileName: fileName,
        totalBytes: bytes.lengthInBytes,
        sentBytes: resumeOffset,
        chunkSize: 0,
        mtu: mtu,
        retries: 0,
        bytesPerSecond: 0,
        startedAt: startedAt,
        lastUpdatedAt: startedAt,
        resumeOffset: resumeOffset,
        error: 'ACK mode is enabled, but no ACK characteristic was selected.',
      );
      onProgress(failedState);
      return failedState;
    }
    final maxChunkSize = _effectiveChunkSize(mtu, preferredChunkSize, withoutResponse);
    final minChunkSize = withoutResponse ? 20 : 16;
    var currentChunkSize = maxChunkSize;
    var sentBytes = resumeOffset;
    var retries = 0;
    var lastState = OtaTransferState(
      status: OtaTransferStatus.preparing,
      fileName: fileName,
      totalBytes: bytes.lengthInBytes,
      sentBytes: sentBytes,
      chunkSize: currentChunkSize,
      mtu: mtu,
      retries: 0,
      bytesPerSecond: 0,
      startedAt: startedAt,
      lastUpdatedAt: startedAt,
      resumeOffset: resumeOffset,
    );
    onProgress(lastState);
    _logService.info(
      'Starting OTA transfer for $fileName. CRC32=${CrcUtils.crc32(bytes).toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );
    if (requireAck && ackCharacteristicId != null) {
      await _repository.ensureNotificationsEnabled(ackCharacteristicId);
    }

    final txParts = _parseCharacteristicId(txCharacteristicId);
    final ackParts = ackCharacteristicId == null ? null : _parseCharacteristicId(ackCharacteristicId);
    final headerPreview = bytes.sublist(0, bytes.lengthInBytes < 32 ? bytes.lengthInBytes : 32);
    _logService.recordPacket(
      direction: BlePacketDirection.outgoing,
      kind: BlePacketKind.otaHeader,
      deviceId: deviceId,
      serviceUuid: txParts.$1,
      characteristicUuid: txParts.$2,
      bytes: headerPreview,
      note: 'OTA header preview',
    );
    final effectiveDelayMs = delayMs < 0 ? 0 : delayMs;

    for (var offset = resumeOffset; offset < bytes.lengthInBytes;) {
      if (_cancelRequested) {
        lastState = lastState.copyWith(
          status: OtaTransferStatus.cancelled,
          sentBytes: sentBytes,
          lastUpdatedAt: DateTime.now(),
          resumeOffset: sentBytes,
        );
        onProgress(lastState);
        return lastState;
      }

      final nextOffset =
          (offset + currentChunkSize > bytes.lengthInBytes) ? bytes.lengthInBytes : offset + currentChunkSize;
      final chunk = bytes.sublist(offset, nextOffset);
      try {
        await _repository.writeCharacteristic(
          txCharacteristicId,
          chunk,
          withoutResponse: withoutResponse,
        );
        _logService.recordPacket(
          direction: BlePacketDirection.outgoing,
          kind: BlePacketKind.write,
          deviceId: deviceId,
          serviceUuid: txParts.$1,
          characteristicUuid: txParts.$2,
          bytes: chunk,
          note: 'OTA chunk ${offset ~/ currentChunkSize + 1}',
        );
        if (requireAck && ackCharacteristicId != null) {
          final ack = await _repository.waitForNotification(
            ackCharacteristicId,
            timeout: Duration(milliseconds: timeoutMs),
          );
          _logService.recordPacket(
            direction: BlePacketDirection.incoming,
            kind: BlePacketKind.notify,
            deviceId: deviceId,
            serviceUuid: ackParts!.$1,
            characteristicUuid: ackParts.$2,
            bytes: ack,
            note: 'OTA ACK',
          );
        }
        sentBytes = nextOffset;
        offset = nextOffset;
        if (retries == 0 && currentChunkSize < maxChunkSize) {
          currentChunkSize = (currentChunkSize + 8).clamp(minChunkSize, maxChunkSize);
        }
        retries = 0;
        final elapsedSeconds = DateTime.now().difference(startedAt).inMilliseconds / 1000;
        lastState = lastState.copyWith(
          status: OtaTransferStatus.uploading,
          sentBytes: sentBytes,
          retries: retries,
          chunkSize: currentChunkSize,
          bytesPerSecond: elapsedSeconds <= 0 ? 0 : sentBytes / elapsedSeconds,
          lastUpdatedAt: DateTime.now(),
          resumeOffset: sentBytes,
        );
        onProgress(lastState);
        if (effectiveDelayMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: effectiveDelayMs));
        } else if (withoutResponse) {
          await Future<void>.delayed(const Duration(milliseconds: 6));
        }
      } catch (error) {
        retries++;
        currentChunkSize = (currentChunkSize ~/ 2).clamp(minChunkSize, maxChunkSize);
        if (retries > maxRetries) {
          lastState = lastState.copyWith(
            status: OtaTransferStatus.failed,
            sentBytes: sentBytes,
            retries: retries,
            chunkSize: currentChunkSize,
            error: error.toString(),
            lastUpdatedAt: DateTime.now(),
            resumeOffset: sentBytes,
          );
          onProgress(lastState);
          return lastState;
        }
        _logService.warning(
          'Retry $retries/$maxRetries for chunk at offset $offset with chunk size $currentChunkSize',
        );
        lastState = lastState.copyWith(
          status: OtaTransferStatus.uploading,
          retries: retries,
          chunkSize: currentChunkSize,
          lastUpdatedAt: DateTime.now(),
          resumeOffset: sentBytes,
        );
        onProgress(lastState);
        await Future<void>.delayed(
          Duration(milliseconds: effectiveDelayMs > 0 ? effectiveDelayMs * 2 : 20),
        );
      }
    }

    lastState = lastState.copyWith(
      status: OtaTransferStatus.completed,
      sentBytes: bytes.lengthInBytes,
      lastUpdatedAt: DateTime.now(),
      resumeOffset: bytes.lengthInBytes,
      bytesPerSecond: bytes.lengthInBytes /
          (DateTime.now().difference(startedAt).inMilliseconds <= 0
              ? 1
              : (DateTime.now().difference(startedAt).inMilliseconds / 1000)),
    );
    onProgress(lastState);
    return lastState;
  }

  (String, String) _parseCharacteristicId(String characteristicId) {
    final parts = characteristicId.split('|');
    final serviceUuid = parts.isNotEmpty ? parts[0] : '';
    final characteristicUuid = parts.length > 1 ? parts[1] : '';
    return (serviceUuid, characteristicUuid);
  }

  int _effectiveChunkSize(int mtu, int preferredChunkSize, bool withoutResponse) {
    final overhead = withoutResponse ? 3 : 5;
    final maxPayload = (mtu - overhead).clamp(20, 244);
    return preferredChunkSize.clamp(20, maxPayload);
  }
}
