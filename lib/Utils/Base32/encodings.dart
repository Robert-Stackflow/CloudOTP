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

class EncodingUtils {
  static String getChars(Encoding encoding) {
    return _encodeMap[encoding]!;
  }

  static Map<String, int> getDecodeMap(Encoding encoding) {
    var map = _decodeMap[encoding];
    if (map != null) {
      return map;
    } else {
      var chars = _encodeMap[encoding]!;
      // ignore: omit_local_variable_types
      Map<String, int> map = {};
      for (var i = 0; i < 32; i++) {
        map[chars[i]] = i;
      }
      _decodeMap[encoding] = map;
      return map;
    }
  }

  static RegExp getRegex(Encoding encoding) {
    return _regexMap[encoding]!;
  }

  static bool getPadded(Encoding encoding) {
    return _padded[encoding]!;
  }

  static final _regexMap = {
    Encoding.standardRFC4648: RegExp(r'^[A-Z2-7=]+$'),
    Encoding.nonStandardRFC4648Lower: RegExp(r'^[a-z2-7=]+$'),
    Encoding.base32Hex: RegExp(r'^[0-9A-V=]+$'),
    Encoding.crockford: RegExp(r'^[0123456789ABCDEFGHJKMNPQRSTVWXYZ-]+$'),
    Encoding.zbase32: RegExp(r'^[ybndrfg8ejkmcpqxot1uwisza345h769]+$'),
    Encoding.geohash: RegExp(r'^[0123456789bcdefghjkmnpqrstuvwxyz=]+$')
  };
  static final _encodeMap = {
    Encoding.standardRFC4648: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567',
    Encoding.nonStandardRFC4648Lower: 'abcdefghijklmnopqrstuvwxyz234567',
    Encoding.base32Hex: '0123456789ABCDEFGHIJKLMNOPQRSTUV',
    Encoding.crockford: '0123456789ABCDEFGHJKMNPQRSTVWXYZ',
    Encoding.zbase32: 'ybndrfg8ejkmcpqxot1uwisza345h769',
    Encoding.geohash: '0123456789bcdefghjkmnpqrstuvwxyz'
  };

  static final Map<Encoding, Map<String, int>> _decodeMap = {};

  static final _padded = {
    Encoding.standardRFC4648: true,
    Encoding.nonStandardRFC4648Lower: true,
    Encoding.base32Hex: true,
    Encoding.crockford: false,
    Encoding.zbase32: false,
    Encoding.geohash: true
  };
}

enum Encoding {
  standardRFC4648,
  base32Hex,
  crockford,
  zbase32,
  geohash,
  nonStandardRFC4648Lower
}
