import 'package:intl/intl.dart';

class FormatUtils {
  const FormatUtils._();

  static final DateFormat _timestamp = DateFormat('HH:mm:ss.SSS');
  static final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmmss');

  static String time(DateTime value) => _timestamp.format(value);
  static String fileStamp(DateTime value) => _fileStamp.format(value);

  static String bytes(num value) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = value.toDouble();
    var index = 0;
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(size < 10 && index > 0 ? 2 : 1)} ${suffixes[index]}';
  }

  static String speed(double bytesPerSecond) => '${bytes(bytesPerSecond)}/s';

  static String percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
}
