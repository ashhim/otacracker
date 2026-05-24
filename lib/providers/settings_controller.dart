import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  bool _loaded = false;
  AppSettings _settings = AppSettings.defaults();

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> initialize() async {
    if (_loaded) {
      return;
    }
    _settings = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _settings = next;
    await _repository.save(next);
    notifyListeners();
  }
}
