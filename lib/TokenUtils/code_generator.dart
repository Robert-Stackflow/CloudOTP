import 'package:cloudotp/Models/opt_token.dart';
import 'package:otp/otp.dart';

import 'Otp/mobile_otp.dart';
import 'Otp/steam_totp.dart';
import 'Otp/yandex_otp.dart';

class CodeGenerator {
  static String getCurrentCode(OtpToken token) {
    late String code;
    try {
      switch (token.tokenType) {
        case OtpTokenType.TOTP:
          code = OTP.generateTOTPCodeString(
            token.secret,
            DateTime.now().millisecondsSinceEpoch,
            length: token.digits.digit,
            interval: token.period,
            algorithm: token.algorithm.algorithm,
            isGoogle: true,
          );
          break;
        case OtpTokenType.HOTP:
          code = OTP.generateHOTPCodeString(
            token.secret,
            token.counter,
            length: token.digits.digit,
            algorithm: token.algorithm.algorithm,
            isGoogle: true,
          );
          break;
        case OtpTokenType.MOTP:
          code = MOTP(
            secret: token.secret,
            pin: token.pin,
            period: token.period,
            digits: token.digits.digit,
          ).generate();
          break;
        case OtpTokenType.Steam:
          code = SteamTOTP(secret: token.secret).generate();
          break;
        case OtpTokenType.Yandex:
          code = YandexOTP(
            pin: token.pin,
            secret: token.secret,
          ).generate();
          break;
      }
    } catch (e) {
      code = "ERROR";
    }
    return code;
  }

  static String getNextCode(OtpToken token) {
    late String code;
    try {
      switch (token.tokenType) {
        case OtpTokenType.TOTP:
          code = OTP.generateTOTPCodeString(
            token.secret,
            DateTime.now().millisecondsSinceEpoch + token.period * 1000,
            length: token.digits.digit,
            interval: token.period,
            algorithm: token.algorithm.algorithm,
            isGoogle: true,
          );
          break;
        case OtpTokenType.HOTP:
          code = OTP.generateHOTPCodeString(
            token.secret,
            token.counter + 1,
            length: token.digits.digit,
            algorithm: token.algorithm.algorithm,
            isGoogle: true,
          );
          break;
        case OtpTokenType.MOTP:
          code = MOTP(
            secret: token.secret,
            pin: token.pin,
            period: token.period,
            digits: token.digits.digit,
          ).generate(deltaMilliseconds: token.period * 1000);
          break;
        case OtpTokenType.Steam:
          code = SteamTOTP(secret: token.secret)
              .generate(deltaMilliseconds: token.period * 1000);
          break;
        case OtpTokenType.Yandex:
          code = YandexOTP(
            pin: token.pin,
            secret: token.secret,
          ).generate(deltaMilliseconds: token.period * 1000);
          break;
      }
    } catch (e) {
      code = "ERROR";
    }
    return code;
  }
}
