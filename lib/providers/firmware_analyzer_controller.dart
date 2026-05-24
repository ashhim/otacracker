import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../analyzers/firmware_analyzer.dart';
import '../models/file_payload.dart';
import '../models/firmware_metadata.dart';
import '../services/file_service.dart';

class FirmwareAnalyzerController extends ChangeNotifier {
  FirmwareAnalyzerController(this._fileService, this._analyzer);

  final FileService _fileService;
  final FirmwareAnalyzer _analyzer;

  FilePayload? _payload;
  FirmwareMetadata? _metadata;
  bool _loading = false;
  String? _error;

  FilePayload? get payload => _payload;
  FirmwareMetadata? get metadata => _metadata;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> pickAndAnalyze() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final selected = await _fileService.pickSingle(
        type: FileType.custom,
        allowedExtensions: const ['bin', 'fw', 'img', 'zip', 'res', 'dat'],
      );
      if (selected != null) {
        _payload = selected;
        _metadata = _analyzer.analyze(selected);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
