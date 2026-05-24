import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/app_constants.dart';

class StorageService {
  Directory? _rootDirectory;

  Future<void> initialize() async {
    _rootDirectory ??= await getApplicationDocumentsDirectory();
    await _ensureSubDirectory(AppConstants.sessionsDirectory);
    await _ensureSubDirectory(AppConstants.exportsDirectory);
    await _ensureSubDirectory(AppConstants.logsDirectory);
    await _ensureSubDirectory(AppConstants.watchfaceDirectory);
  }

  Future<Directory> get root async {
    _rootDirectory ??= await getApplicationDocumentsDirectory();
    return _rootDirectory!;
  }

  Future<Directory> subDirectory(String name) async {
    await initialize();
    return _ensureSubDirectory(name);
  }

  Future<File> writeText(String relativePath, String content) async {
    final file = await _file(relativePath);
    await file.create(recursive: true);
    return file.writeAsString(content, flush: true);
  }

  Future<File> writeBytes(String relativePath, Uint8List content) async {
    final file = await _file(relativePath);
    await file.create(recursive: true);
    return file.writeAsBytes(content, flush: true);
  }

  Future<String?> readText(String relativePath) async {
    final file = await _file(relativePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  Future<Map<String, dynamic>?> readJson(String relativePath) async {
    final text = await readText(relativePath);
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<List<FileSystemEntity>> listFiles(String subDirectoryName) async {
    final directory = await subDirectory(subDirectoryName);
    if (!await directory.exists()) {
      return const [];
    }
    return directory.list().toList();
  }

  Future<File> _file(String relativePath) async {
    final rootDirectory = await root;
    return File('${rootDirectory.path}${Platform.pathSeparator}$relativePath');
  }

  Future<Directory> _ensureSubDirectory(String name) async {
    _rootDirectory ??= await getApplicationDocumentsDirectory();
    final rootDirectory = _rootDirectory!;
    final directory = Directory('${rootDirectory.path}${Platform.pathSeparator}$name');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
