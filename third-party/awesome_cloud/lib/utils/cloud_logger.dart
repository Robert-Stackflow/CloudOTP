/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class CloudLogger {
  static const int _maxLogValueLength = 4096;

  static Function(String tag, String message, [dynamic e, dynamic t])? logTrace;
  static Function(String tag, String message, [dynamic e, dynamic t])? logDebug;
  static Function(String tag, String message, [dynamic e, dynamic t])? logInfo;
  static Function(String tag, String message, [dynamic e, dynamic t])?
      logWarning;
  static Function(String tag, String message, [dynamic e, dynamic t])? logError;
  static Function(String tag, String message, [dynamic e, dynamic t])? logFatal;

  static String redactForLogging(String value) {
    var redacted = value;
    final jsonSecret = RegExp(
      r'''("(?:access[_-]?token|refresh[_-]?token|id[_-]?token|authorization|password|secret|client[_-]?secret|code)"\s*:\s*")[^"]*(")''',
      caseSensitive: false,
    );
    final parameterSecret = RegExp(
      r'((?:access[_-]?token|refresh[_-]?token|id[_-]?token|authorization|password|secret|client[_-]?secret|code)\s*[=:]\s*)[^&\s,}\]]+',
      caseSensitive: false,
    );
    final bearerToken = RegExp(
      r'(Bearer\s+)[A-Za-z0-9._~+\-/=]+',
      caseSensitive: false,
    );
    final basicCredentials = RegExp(
      r'(Basic\s+)[A-Za-z0-9+/=]+',
      caseSensitive: false,
    );

    redacted = redacted.replaceAllMapped(
      jsonSecret,
      (match) => '${match.group(1)}[REDACTED]${match.group(2)}',
    );
    redacted = redacted.replaceAllMapped(
      bearerToken,
      (match) => '${match.group(1)}[REDACTED]',
    );
    redacted = redacted.replaceAllMapped(
      basicCredentials,
      (match) => '${match.group(1)}[REDACTED]',
    );
    redacted = redacted.replaceAllMapped(
      parameterSecret,
      (match) => '${match.group(1)}[REDACTED]',
    );

    if (redacted.length > _maxLogValueLength) {
      redacted = '${redacted.substring(0, _maxLogValueLength)}...[TRUNCATED]';
    }
    return redacted;
  }

  static String _safeMessage(String message) => redactForLogging(message);

  static Object? _safeError(dynamic error) =>
      error == null ? null : redactForLogging(error.toString());

  static void trace(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logTrace != null) {
      logTrace!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [TRACE] : $safeMessage $safeError $t');
    }
  }

  static void debug(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logDebug != null) {
      logDebug!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [DEBUG] : $safeMessage $safeError $t');
    }
  }

  static void info(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logInfo != null) {
      logInfo!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [INFO] : $safeMessage $safeError $t');
    }
  }

  static void infoResponse(String tag, String message, Response response) {
    if (logInfo != null) {
      logInfo!(tag, "$message [${response.statusCode}]");
    } else {
      debugPrint('[$tag] [INFO RESPONSE] : $message [${response.statusCode}]');
    }
  }

  static void errorResponse(String tag, String message, Response response) {
    final safeMessage = _safeMessage(message);
    final summary =
        '$safeMessage [${response.statusCode}] [body omitted: ${response.bodyBytes.length} bytes]';
    if (logError != null) {
      logError!(tag, summary);
    } else {
      debugPrint('[$tag] [ERROR RESPONSE] : $summary');
    }
  }

  static void warning(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logWarning != null) {
      logWarning!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [WARNING] : $safeMessage $safeError $t');
    }
  }

  static void error(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logError != null) {
      logError!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [ERROR] : $safeMessage $safeError $t');
    }
  }

  static void fatal(String tag, String message, [dynamic e, dynamic t]) {
    final safeMessage = _safeMessage(message);
    final safeError = _safeError(e);
    if (logFatal != null) {
      logFatal!(tag, safeMessage, safeError, t);
    } else {
      debugPrint('[$tag] [FATAL] : $safeMessage $safeError $t');
    }
  }
}
