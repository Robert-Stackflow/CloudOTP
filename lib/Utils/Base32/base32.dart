library base32;

import 'dart:typed_data';
import 'encodings.dart';

// ignore: camel_case_types
class base32 {
  /// Takes in a [byteList] converts it to a Uint8List so that I can run
  /// bit operations on it, then outputs a [String] representation of the
  /// base32.
  static String encode(Uint8List bytesList,
      {Encoding encoding = Encoding.standardRFC4648}) {
    var base32Chars = EncodingUtils.getChars(encoding);
    var i = 0;
    var count = (bytesList.length ~/ 5) * 5;
    var base32str = '';
    while (i < count) {
      var v1 = bytesList[i++];
      var v2 = bytesList[i++];
      var v3 = bytesList[i++];
      var v4 = bytesList[i++];
      var v5 = bytesList[i++];

      base32str += base32Chars[v1 >> 3] +
          base32Chars[(v1 << 2 | v2 >> 6) & 31] +
          base32Chars[(v2 >> 1) & 31] +
          base32Chars[(v2 << 4 | v3 >> 4) & 31] +
          base32Chars[(v3 << 1 | v4 >> 7) & 31] +
          base32Chars[(v4 >> 2) & 31] +
          base32Chars[(v4 << 3 | v5 >> 5) & 31] +
          base32Chars[v5 & 31];
    }

    var remain = bytesList.length - count;
    if (remain == 1) {
      var v1 = bytesList[i];
      base32str += base32Chars[v1 >> 3] + base32Chars[(v1 << 2) & 31];
      if (EncodingUtils.getPadded(encoding)) {
        base32str += '======';
      }
    } else if (remain == 2) {
      var v1 = bytesList[i++];
      var v2 = bytesList[i];
      base32str += base32Chars[v1 >> 3] +
          base32Chars[(v1 << 2 | v2 >> 6) & 31] +
          base32Chars[(v2 >> 1) & 31] +
          base32Chars[(v2 << 4) & 31];
      if (EncodingUtils.getPadded(encoding)) {
        base32str += '====';
      }
    } else if (remain == 3) {
      var v1 = bytesList[i++];
      var v2 = bytesList[i++];
      var v3 = bytesList[i];
      base32str += base32Chars[v1 >> 3] +
          base32Chars[(v1 << 2 | v2 >> 6) & 31] +
          base32Chars[(v2 >> 1) & 31] +
          base32Chars[(v2 << 4 | v3 >> 4) & 31] +
          base32Chars[(v3 << 1) & 31];
      if (EncodingUtils.getPadded(encoding)) {
        base32str += '===';
      }
    } else if (remain == 4) {
      var v1 = bytesList[i++];
      var v2 = bytesList[i++];
      var v3 = bytesList[i++];
      var v4 = bytesList[i];
      base32str += base32Chars[v1 >> 3] +
          base32Chars[(v1 << 2 | v2 >> 6) & 31] +
          base32Chars[(v2 >> 1) & 31] +
          base32Chars[(v2 << 4 | v3 >> 4) & 31] +
          base32Chars[(v3 << 1 | v4 >> 7) & 31] +
          base32Chars[(v4 >> 2) & 31] +
          base32Chars[(v4 << 3) & 31];
      if (EncodingUtils.getPadded(encoding)) {
        base32str += '=';
      }
    }
    return base32str;
  }

  static Uint8List _hexDecode(final String input) => Uint8List.fromList([
        for (int i = 0; i < input.length; i += 2)
          int.parse(input.substring(i, i + 2), radix: 16),
      ]);

  static String _hexEncode(final Uint8List input) => [
        for (int i = 0; i < input.length; i++)
          input[i].toRadixString(16).padLeft(2, '0')
      ].join();

  /// Takes in a [hex] string, converts the string to a byte list
  /// and runs a normal encode() on it. Returning a [String] representation
  /// of the base32.
  static String encodeHexString(String b32hex,
      {Encoding encoding = Encoding.standardRFC4648}) {
    return encode(_hexDecode(b32hex), encoding: encoding);
  }

  /// Takes in a [utf8string], converts the string to a byte list
  /// and runs a normal encode() on it. Returning a [String] representation
  /// of the base32.
  static String encodeString(String utf8string,
      {Encoding encoding = Encoding.standardRFC4648}) {
    return encode(Uint8List.fromList(utf8string.codeUnits), encoding: encoding);
  }

  /// Takes in a [base32] string and decodes it back to a [String] in hex format.
  static String decodeAsHexString(String base32,
      {Encoding encoding = Encoding.standardRFC4648}) {
    return _hexEncode(decode(base32, encoding: encoding));
  }

  /// Takes in a [base32] string and decodes it back to a [String].
  static String decodeAsString(String base32,
      {Encoding encoding = Encoding.standardRFC4648}) {
    return decode(base32, encoding: encoding)
        .toList()
        .map((charCode) => String.fromCharCode(charCode))
        .join();
  }

  /// Takes in a [base32] string and decodes it back to a [Uint8List] that can be
  /// converted to a hex string using hexEncode
  static Uint8List decode(String base32,
      {Encoding encoding = Encoding.standardRFC4648}) {
    if (base32.isEmpty) {
      return Uint8List(0);
    }

    base32 = _pad(base32, encoding: encoding);

    if (!_isValid(base32, encoding: encoding)) {
      throw FormatException('Invalid Base32 characters');
    }

    if (encoding == Encoding.crockford) {
      base32 = base32.replaceAll('-', '');
    } // Handle crockford dashes.

    var base32Decode = EncodingUtils.getDecodeMap(encoding);
    var length = base32.indexOf('=');
    if (length == -1) {
      length = base32.length;
    }

    var i = 0;
    var count = length >> 3 << 3;
    var bytes = <int>[];
    while (i < count) {
      var v1 = base32Decode[base32[i++]] ?? 0;
      var v2 = base32Decode[base32[i++]] ?? 0;
      var v3 = base32Decode[base32[i++]] ?? 0;
      var v4 = base32Decode[base32[i++]] ?? 0;
      var v5 = base32Decode[base32[i++]] ?? 0;
      var v6 = base32Decode[base32[i++]] ?? 0;
      var v7 = base32Decode[base32[i++]] ?? 0;
      var v8 = base32Decode[base32[i++]] ?? 0;
      bytes.add((v1 << 3 | v2 >> 2) & 255);
      bytes.add((v2 << 6 | v3 << 1 | v4 >> 4) & 255);
      bytes.add((v4 << 4 | v5 >> 1) & 255);
      bytes.add((v5 << 7 | v6 << 2 | v7 >> 3) & 255);
      bytes.add((v7 << 5 | v8) & 255);
    }

    var remain = length - count;
    if (remain == 2) {
      var v1 = base32Decode[base32[i++]] ?? 0;
      var v2 = base32Decode[base32[i++]] ?? 0;
      bytes.add((v1 << 3 | v2 >> 2) & 255);
    } else if (remain == 4) {
      var v1 = base32Decode[base32[i++]] ?? 0;
      var v2 = base32Decode[base32[i++]] ?? 0;
      var v3 = base32Decode[base32[i++]] ?? 0;
      var v4 = base32Decode[base32[i++]] ?? 0;
      bytes.add((v1 << 3 | v2 >> 2) & 255);
      bytes.add((v2 << 6 | v3 << 1 | v4 >> 4) & 255);
    } else if (remain == 5) {
      var v1 = base32Decode[base32[i++]] ?? 0;
      var v2 = base32Decode[base32[i++]] ?? 0;
      var v3 = base32Decode[base32[i++]] ?? 0;
      var v4 = base32Decode[base32[i++]] ?? 0;
      var v5 = base32Decode[base32[i++]] ?? 0;
      bytes.add((v1 << 3 | v2 >> 2) & 255);
      bytes.add((v2 << 6 | v3 << 1 | v4 >> 4) & 255);
      bytes.add((v4 << 4 | v5 >> 1) & 255);
    } else if (remain == 7) {
      var v1 = base32Decode[base32[i++]] ?? 0;
      var v2 = base32Decode[base32[i++]] ?? 0;
      var v3 = base32Decode[base32[i++]] ?? 0;
      var v4 = base32Decode[base32[i++]] ?? 0;
      var v5 = base32Decode[base32[i++]] ?? 0;
      var v6 = base32Decode[base32[i++]] ?? 0;
      var v7 = base32Decode[base32[i++]] ?? 0;
      bytes.add((v1 << 3 | v2 >> 2) & 255);
      bytes.add((v2 << 6 | v3 << 1 | v4 >> 4) & 255);
      bytes.add((v4 << 4 | v5 >> 1) & 255);
      bytes.add((v5 << 7 | v6 << 2 | v7 >> 3) & 255);
    }
    return Uint8List.fromList(bytes);
  }

  static bool _isValid(String b32str,
      {Encoding encoding = Encoding.standardRFC4648}) {
    var regex = EncodingUtils.getRegex(encoding);
    if (b32str.length % 2 != 0 || !regex.hasMatch(b32str)) {
      return false;
    }
    return true;
  }

  static String _pad(String base32,
      {Encoding encoding = Encoding.standardRFC4648}) {
    if (EncodingUtils.getPadded(encoding)) {
      int neededPadding = (8 - base32.length % 8) % 8;
      return base32.padRight(base32.length + neededPadding, '=');
    }
    return base32;
  }
}
