import 'dart:collection';

import 'package:pinyin/pinyin.dart';

import '../Models/opt_token.dart';

class TokenSearchRanker {
  static final LinkedHashMap<String, _IndexedToken> _cache = LinkedHashMap();
  static final RegExp _separators = RegExp(r'[\s_\-]+');

  static int? score(OtpToken token, String query) {
    final needle = _normalize(query);
    if (needle.isEmpty) return 0;

    final signature =
        '${token.issuer}\u0000${token.account}\u0000${token.description}';
    var indexed = _cache[token.uid];
    if (indexed == null || indexed.signature != signature) {
      _cache.remove(token.uid);
      if (_cache.length >= 5000) _cache.remove(_cache.keys.first);
      indexed = _IndexedToken(
        signature,
        _IndexedField(token.issuer),
        _IndexedField(token.account),
        _IndexedField(token.description),
      );
      _cache[token.uid] = indexed;
    } else {
      _cache.remove(token.uid);
      _cache[token.uid] = indexed;
    }

    final issuer = _scoreField(indexed.issuer, needle);
    final account = _scoreField(indexed.account, needle);
    final description = _scoreField(indexed.description, needle);
    final scores = [
      if (issuer != null) issuer + 30,
      if (account != null) account + 20,
      if (description != null) description,
    ];
    if (scores.isEmpty) return null;
    scores.sort();
    return scores.last;
  }

  static int? _scoreField(_IndexedField field, String needle) {
    if (field.text.isEmpty) return null;
    if (field.text == needle) return 1000;
    if (field.text.startsWith(needle)) return 900;
    if (field.text.contains(needle)) return 800;
    if (field.pinyin.startsWith(needle)) return 650;
    if (field.pinyin.contains(needle)) return 550;
    if (field.initials.startsWith(needle)) return 500;
    if (field.initials.contains(needle)) return 400;
    if (needle.length >= 2 &&
        (_isSubsequence(field.text, needle) ||
            _isSubsequence(field.pinyin, needle))) {
      return 200;
    }
    return null;
  }

  static bool _isSubsequence(String source, String needle) {
    var position = 0;
    for (final rune in needle.runes) {
      position = source.indexOf(String.fromCharCode(rune), position);
      if (position < 0) return false;
      position++;
    }
    return true;
  }

  static String _normalize(String text) =>
      text.toLowerCase().replaceAll(_separators, '');
}

class _IndexedToken {
  const _IndexedToken(
      this.signature, this.issuer, this.account, this.description);

  final String signature;
  final _IndexedField issuer;
  final _IndexedField account;
  final _IndexedField description;
}

class _IndexedField {
  _IndexedField(String value)
      : text = TokenSearchRanker._normalize(value),
        pinyin = _toPinyin(value, short: false),
        initials = _toPinyin(value, short: true);

  final String text;
  final String pinyin;
  final String initials;

  static String _toPinyin(String value, {required bool short}) {
    if (!RegExp(r'[\u3400-\u9fff]').hasMatch(value)) return '';
    try {
      return TokenSearchRanker._normalize(short
          ? PinyinHelper.getShortPinyin(value)
          : PinyinHelper.getPinyin(value));
    } catch (_) {
      return '';
    }
  }
}
