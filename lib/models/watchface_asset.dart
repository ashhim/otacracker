import 'dart:typed_data';

class WatchfaceAsset {
  const WatchfaceAsset({
    required this.name,
    required this.originalBytes,
    required this.optimizedBytes,
    required this.width,
    required this.height,
    required this.format,
  });

  final String name;
  final Uint8List originalBytes;
  final Uint8List optimizedBytes;
  final int width;
  final int height;
  final String format;
}
