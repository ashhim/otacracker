import 'dart:typed_data';

import '../utils/binary_utils.dart';

class FilePayload {
  const FilePayload({
    required this.name,
    required this.bytes,
    required this.path,
  });

  final String name;
  final Uint8List bytes;
  final String? path;

  int get sizeBytes => bytes.lengthInBytes;
  String get sha256 => BinaryUtils.sha256Hex(bytes);
}
