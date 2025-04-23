import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';

class NumberUtil {
  static int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  static String intToHex(int value) {
    return value.toRadixString(16);
  }

  static int parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      try {
        return int.parse(value);
      } catch (e, t) {
        ILogger.error("Failed to parse int $value", e, t);
        return 0;
      }
    } else {
      return 0;
    }
  }

  static Map formatCountToMap(int count) {
    if (count < 10000) {
      return {"count": count.toString()};
    } else {
      return {
        "count": (count / 10000).toStringAsFixed(1),
        "scale": ChewieS.current.tenThousand
      };
    }
  }
}
