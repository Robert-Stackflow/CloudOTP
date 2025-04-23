import 'dart:convert';

import 'package:html/parser.dart';
import 'package:uuid/uuid.dart';

extension StringExtension on String? {
  bool get nullOrEmpty => this == null || this!.isEmpty;

  bool get notNullOrEmpty => !nullOrEmpty;
}

class StringUtil {
  static String generateUid() {
    return const Uuid().v4();
  }

  static bool isUid(String uid) {
    return RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
        .hasMatch(uid);
  }

  static String extractTextFromHtml(String html) {
    var document = parse(html);
    return document.body?.text ?? "";
  }

  static List<String> extractImagesFromHtml(String html) {
    var document = parse(html);
    var images = document.getElementsByTagName("img");
    return images.map((e) => e.attributes["src"] ?? "").toList();
  }

  static String replaceLineBreak(String str) {
    return str.replaceAll(RegExp(r"\r\n"), "<br/>");
  }

  static String limitString(String str, {int limit = 30}) {
    return str.length > limit ? str.substring(0, limit) : str;
  }

  static String clearBlank(String str, {bool keepOne = true}) {
    return str.trim().replaceAll(RegExp(r"\s+"), keepOne ? " " : "");
  }

  static String formatCount(int count) {
    if (count < 10000) {
      return count.toString();
    } else {
      return "${(count / 10000).toStringAsFixed(1)}万";
    }
  }

  static Map<String, dynamic> parseJson(String jsonStr) {
    return jsonDecode(jsonStr);
  }

  static List<dynamic> parseJsonList(String jsonStr) {
    return jsonDecode(jsonStr);
  }
}
