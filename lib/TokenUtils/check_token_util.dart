import 'package:base32/base32.dart';

import '../Models/opt_token.dart';

enum CheckTokenError {
  ISSUER_EMPTY,
  SECRET_EMPTY,
  SECRET_BASE32_ERROR,
  period_ERROR,
  UNKNOWN_ERROR;

  String get message {
    switch (this) {
      case CheckTokenError.ISSUER_EMPTY:
        return "应用名称不能为空";
      case CheckTokenError.SECRET_EMPTY:
        return "密钥不能为空";
      case CheckTokenError.SECRET_BASE32_ERROR:
        return "密钥不是Base32编码";
      case CheckTokenError.period_ERROR:
        return "时间间隔不是整数或过长";
      case CheckTokenError.UNKNOWN_ERROR:
        return "未知错误";
      default:
        return "未知错误";
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
    if (!isSecretBase32(token.secret)) {
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
    return RegExp("[a-zA-Z|0-9]+").hasMatch(str);
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
