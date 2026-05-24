import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/ble_device_record.dart';

class SettingsRepository {
  static const _settingsKey = 'app_settings_v1';
  static const _historyKey = 'device_history_v1';

  AppSettings _current = AppSettings.defaults();
  final List<BleDeviceRecord> _history = <BleDeviceRecord>[];

  AppSettings get current => _current;
  List<BleDeviceRecord> get history => List.unmodifiable(_history);

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_settingsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _current = AppSettings.fromJson(decoded);
      } else if (decoded is Map) {
        _current = AppSettings.fromJson(decoded.map((key, value) => MapEntry(key.toString(), value)));
      }
    }
    final historyRaw = preferences.getString(_historyKey);
    _history
      ..clear()
      ..addAll(_decodeHistory(historyRaw));
    return _current;
  }

  Future<void> save(AppSettings settings) async {
    _current = settings;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveDeviceHistory(List<BleDeviceRecord> devices) async {
    _history
      ..clear()
      ..addAll(devices.take(20));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _historyKey,
      jsonEncode(_history.map((device) => device.toJson()).toList()),
    );
  }

  List<BleDeviceRecord> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => BleDeviceRecord.fromJson(item.map((key, value) => MapEntry(key.toString(), value))),
        )
        .toList();
  }
}
