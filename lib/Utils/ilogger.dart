import 'dart:io';

import 'package:cloudotp/Utils/file_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class ILogger {
  static final List<Logger> _loggers = [
    Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        colors: true,
        printEmojis: false,
        dateTimeFormat: (time) =>
            DateFormat('yyyy-MM-dd HH:mm:ss:SSS').format(time),
      ),
      output: ConsoleOutput(),
    ),
    Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: null,
        lineLength: 300,
        colors: false,
        printEmojis: false,
        excludeBox: {
          Level.trace: true,
          Level.debug: true,
          Level.info: true,
          Level.warning: true,
          Level.error: false,
          Level.fatal: false,
        },
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

  static void warn(String message, [Object? error, StackTrace? stackTrace]) {
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
  int maxLogSize = 10 * 1024 * 1024; // 10MB
  int maxLogFileCount = 10; // 10 files
  RegExp logFilNameRegExp =
      RegExp(r'CloudOTP_(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2}-\d{2})\.log');

  @override
  Future<void> init() async {
    super.init();
    await checkLogs();
  }

  Future<void> checkLogs() async {
    Directory logDir = Directory(await FileUtil.getLogDir());
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }
    List<FileSystemEntity> files = logDir.listSync();
    files = files.whereType<File>().toList();
    files = files
        .where((element) =>
            logFilNameRegExp.hasMatch(element.path) &&
            element.path.endsWith('.log'))
        .toList();
    if (files.length > maxLogFileCount) {
      files.sort((a, b) => a.path.compareTo(b.path));
      for (int i = 0; i < files.length - maxLogFileCount; i++) {
        files[i].deleteSync();
      }
    }
    for (FileSystemEntity entity in files) {
      File file = entity as File;
      if (file.lengthSync() < maxLogSize) {
        this.file = file;
        return;
      }
    }
    String formattedDate =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    file = File('${logDir.path}/CloudOTP_$formattedDate.log');
  }

  @override
  Future<void> output(OutputEvent event) async {
    await checkLogs();
    for (var line in event.lines) {
      file!.writeAsStringSync('$line\n', mode: FileMode.append);
    }
    checkLogs();
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
