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

import 'package:cloudotp/generated/l10n.dart';

import '../../Utils/ilogger.dart';
import '../Models/opt_token.dart';
import '../Utils/Base32/base32.dart';

enum CheckTokenError {
  ISSUER_EMPTY,
  SECRET_EMPTY,
  PIN_EMPTY,
  SECRET_BASE32_ERROR,
  period_ERROR,
  UNKNOWN_ERROR;

  String get message {
    switch (this) {
      case CheckTokenError.ISSUER_EMPTY:
        return S.current.issuerCannotBeEmpty;
      case CheckTokenError.SECRET_EMPTY:
        return S.current.secretCannotBeEmpty;
      case CheckTokenError.SECRET_BASE32_ERROR:
        return S.current.secretNotBase32;
      case CheckTokenError.period_ERROR:
        return S.current.periodTooLong;
      case CheckTokenError.PIN_EMPTY:
        return S.current.pinCannotBeEmpty;
      case CheckTokenError.UNKNOWN_ERROR:
        return S.current.tokenUnKnownError;
    }
  }
}

class CheckTokenUtil {
  static CheckTokenError? checkToken(OtpToken token) {
    if (token.issuer.isEmpty) {
      return CheckTokenError.ISSUER_EMPTY;
    }
    if (token.secret.isEmpty) {
      return CheckTokenError.SECRET_EMPTY;
    }
    if (token.tokenType == OtpTokenType.MOTP && token.pin.isEmpty) {
      return CheckTokenError.PIN_EMPTY;
    }
    if (token.tokenType == OtpTokenType.Steam &&
        !isSecretBase32(token.secret)) {
      return CheckTokenError.SECRET_BASE32_ERROR;
    }
    if (!isIntervalValid(token.periodString)) {
      return CheckTokenError.period_ERROR;
    }
    return null;
  }

  static bool isTokenValid(OtpToken token) {
    if (token.secret.isEmpty ||
        !isSecretValid(token.secret) ||
        !isSecretBase32(token.secret) ||
        !isIntervalValid(token.periodString)) {
      return false;
    }
    return true;
  }

  static bool isSecretValid(String str) {
    return RegExp(r"^[a-zA-Z|0-9]+$").hasMatch(str);
  }

  static bool isSecretBase32(String str) {
    try {
      base32.decode(str.toUpperCase());
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to decode base32 from $str", e, t);
      return false;
    }
    return true;
  }

  static bool isIntervalValid(String str) {
    try {
      int.parse(str);
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to parse int from interval $str", e, t);
      return false;
    }
    return true;
  }
}
