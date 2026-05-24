import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';

import '../models/file_payload.dart';
import '../models/watchface_asset.dart';
import '../models/watchface_package.dart';
import '../utils/binary_utils.dart';

class WatchfaceBuilder {
  const WatchfaceBuilder();

  Future<WatchfaceAsset> prepareAsset(
    FilePayload payload, {
    int maxDimension = 320,
  }) async {
    final probeCodec = await ui.instantiateImageCodec(payload.bytes);
    final probeFrame = await probeCodec.getNextFrame();
    final source = probeFrame.image;
    final width = source.width;
    final height = source.height;
    final targetWidth = width >= height
        ? maxDimension
        : ((width / height) * maxDimension).round().clamp(1, maxDimension);
    final targetHeight = height > width
        ? maxDimension
        : ((height / width) * maxDimension).round().clamp(1, maxDimension);
    source.dispose();

    final codec = await ui.instantiateImageCodec(
      payload.bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode image ${payload.name}');
    }
    final optimizedBytes = byteData.buffer.asUint8List();
    return WatchfaceAsset(
      name: payload.name.replaceAll(RegExp(r'\s+'), '_'),
      originalBytes: payload.bytes,
      optimizedBytes: optimizedBytes,
      width: image.width,
      height: image.height,
      format: 'png',
    );
  }

  Future<WatchfacePackage> buildPackage(String name, List<WatchfaceAsset> assets) async {
    final archive = Archive();
    final manifest = {
      'name': name,
      'generatedAt': DateTime.now().toIso8601String(),
      'assetCount': assets.length,
      'assets': assets
          .map(
            (asset) => {
              'name': asset.name,
              'width': asset.width,
              'height': asset.height,
              'format': asset.format,
              'size': asset.optimizedBytes.lengthInBytes,
              'sha256': BinaryUtils.sha256Hex(asset.optimizedBytes),
            },
          )
          .toList(),
    };
    final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
    final manifestBytes = Uint8List.fromList(utf8.encode(manifestJson));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.lengthInBytes, manifestBytes));
    for (final asset in assets) {
      archive.addFile(
        ArchiveFile('assets/${asset.name}.png', asset.optimizedBytes.lengthInBytes, asset.optimizedBytes),
      );
    }
    final zipBytes = ZipEncoder().encodeBytes(archive);
    return WatchfacePackage(
      name: name,
      assets: assets,
      archiveBytes: zipBytes,
      manifestJson: manifestJson,
    );
  }
}
