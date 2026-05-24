import '../models/file_payload.dart';
import '../models/firmware_metadata.dart';
import '../utils/binary_utils.dart';
import '../utils/crc_utils.dart';
import '../utils/hex_utils.dart';

class FirmwareAnalyzer {
  const FirmwareAnalyzer();

  FirmwareMetadata analyze(FilePayload payload) {
    final bytes = payload.bytes;
    final headerFields = <String, String>{
      'File Name': payload.name,
      'Size': payload.sizeBytes.toString(),
      'SHA-256': payload.sha256,
      'CRC32': CrcUtils.crc32(bytes).toRadixString(16).padLeft(8, '0').toUpperCase(),
      'First 16 Bytes': HexUtils.bytesToHex(bytes.take(16).toList(), spaced: true),
    };

    final signatures = BinaryUtils.detectSignatures(bytes);
    final otaFormat = _inferOtaFormat(signatures, payload.name.toLowerCase());

    return FirmwareMetadata(
      fileName: payload.name,
      sizeBytes: payload.sizeBytes,
      sha256: payload.sha256,
      crc32Hex: headerFields['CRC32']!,
      signatures: signatures,
      asciiStrings: BinaryUtils.extractAsciiStrings(bytes),
      headerFields: headerFields,
      entropy: BinaryUtils.shannonEntropy(bytes),
      entropyWindows: BinaryUtils.entropyWindows(bytes),
      possibleOtaFormat: otaFormat,
    );
  }

  String _inferOtaFormat(List<String> signatures, String lowerName) {
    if (lowerName.endsWith('.bin')) {
      return 'Raw firmware/resource BIN';
    }
    if (lowerName.endsWith('.zip')) {
      return 'Zipped multi-part OTA package';
    }
    if (signatures.any((value) => value.contains('Nordic'))) {
      return 'Nordic-style distribution artifact';
    }
    if (signatures.any((value) => value.contains('ZIP'))) {
      return 'Containerized OTA bundle';
    }
    return 'Unknown vendor OTA format';
  }
}
