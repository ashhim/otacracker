import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/file_payload.dart';

class FileService {
  const FileService();

  Future<FilePayload?> pickSingle({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowMultiple: false,
      withData: true,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return _toPayload(result.files.single);
  }

  Future<List<FilePayload>> pickMultiple({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowMultiple: true,
      withData: true,
      allowedExtensions: allowedExtensions,
    );
    if (result == null) {
      return const [];
    }
    final payloads = <FilePayload>[];
    for (final file in result.files) {
      final payload = await _toPayload(file);
      if (payload != null) {
        payloads.add(payload);
      }
    }
    return payloads;
  }

  Future<FilePayload?> _toPayload(PlatformFile file) async {
    final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null) {
      return null;
    }
    return FilePayload(
      name: file.name,
      bytes: Uint8List.fromList(bytes),
      path: file.path,
    );
  }
}
