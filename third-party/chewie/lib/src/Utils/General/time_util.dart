import 'package:intl/intl.dart';

class TimeUtil {
  static String timestampToDateString(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss:SSS");
    return dateFormat.format(date);
  }

  static String getFormattedDate(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd-HH-mm-ss").format(dateTime);
  }

  static String formatDuration(Duration duration) {
    var hours = duration.inHours;
    var minutes = duration.inMinutes % 60;
    var seconds = duration.inSeconds % 60;
    if (hours == 0) {
      return "${minutes < 10 ? "0$minutes" : minutes}:${seconds < 10 ? "0$seconds" : seconds}";
    } else {
      return "${hours < 10 ? "0$hours" : hours}:${minutes < 10 ? "0$minutes" : minutes}:${seconds < 10 ? "0$seconds" : seconds}";
    }
  }

  static String formatIntDuration(int duration) {
    var hours = duration ~/ 3600;
    var minutes = duration ~/ 60;
    var seconds = duration % 60;
    return formatDuration(
        Duration(hours: hours, minutes: minutes, seconds: seconds));
  }

  static DateTime? parseDateTime(String? dateString, {bool toLocal = true}) {
    if (dateString == null) return null;
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return toLocal ? parsedDate.toLocal() : parsedDate.toUtc();
    } catch (e) {
      final List<String> formats = [
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
      ];
      for (String format in formats) {
        try {
          DateFormat dateFormat = DateFormat(format);
          DateTime parsedDate = dateFormat.parse(dateString, true).toUtc();
          return toLocal ? parsedDate.toLocal() : parsedDate.toUtc();
        } catch (_) {}
      }
      try {
        return parseDateStringManually(dateString, toLocal: toLocal);
      } catch (_) {}
      return null;
    }
  }

  static DateTime? parseDateStringManually(
    String dateString, {
    bool toLocal = true,
  }) {
    final dateRegex = RegExp(
        r"(?<day>\w{3}), (?<dd>\d{2}) (?<month>\w{3}) (?<yyyy>\d{4}) (?<HH>\d{2}):(?<mm>\d{2}):(?<ss>\d{2}) (?<tz>[+\-]\d{4})");
    final match = dateRegex.firstMatch(dateString);
    if (match == null) {
      return null;
    }
    const monthMap = {
      "Jan": 1,
      "Feb": 2,
      "Mar": 3,
      "Apr": 4,
      "May": 5,
      "Jun": 6,
      "Jul": 7,
      "Aug": 8,
      "Sep": 9,
      "Oct": 10,
      "Nov": 11,
      "Dec": 12
    };
    final day = int.parse(match.namedGroup('dd')!);
    final month = monthMap[match.namedGroup('month')!]!;
    final year = int.parse(match.namedGroup('yyyy')!);
    final hour = int.parse(match.namedGroup('HH')!);
    final minute = int.parse(match.namedGroup('mm')!);
    final second = int.parse(match.namedGroup('ss')!);
    final tz = match.namedGroup('tz')!;

    final tzSign = tz[0] == '+' ? 1 : -1;
    final tzHour = int.parse(tz.substring(1, 3));
    final tzMinute = int.parse(tz.substring(3, 5));
    final tzOffset = Duration(hours: tzHour, minutes: tzMinute) * tzSign;

    final dateTime =
        DateTime.utc(year, month, day, hour, minute, second).subtract(tzOffset);
    return toLocal ? dateTime.toLocal() : dateTime;
  }

  static String formatAll(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd_HH-mm-ss");
    return dateFormat.format(date);
  }

  static String formatYearMonth(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy年MM月");
    return dateFormat.format(date);
  }

  static String formatTimestamp(
    int timestamp, [
    String format = "yyyy-MM-dd HH:mm:ss",
  ]) {
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    var dateFormat = DateFormat(format);
    return dateFormat.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  static String formatTimestampManual(int timestamp) {
    var now = DateTime.now();
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd");
    var dateFormat2 = DateFormat("MM-dd");
    var diff = now.difference(date);
    if (date.year != now.year) {
      return dateFormat.format(date);
    } else if (diff.inDays > 7) {
      return dateFormat2.format(date);
    } else if (diff.inDays > 0) {
      return "${diff.inDays}天前";
    }
    // else if (diff.inHours > 12) {
    //   return "${date.hour < 10 ? "0${date.hour}" : date.hour}:${date.minute < 10 ? "0${date.minute}" : date.minute}";
    // }
    else if (diff.inHours > 0) {
      return "${diff.inHours}小时前";
    } else {
      return "${diff.inMinutes}分钟前";
    }
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0 && date.day == now.day) {
      return "今天";
    } else if (difference.inDays <= 1 && now.day - date.day == 1) {
      return "昨天";
    } else if (difference.inDays <= 2 && now.day - date.day == 2) {
      return "前天";
    } else if (date.year == now.year) {
      String weekday = getWeekday(date.weekday);
      return "${DateFormat('M月dd日').format(date)} $weekday";
    } else {
      return DateFormat('yyyy年M月d日').format(date);
    }
  }

  static String getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "星期一";
      case DateTime.tuesday:
        return "星期二";
      case DateTime.wednesday:
        return "星期三";
      case DateTime.thursday:
        return "星期四";
      case DateTime.friday:
        return "星期五";
      case DateTime.saturday:
        return "星期六";
      case DateTime.sunday:
        return "星期日";
      default:
        return "";
    }
  }
}
