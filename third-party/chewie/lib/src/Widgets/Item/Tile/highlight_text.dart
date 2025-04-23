import 'package:awesome_chewie/src/Widgets/Item/Tile/searchable_stateful_widget.dart';
import 'package:flutter/material.dart';
import 'package:pinyin/pinyin.dart';

List<List<int>> getMatchedRanges(
  String text,
  String query, {
  SearchConfig? searchConfig,
}) {
  var tmpSearchConfig = searchConfig ?? SearchConfig();
  if (query.trim().isEmpty) return [];

  final lowerQuery = query.trim().toLowerCase();
  final List<String> queries = tmpSearchConfig.enableSplit
      ? lowerQuery.split(RegExp(r'\s+'))
      : [lowerQuery];
  final chars = text.characters.toList();
  final pinyins = chars
      .map((c) => PinyinHelper.getPinyinE(c, separator: '', defPinyin: '')
          .toLowerCase())
      .toList();
  final shortPinyins =
      chars.map((c) => PinyinHelper.getShortPinyin(c).toLowerCase()).toList();

  final matches = <List<int>>[];

  for (final query in queries) {
    for (int start = 0; start < chars.length; start++) {
      for (int end = start + 1; end <= chars.length; end++) {
        final origSlice = chars.sublist(start, end).join().toLowerCase();
        final pinyinSlice = pinyins.sublist(start, end).join();
        final shortSlice = shortPinyins.sublist(start, end).join();

        if (origSlice == query ||
            (pinyinSlice == query && tmpSearchConfig.enablePinyin) ||
            (shortSlice == query && tmpSearchConfig.enableShortPinyin)) {
          matches.add([start, end - 1]);
          break;
        }
      }
    }
  }
  return matches;
}

TextSpan highlightText(
  String text,
  String query,
  TextStyle normal,
  TextStyle highlight, {
  SearchConfig? searchConfig,
}) {
  final ranges = getMatchedRanges(
    text,
    query,
    searchConfig: searchConfig,
  );
  final chars = text.characters.toList();
  final highlights = List<bool>.filled(chars.length, false);

  for (final [start, end] in ranges) {
    for (int i = start; i <= end; i++) {
      highlights[i] = true;
    }
  }

  return TextSpan(
    children: List.generate(chars.length, (i) {
      return TextSpan(
        text: chars[i],
        style: highlights[i] ? highlight : normal,
      );
    }),
  );
}
