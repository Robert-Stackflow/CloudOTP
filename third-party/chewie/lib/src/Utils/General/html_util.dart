import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class HtmlUtil {
  static String detectLanguage(String code) {
    if (RegExp(r'\bvoid\s+main\s*\(\)').hasMatch(code) ||
        // RegExp(r"import\s+['\"]dart").hasMatch(code) ||
        RegExp(r'@override').hasMatch(code) ||
        RegExp(r'final\s+\w+').hasMatch(code)) {
      return 'Dart';
    } else if (RegExp(r'\bpackage\s+\w+').hasMatch(code) ||
        // RegExp(r'\bimport\s+["\']\w+["\']').hasMatch(code) ||
        RegExp(r'\bfunc\s+\w+\s*\(').hasMatch(code) ||
        RegExp(r'fmt\.Println\s*\(').hasMatch(code)) {
      return 'Go';
    } else if (RegExp(r'\bdef\s+\w+\s*\(').hasMatch(code) ||
        RegExp(r'\bprint\s*\(').hasMatch(code) ||
        RegExp(r'import\s+\w+').hasMatch(code) ||
        RegExp(r'#[^\n]*').hasMatch(code)) {
      return 'Python';
    } else if (RegExp(r'console\.log\s*\(').hasMatch(code) ||
        RegExp(r'function\s+\w+\s*\(').hasMatch(code) ||
        RegExp(r'const\s+\w+\s*=').hasMatch(code) ||
        RegExp(r'let\s+\w+\s*=').hasMatch(code) ||
        RegExp(r'//[^\n]*').hasMatch(code)) {
      return 'JavaScript';
    } else if (RegExp(r'public\s+class\s+\w+').hasMatch(code) ||
        RegExp(r'System\.out\.println\s*\(').hasMatch(code) ||
        RegExp(r'public\s+(static\s+)?void\s+main\s*\(').hasMatch(code) ||
        RegExp(r'import\s+java\.').hasMatch(code)) {
      return 'Java';
    } else if (RegExp(r'#include\s+<[^>]+>').hasMatch(code) ||
        RegExp(r'\bint\s+main\s*\(').hasMatch(code) ||
        RegExp(r'printf\s*\(').hasMatch(code) ||
        RegExp(r'//[^\n]*').hasMatch(code) ||
        RegExp(r'/\*[\s\S]*?\*/').hasMatch(code)) {
      return 'C/C++';
    } else if (RegExp(r'<\?php').hasMatch(code) ||
        // RegExp(r'echo\s+["\'].*["\'];').hasMatch(code) ||
        RegExp(r'\bfunction\s+\w+\s*\(').hasMatch(code) ||
        RegExp(r'\$\w+').hasMatch(code)) {
      return 'PHP';
    } else if (RegExp(r'<html\s*>').hasMatch(code) ||
        RegExp(r'<body\s*>').hasMatch(code) ||
        RegExp(r'<head\s*>').hasMatch(code) ||
        RegExp(r'<!DOCTYPE\s+html>').hasMatch(code)) {
      return 'HTML';
    } else if (RegExp(r'\.\w+\s*{').hasMatch(code) ||
        RegExp(r'#\w+\s*{').hasMatch(code) ||
        RegExp(r'\bcolor\s*:\s*').hasMatch(code) ||
        RegExp(r'\bfont-size\s*:\s*').hasMatch(code)) {
      return 'CSS';
    } else if (RegExp(r'SELECT\s+.+\s+FROM').hasMatch(code) ||
        RegExp(r'INSERT\s+INTO').hasMatch(code) ||
        RegExp(r'UPDATE\s+\w+\s+SET').hasMatch(code) ||
        RegExp(r'DELETE\s+FROM').hasMatch(code) ||
        RegExp(r'CREATE\s+TABLE').hasMatch(code)) {
      return 'SQL';
    } else if (RegExp(r'^#!/bin/bash').hasMatch(code) ||
        // RegExp(r'\becho\s+["\'].*["\']').hasMatch(code) ||
        RegExp(r'\bif\s*\[\s*.*\s*\]').hasMatch(code) ||
        RegExp(r'\bfor\s+\w+\s+in').hasMatch(code)) {
      return 'Shell';
    } else if (RegExp(r'^<\?xml').hasMatch(code) ||
        RegExp(r'<[a-zA-Z0-9]+[^>]*>').hasMatch(code)) {
      return 'XML';
    }
    return 'Plain Text';
  }

  static List<String> extractTitles(String html) {
    List<String> titles = [];
    dom.Document document = parse(html);
    document.querySelectorAll('h1, h2, h3, h4').forEach((element) {
      titles.add(element.text.trim());
    });
    return titles;
  }

  static List<Anchor> extractAnchors(
    String title,
    String html, {
    bool addTitleAnchor = true,
  }) {
    List<Anchor> titles = [];
    dom.Document document = parse(html);
    document.querySelectorAll('h1, h2, h3, h4').forEach((element) {
      String tagName = element.localName!;
      String text = element.text.trim();
      AnchorType? anchorType;
      switch (tagName) {
        case 'h1':
          anchorType = AnchorType.h1;
          break;
        case 'h2':
          anchorType = AnchorType.h2;
          break;
        case 'h3':
          anchorType = AnchorType.h3;
          break;
        case 'h4':
          anchorType = AnchorType.h4;
          break;
        default:
          return;
      }
      titles.add(Anchor(anchorType,
          StringUtil.clearBlank(StringUtil.extractTextFromHtml(text))));
    });
    if (titles.isNotEmpty) {
      titles.insert(
          0,
          Anchor(AnchorType.top,
              StringUtil.clearBlank(StringUtil.extractTextFromHtml(title))));
    }
    return titles;
  }
}
