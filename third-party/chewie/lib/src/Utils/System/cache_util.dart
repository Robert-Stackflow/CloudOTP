import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CacheUtil {
  static Future<String> loadCache() async {
    Directory tempDir = await getTemporaryDirectory();
    double value = await _getTotalSizeOfFilesInDir(tempDir);
    tempDir.list(followLinks: false, recursive: true).listen((file) {});
    return renderSize(value);
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
    if (file is Directory) {
      final List<FileSystemEntity> children = file.listSync();
      for (final FileSystemEntity child in children) {
        await delDir(child);
      }
    }
    await file.delete();
  }

  static String renderSize(
    double value, {
    int fractionDigits = 2,
  }) {
    final List<String> unitArr = ['B', 'K', 'M', 'G', 'T', 'P', 'E'];
    int index = 0;

    while (value >= 1024 && index < unitArr.length - 1) {
      value /= 1024;
      index++;
    }

    final size = value.toStringAsFixed(fractionDigits);

    if (double.tryParse(size) == 0) {
      return '0${unitArr[0]}';
    }

    return '$size${unitArr[index]}';
  }
}
