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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class CloudLogger {
  static Function(String tag, String message, [dynamic e, dynamic t])? logTrace;
  static Function(String tag, String message, [dynamic e, dynamic t])? logDebug;
  static Function(String tag, String message, [dynamic e, dynamic t])? logInfo;
  static Function(String tag, String message, [dynamic e, dynamic t])?
      logWarning;
  static Function(String tag, String message, [dynamic e, dynamic t])? logError;
  static Function(String tag, String message, [dynamic e, dynamic t])? logFatal;

  static void trace(String tag, String message, [dynamic e, dynamic t]) {
    if (logTrace != null) {
      logTrace!(tag, message, e, t);
    } else {
      debugPrint('TRACE: $tag: $message $e $t');
    }
  }

  static void debug(String tag, String message, [dynamic e, dynamic t]) {
    if (logDebug != null) {
      logDebug!(tag, message, e, t);
    } else {
      debugPrint('DEBUG: $tag: $message $e $t');
    }
  }

  static void info(String tag, String message, [dynamic e, dynamic t]) {
    if (logInfo != null) {
      logInfo!(tag, message, e, t);
    } else {
      debugPrint('INFO: $tag: $message $e $t');
    }
  }

  static void infoResponse(String tag, String message, Response response) {
    if (logInfo != null) {
      logInfo!(tag, "$message [${response.statusCode}] [${response.body}]");
    } else {
      debugPrint(
          'INFO for response: $tag: $message [${response.statusCode}] [${response.body}]');
    }
  }

  static void errorResponse(String tag, String message, Response response) {
    if (logError != null) {
      logError!(tag, "$message [${response.statusCode}] [${response.body}]");
    } else {
      debugPrint(
          'ERROR for response: $tag: $message [${response.statusCode}] [${response.body}]');
    }
  }

  static void warning(String tag, String message, [dynamic e, dynamic t]) {
    if (logWarning != null) {
      logWarning!(tag, message, e, t);
    } else {
      debugPrint('WARNING: $tag: $message $e $t');
    }
  }

  static void error(String tag, String message, [dynamic e, dynamic t]) {
    if (logError != null) {
      logError!(tag, message, e, t);
    } else {
      debugPrint('ERROR: $tag: $message $e $t');
    }
  }

  static void fatal(String tag, String message, [dynamic e, dynamic t]) {
    if (logFatal != null) {
      logFatal!(tag, message, e, t);
    } else {
      debugPrint('FATAL: $tag: $message $e $t');
    }
  }
}
