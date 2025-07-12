import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class ILogger {
  static final List<Logger> _loggers = [
    Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 10,
        colors: true,
        printEmojis: false,
        dateTimeFormat: (time) =>
            DateFormat('yyyy-MM-dd HH:mm:ss:SSS').format(time),
      ),
      output: ConsoleOutput(),
    ),
    Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: null,
        lineLength: 300,
        colors: false,
        printEmojis: false,
        noBoxingByDefault: true,
        dateTimeFormat: (time) =>
            DateFormat('yyyy-MM-dd HH:mm:ss:SSS').format(time),
      ),
      output: FileOutput(),
    ),
  ];

  static void log(Level level, String message,
      [Object? error, StackTrace? stackTrace]) {
    for (var logger in _loggers) {
      switch (level) {
        case Level.error:
          logger.e(
            message,
            error: error,
            stackTrace: stackTrace,
          );
          break;
        case Level.warning:
          logger.w(
            message,
            error: error,
            stackTrace: stackTrace,
          );

          break;
        case Level.debug:
          logger.d(
            message,
            error: error,
            stackTrace: stackTrace,
          );
          break;
        case Level.info:
          logger.i(
            message,
            error: error,
            stackTrace: stackTrace,
          );

          break;
        case Level.trace:
          logger.t(
            message,
            error: error,
            stackTrace: stackTrace,
          );

          break;
        case Level.fatal:
          logger.f(
            message,
            error: error,
            stackTrace: stackTrace,
          );
          break;
        default:
          break;
      }
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.error, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.warning, message, error, stackTrace);
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.info, message, error, stackTrace);
  }

  static void trace(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.trace, message, error, stackTrace);
  }

  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    log(Level.fatal, message, error, stackTrace);
  }
}

class FileOutput extends LogOutput {
  File? file;
  static int maxLogSize = 100 * 1024 * 1024; // 100MB
  static int maxLogFileCount = 10; // 10 files
  static RegExp logFilNameRegExp = RegExp(
      '${ResponsiveUtil.appName}_(\\d{4}-\\d{2}-\\d{2})_(\\d{2}-\\d{2}-\\d{2})\\.log');
  static RegExp errorLogFilNameRegExp = RegExp(r'error\.log');

  @override
  Future<void> init() async {
    super.init();
    file = await getLogFile();
  }

  static Future<bool> haveLogs() async {
    List<File> logs = await getLogs();
    return logs.isNotEmpty;
  }

  static Future<List<File>> getLogs() async {
    Directory logDir = Directory(await FileUtil.getLogDir());
    if (!logDir.existsSync()) {
      return [];
    }
    List<FileSystemEntity> files = logDir.listSync();
    files = files.whereType<File>().toList();
    files = files
        .where((element) =>
            (logFilNameRegExp.hasMatch(element.path) ||
                errorLogFilNameRegExp.hasMatch(element.path)) &&
            element.path.endsWith('.log'))
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files as List<File>;
  }

  static Future<Uint8List?> getArchiveData() async {
    if (!(await haveLogs())) return null;
    List<File> logs = await getLogs();
    List<int>? ints;
    ints = await compute((deviceDescription) async {
      Archive archive = Archive();
      for (File file in logs) {
        if (file.existsSync()) {
          archive.addFile(ArchiveFile(
              FileUtil.getFileNameWithExtension(file.path),
              file.lengthSync(),
              file.readAsBytesSync()));
        }
      }
      archive.addFile(ArchiveFile(
          'info.txt', deviceDescription.length, deviceDescription.codeUnits));
      ZipEncoder encoder = ZipEncoder();
      return encoder.encode(archive);
    }, ResponsiveUtil.deviceDescription);
    return ints != null ? Uint8List.fromList(ints) : null;
  }

  static Future<void> clearLogs() async {
    List<File> logs = await getLogs();
    for (File file in logs) {
      if (file.existsSync()) file.deleteSync();
    }
  }

  static Future<double> getLogsSize() async {
    List<File> logs = await getLogs();
    double size = 0;
    for (File file in logs) {
      if (file.existsSync()) size += file.lengthSync();
    }
    return size;
  }

  static Future<File> getLogFile() async {
    Directory logDir = Directory(await FileUtil.getLogDir());
    List<File> logs = await getLogs();
    if (logs.length > maxLogFileCount) {
      for (int i = 0; i < logs.length - maxLogFileCount; i++) {
        logs[i].deleteSync();
      }
    }
    for (File file in logs) {
      if (file.lengthSync() < maxLogSize) {
        return file;
      }
    }
    String formattedDate =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    return File('${logDir.path}/${ResponsiveUtil.appName}_$formattedDate.log');
  }

  @override
  Future<void> output(OutputEvent event) async {
    file = await getLogFile();
    String content = "";
    for (var line in event.lines) {
      content += "$line\n";
    }
    file!.writeAsString(content, mode: FileMode.append);
    file = await getLogFile();
  }
}

class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      debugPrint(line);
    }
  }
}
