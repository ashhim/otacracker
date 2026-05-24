import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../models/watchface_asset.dart';
import '../models/watchface_package.dart';
import '../services/file_service.dart';
import '../watchface/watchface_builder.dart';

class WatchFaceController extends ChangeNotifier {
  WatchFaceController(this._fileService, this._builder);

  final FileService _fileService;
  final WatchfaceBuilder _builder;

  bool _loading = false;
  String? _error;
  List<WatchfaceAsset> _assets = const [];
  WatchfacePackage? _package;

  bool get loading => _loading;
  String? get error => _error;
  List<WatchfaceAsset> get assets => _assets;
  WatchfacePackage? get package => _package;

  Future<void> pickAssets() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payloads = await _fileService.pickMultiple(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'bmp'],
      );
      final prepared = <WatchfaceAsset>[];
      for (final payload in payloads) {
        prepared.add(await _builder.prepareAsset(payload));
      }
      _assets = prepared;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> buildPackage(String name) async {
    if (_assets.isEmpty) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _package = await _builder.buildPackage(name, _assets);
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _assets = const [];
    _package = null;
    _error = null;
    notifyListeners();
  }
}
