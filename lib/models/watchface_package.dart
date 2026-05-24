import 'dart:typed_data';

import 'watchface_asset.dart';

class WatchfacePackage {
  const WatchfacePackage({
    required this.name,
    required this.assets,
    required this.archiveBytes,
    required this.manifestJson,
  });

  final String name;
  final List<WatchfaceAsset> assets;
  final Uint8List archiveBytes;
  final String manifestJson;
}
