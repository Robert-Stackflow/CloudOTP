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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class IPrint {
  static final _buffer = StringBuffer();

  static void debug(Object? text) {
    if (kDebugMode) {
      print(text);
    }
  }

  static void debugTime(Object? text) {
    if (kDebugMode) {
      print("【${DateTime.now().toString()}】：$text");
    }
  }

  static void format({
    required String tag,
    required String status,
    required Map<String, Object?> list,
    String ld = "【",
    String rd = "】",
    bool showTopLine = true,
    bool showBottomLine = true,
  }) {
    String text = "";
    String line =
        "====================================================================================================================================";
    if (showTopLine) debug("$line\n");
    text += "$ld$tag$rd $ld$status$rd ";
    for (var e in list.entries) {
      if (e.key.startsWith("splitter")) {
        debug(text);
        text = "";
      } else {
        text += "$ld${e.key}：${e.value}$rd ";
      }
    }
    debug(text);
    if (showBottomLine) debug("\n$line");
  }

  static f(i) async {
    _buffer.write(i.toString());
    String nowRecord = _buffer.toString();
    if (nowRecord.length > 50) {
      var path = await getTemporaryDirectory();
      var filePath = join(path.path, "cloudotp.log");
      File file = File(filePath);
      file.writeAsStringSync(nowRecord, mode: FileMode.append);
      _buffer.clear();
    }
  }

  static Future<File> savedLogFile() async {
    var path = await getTemporaryDirectory();
    var filePath = join(path.path, "cloudotp.log");
    File file = File(filePath);
    file.writeAsStringSync(_buffer.toString());
    _buffer.clear();
    return file;
  }
}
