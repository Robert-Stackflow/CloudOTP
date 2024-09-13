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

import 'package:hashlib/hashlib.dart';

/// [MOTP] generates Mobile-OTP (mOTP) codes according to the specification at
/// [https://motp.sourceforge.net](https://motp.sourceforge.net).
///
/// The specification states that the [secret] should be a 16-digit hexadecimal
/// number (e.g. 0123456789abcdef) and the [pin] should be a 4-digit decimal
/// number (e.g. 1234). However, this [MOTP] class permits any arbitrary String
/// for [secret] and [pin]. [secret] and [pin] are **case-sensitive**.
///
/// The default values for [period] and [digits] are from the specification.
class MOTP {
  late String secret;
  late String pin;
  late int period;
  late int digits;

  MOTP({
    required this.secret,
    required this.pin,
    this.period = 10,
    this.digits = 6,
  }) {
    if (period < 1) {
      throw ArgumentError('period must be positive.');
    }
    if (digits < 1 || digits > 32) {
      throw ArgumentError('digits must be in the range 1-32.');
    }
  }

  /// By default, the current epoch time will be used.
  /// This behavior can be overridden by passing in [unixSeconds] explicitly.
  String generate({
    int? unixSeconds,
    int deltaMilliseconds = 0,
  }) {
    unixSeconds ??=
        (DateTime.now().millisecondsSinceEpoch + deltaMilliseconds) ~/ 1000;
    if (unixSeconds < 0) {
      throw ArgumentError('unixSeconds must be non-negative.');
    }
    return md5sum('${unixSeconds ~/ period}$secret$pin', null, true)
        .substring(0, digits);
  }
}
