import 'package:flutter/foundation.dart';

import '../models/device_session.dart';
import '../repositories/session_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final SessionRepository _repository;
  bool _loading = false;
  List<DeviceSession> _sessions = const [];

  bool get loading => _loading;
  List<DeviceSession> get sessions => _sessions;

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    _sessions = await _repository.listSessions();
    _loading = false;
    notifyListeners();
  }
}
