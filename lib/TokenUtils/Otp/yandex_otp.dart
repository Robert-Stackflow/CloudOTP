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

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart';

import '../../Utils/Base32/base32.dart';

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
    return base32.decode(secret.toUpperCase());
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

    var hmacSha256 = HMAC(sha256, key);
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
