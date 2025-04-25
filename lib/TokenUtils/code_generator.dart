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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/opt_token.dart';

import 'Otp/mobile_otp.dart';
import 'Otp/otp.dart';
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
    } catch (e, t) {
      ILogger.error("Failed to get current code from token $token", e, t);
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
    } catch (e, t) {
      ILogger.error("Failed to get next code from token $token", e, t);
      code = "ERROR";
    }
    return code;
  }
}
