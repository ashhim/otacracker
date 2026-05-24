import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analyzers/firmware_analyzer.dart';
import '../ble/ble_protocol_analyzer.dart';
import '../logs/log_service.dart';
import '../ota/ota_transfer_engine.dart';
import '../providers/ble_controller.dart';
import '../providers/firmware_analyzer_controller.dart';
import '../providers/ota_controller.dart';
import '../providers/session_controller.dart';
import '../providers/settings_controller.dart';
import '../providers/watch_face_controller.dart';
import '../repositories/ble_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../watchface/watchface_builder.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final fileServiceProvider = Provider<FileService>((ref) => const FileService());
final permissionServiceProvider = Provider<PermissionService>((ref) => const PermissionService());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());
final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) => SessionRepository(ref.read(storageServiceProvider)));
final exportServiceProvider =
    Provider<ExportService>((ref) => ExportService(ref.read(storageServiceProvider)));
final logServiceProvider = ChangeNotifierProvider<LogService>((ref) => LogService());
final bleAnalyzerProvider = Provider<BleProtocolAnalyzer>((ref) => const BleProtocolAnalyzer());
final firmwareAnalyzerProvider = Provider<FirmwareAnalyzer>((ref) => const FirmwareAnalyzer());
final watchfaceBuilderProvider = Provider<WatchfaceBuilder>((ref) => const WatchfaceBuilder());
final bleRepositoryProvider = Provider<BleRepository>((ref) {
  final repository = BleRepository(ref.read(logServiceProvider));
  ref.onDispose(repository.dispose);
  return repository;
});
final otaTransferEngineProvider = Provider<OtaTransferEngine>((ref) {
  return OtaTransferEngine(ref.read(bleRepositoryProvider), ref.read(logServiceProvider));
});

final settingsControllerProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController(ref.read(settingsRepositoryProvider));
});

final sessionControllerProvider = ChangeNotifierProvider<SessionController>((ref) {
  return SessionController(ref.read(sessionRepositoryProvider));
});

final firmwareAnalyzerControllerProvider = ChangeNotifierProvider<FirmwareAnalyzerController>((ref) {
  return FirmwareAnalyzerController(
    ref.read(fileServiceProvider),
    ref.read(firmwareAnalyzerProvider),
  );
});

final watchFaceControllerProvider = ChangeNotifierProvider<WatchFaceController>((ref) {
  return WatchFaceController(
    ref.read(fileServiceProvider),
    ref.read(watchfaceBuilderProvider),
  );
});

final bleControllerProvider = ChangeNotifierProvider<BleController>((ref) {
  return BleController(
    ref.read(permissionServiceProvider),
    ref.read(bleRepositoryProvider),
    ref.read(bleAnalyzerProvider),
    ref.read(settingsRepositoryProvider),
    ref.read(logServiceProvider),
    ref.read(exportServiceProvider),
    ref.read(sessionRepositoryProvider),
  );
});

final otaControllerProvider = ChangeNotifierProvider<OtaController>((ref) {
  return OtaController(
    ref.read(fileServiceProvider),
    ref.read(otaTransferEngineProvider),
    ref.read(logServiceProvider),
  );
});
