class FirmwareMetadata {
  const FirmwareMetadata({
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    required this.crc32Hex,
    required this.signatures,
    required this.asciiStrings,
    required this.headerFields,
    required this.entropy,
    required this.entropyWindows,
    required this.possibleOtaFormat,
  });

  final String fileName;
  final int sizeBytes;
  final String sha256;
  final String crc32Hex;
  final List<String> signatures;
  final List<String> asciiStrings;
  final Map<String, String> headerFields;
  final double entropy;
  final List<double> entropyWindows;
  final String possibleOtaFormat;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'sha256': sha256,
      'crc32Hex': crc32Hex,
      'signatures': signatures,
      'asciiStrings': asciiStrings,
      'headerFields': headerFields,
      'entropy': entropy,
      'entropyWindows': entropyWindows,
      'possibleOtaFormat': possibleOtaFormat,
    };
  }
}
