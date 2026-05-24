import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class BinaryUtils {
  const BinaryUtils._();

  static String sha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  static double shannonEntropy(List<int> bytes) {
    if (bytes.isEmpty) {
      return 0;
    }
    final frequencies = List<int>.filled(256, 0);
    for (final byte in bytes) {
      frequencies[byte]++;
    }
    final length = bytes.length.toDouble();
    var entropy = 0.0;
    for (final frequency in frequencies) {
      if (frequency == 0) {
        continue;
      }
      final probability = frequency / length;
      entropy -= probability * (math.log(probability) / math.ln2);
    }
    return entropy;
  }

  static List<double> entropyWindows(
    Uint8List bytes, {
    int windowSize = 512,
    int sampleLimit = 48,
  }) {
    if (bytes.isEmpty) {
      return const [];
    }
    final windows = <double>[];
    final step = bytes.length <= windowSize ? windowSize : math.max(windowSize, bytes.length ~/ sampleLimit);
    for (var offset = 0; offset < bytes.length; offset += step) {
      final end = math.min(bytes.length, offset + windowSize);
      windows.add(shannonEntropy(bytes.sublist(offset, end)));
    }
    return windows;
  }

  static List<String> detectSignatures(Uint8List bytes) {
    final signatures = <String>[];
    final hexHead = bytes.take(16).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    if (hexHead.startsWith('89504e470d0a1a0a')) {
      signatures.add('PNG image');
    }
    if (hexHead.startsWith('ffd8ff')) {
      signatures.add('JPEG image');
    }
    if (hexHead.startsWith('424d')) {
      signatures.add('BMP image');
    }
    if (hexHead.startsWith('504b0304')) {
      signatures.add('ZIP container');
    }
    if (hexHead.startsWith('1f8b08')) {
      signatures.add('GZIP stream');
    }
    if (hexHead.startsWith('7f454c46')) {
      signatures.add('ELF binary');
    }
    if (hexHead.startsWith('4d5a')) {
      signatures.add('PE executable');
    }
    if (bytes.length >= 8) {
      final ascii = String.fromCharCodes(bytes.take(64).where((value) => value >= 32 && value <= 126));
      if (ascii.contains('NRF52')) {
        signatures.add('Nordic NRF hint');
      }
      if (ascii.toLowerCase().contains('watch')) {
        signatures.add('Watch resource hint');
      }
      if (ascii.toLowerCase().contains('dfu')) {
        signatures.add('DFU hint');
      }
    }
    return signatures.isEmpty ? const ['Unknown binary signature'] : signatures;
  }

  static List<String> extractAsciiStrings(Uint8List bytes, {int minimumLength = 5, int limit = 40}) {
    final result = <String>[];
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte >= 32 && byte <= 126) {
        buffer.writeCharCode(byte);
      } else {
        if (buffer.length >= minimumLength) {
          result.add(buffer.toString());
          if (result.length >= limit) {
            break;
          }
        }
        buffer.clear();
      }
    }
    if (buffer.length >= minimumLength && result.length < limit) {
      result.add(buffer.toString());
    }
    return result;
  }
}
