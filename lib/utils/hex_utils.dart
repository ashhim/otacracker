import 'dart:typed_data';

import 'package:convert/convert.dart';

class HexUtils {
  const HexUtils._();

  static String bytesToHex(List<int> bytes, {bool spaced = false}) {
    final encoded = hex.encode(bytes);
    if (!spaced) {
      return encoded.toUpperCase();
    }
    final buffer = StringBuffer();
    for (var index = 0; index < encoded.length; index += 2) {
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(encoded.substring(index, index + 2).toUpperCase());
    }
    return buffer.toString();
  }

  static Uint8List hexToBytes(String input) {
    final normalized = input.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (normalized.isEmpty) {
      return Uint8List(0);
    }
    final padded = normalized.length.isOdd ? '0$normalized' : normalized;
    return Uint8List.fromList(hex.decode(padded));
  }

  static String bytesToAscii(List<int> bytes) {
    return bytes
        .map(
          (value) => value >= 32 && value <= 126 ? String.fromCharCode(value) : '.',
        )
        .join();
  }

  static Uint8List asciiToBytes(String input) {
    return Uint8List.fromList(input.codeUnits);
  }

  static String prettyMultiline(List<int> bytes, {int bytesPerRow = 16}) {
    final buffer = StringBuffer();
    for (var index = 0; index < bytes.length; index += bytesPerRow) {
      final row = bytes.sublist(
        index,
        index + bytesPerRow > bytes.length ? bytes.length : index + bytesPerRow,
      );
      final hexPart = bytesToHex(row, spaced: true).padRight(bytesPerRow * 3 - 1);
      final asciiPart = bytesToAscii(row);
      buffer.writeln('${index.toRadixString(16).padLeft(4, '0').toUpperCase()}  $hexPart  $asciiPart');
    }
    return buffer.toString().trimRight();
  }
}
