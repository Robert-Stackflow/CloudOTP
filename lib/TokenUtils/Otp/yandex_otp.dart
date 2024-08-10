import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

class YandexOTP {
  Uint8List key;

  YandexOTP({
    required String pin,
    required String secret,
  }) : key = Uint8List.fromList(
            sha256.convert(utf8.encode(pin) + _decodeSecret(secret)).bytes);

  static Uint8List _decodeSecret(String secret) {
    int lastBlockWidth = secret.length % 8;
    if (lastBlockWidth != 0) {
      secret += '=' * (8 - lastBlockWidth);
    }
    return base32.decode(secret);
  }

  static String _otpToYandex(int otp) {
    otp = otp % (pow(26, 8).toInt());
    String code = '';
    while (code.length < 8) {
      code = String.fromCharCode('a'.codeUnitAt(0) + (otp % 26)) + code;
      otp ~/= 26;
    }
    return code;
  }

  static int _timeToCounter(int timestamp) {
    return timestamp ~/ 30;
  }

  String generate({
    int? counter,
    int deltaMilliseconds = 0,
  }) {
    counter ??= _timeToCounter(
        (DateTime.now().millisecondsSinceEpoch + deltaMilliseconds) ~/ 1000);

    var hmacSha256 = Hmac(sha256, key);
    var counterBytes = ByteData(8)..setInt64(0, counter, Endian.big);
    var hmacHash = hmacSha256.convert(counterBytes.buffer.asUint8List()).bytes;

    int offset = hmacHash[hmacHash.length - 1] & 0xF;
    int otp = (ByteData.sublistView(
                    Uint8List.fromList(hmacHash.sublist(offset, offset + 8)))
                .getInt64(0, Endian.big) &
            0x7FFFFFFFFFFFFFFF)
        .toUnsigned(64);

    return _otpToYandex(otp);
  }
}
