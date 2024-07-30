import 'package:base32/base32.dart';
import 'package:cloudotp/generated/l10n.dart';

import '../Models/opt_token.dart';

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
      base32.decode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  static bool isIntervalValid(String str) {
    try {
      int.parse(str);
    } catch (e) {
      return false;
    }
    return true;
  }
}
