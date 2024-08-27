import 'dart:typed_data';

import 'package:hashlib/hashlib.dart';

import '../../Utils/Base32/base32.dart';
import '../../Utils/ilogger.dart';

/// [SteamTOTP] generates 5-character alphanumeric Steam TOTP codes.
/// Possible characters can be found in [SteamTOTP.steamChars].
class SteamTOTP {
  late String secret;
  late Uint8List _sharedSecretArray;

  static const String steamChars = '23456789BCDFGHJKMNPQRTVWXY';

  SteamTOTP({required this.secret}) {
    if (secret.isEmpty) {
      throw ArgumentError('secret must not be empty.');
    }
    try {
      _sharedSecretArray = base32.decode(secret.toUpperCase());
      if (_sharedSecretArray.isEmpty) {
        throw Exception();
      }
    } catch (e, t) {
      ILogger.error("Failed to get steam TOTP", e, t);
      throw ArgumentError('secret must be valid base32.');
    }
  }

  /// By default, the current epoch time will be used.
  /// This behavior can be overridden by passing in [unixSeconds] explicitly.
  String generate({
    int? unixSeconds,
    int deltaMilliseconds = 0,
  }) {
    int time = unixSeconds ??
        (DateTime.now().millisecondsSinceEpoch + deltaMilliseconds) ~/ 1000;
    if (time < 0) {
      throw ArgumentError('unixSeconds must be non-negative.');
    }
    time ~/= 30; // Period is 30 seconds.

    final Uint8List timeArray = Uint8List(8);
    for (int i = 8; i > 0; i--) {
      timeArray[i - 1] = time & 0xFF;
      time = time >> 8;
    }

    final Uint8List hmac =
        HMAC(sha1, _sharedSecretArray).convert(timeArray).bytes;
    final int b = (hmac[19] & 0xF) % 0xFF;
    int codePoint = (hmac[b] & 0x7F) << 24 |
        (hmac[b + 1] & 0xFF) << 16 |
        (hmac[b + 2] & 0xFF) << 8 |
        (hmac[b + 3] & 0xFF); // Maximum possible value: 2147483647

    final List<String> codeArray = List.filled(5, '');
    for (int i = 0; i < 5; i++) {
      codeArray[i] = steamChars[codePoint % steamChars.length];
      codePoint = codePoint ~/ steamChars.length;
    }
    return codeArray.join('');
  }
}
