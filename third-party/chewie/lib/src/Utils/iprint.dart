import 'dart:io';

import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';

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
    bool useLogger = false,
  }) {
    String res = "";
    String text = "";
    String line =
        "====================================================================================================================================";
    if (showTopLine) res += "$line\n";
    text += "$ld$tag$rd $ld$status$rd ";
    for (var e in list.entries) {
      if (e.key.startsWith("splitter")) {
        res += text;
        text = "";
      } else {
        text += "$ld${e.key}：${e.value}$rd ";
      }
    }
    res += text;
    if (showBottomLine) res += "\n$line";
    if (useLogger) {
      ILogger.info(res);
    } else {
      debug(res);
    }
  }

  static f(i) async {
    _buffer.write(i.toString());
    String nowRecord = _buffer.toString();
    if (nowRecord.length > 50) {
      var path = await getTemporaryDirectory();
      var filePath = join(path.path, "${ResponsiveUtil.appName}.log");
      File file = File(filePath);
      file.writeAsStringSync(nowRecord, mode: FileMode.append);
      _buffer.clear();
    }
  }

  static Future<File> savedLogFile() async {
    var path = await getTemporaryDirectory();
    var filePath = join(path.path, "${ResponsiveUtil.appName}.log");
    File file = File(filePath);
    file.writeAsStringSync(_buffer.toString());
    _buffer.clear();
    return file;
  }
}
