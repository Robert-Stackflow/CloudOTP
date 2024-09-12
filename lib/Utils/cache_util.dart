import 'dart:io';

import 'package:cloudotp/Utils/ilogger.dart';
import 'package:path_provider/path_provider.dart';

class CacheUtil {
  static Future<String> loadCache() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      double value = await _getTotalSizeOfFilesInDir(tempDir);
      tempDir.list(followLinks: false, recursive: true).listen((file) {});
      return renderSize(value);
    } catch (e, t) {
      ILogger.error("CloudOTP", "Failed to load cache", e, t);
      return "0M";
    }
  }

  static Future<double> _getTotalSizeOfFilesInDir(
      final FileSystemEntity file) async {
    if (file is File) {
      int length = await file.length();
      return double.parse(length.toString());
    }
    if (file is Directory) {
      final List<FileSystemEntity> children = file.listSync();
      double total = 0;
      for (final FileSystemEntity child in children) {
        total += await _getTotalSizeOfFilesInDir(child);
      }
      return total;
    }
    return 0;
  }

  static Future<void> delDir(FileSystemEntity file) async {
    try {
      if (file is Directory) {
        final List<FileSystemEntity> children = file.listSync();
        for (final FileSystemEntity child in children) {
          await delDir(child);
        }
      }
      await file.delete();
    } catch (e, t) {
      ILogger.error("CloudOTP", "Failed to clear cache", e, t);
    }
  }

  static renderSize(
    double value, {
    int fractionDigits = 2,
  }) {
    List<String> unitArr = ['B', 'K', 'M', 'G'];
    int index = 0;
    while (value > 1024) {
      index++;
      value = value / 1024;
    }
    String size = value.toStringAsFixed(fractionDigits);
    if (size == '0.00') {
      return '0M';
    }
    return size + unitArr[index];
  }
}
