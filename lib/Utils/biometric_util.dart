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
import 'package:biometric_storage/biometric_storage.dart';

import '../l10n/l10n.dart';

extension AvailableBiometric on CanAuthenticateResponse {
  bool get isAvailable =>
      this != CanAuthenticateResponse.unsupported &&
      this != CanAuthenticateResponse.statusUnknown;

  bool get isSuccess => this == CanAuthenticateResponse.success;
}

class BiometricUtil {
  static const String databasePassswordStorageKey = "CloudOTP-DatabasePassword";
  static BiometricStorageFile? databasePassswordStorage;

  static Future<CanAuthenticateResponse> canAuthenticate() async {
    return await BiometricStorage().canAuthenticate();
  }

  static Future<String?> getCanAuthenticateResponseString() async {
    CanAuthenticateResponse response = await canAuthenticate();
    switch (response) {
      case CanAuthenticateResponse.success:
        return null;
      case CanAuthenticateResponse.errorHwUnavailable:
        return appLocalizations.biometricErrorHwUnavailable;
      case CanAuthenticateResponse.errorNoBiometricEnrolled:
        return appLocalizations.biometricErrorNoBiometricEnrolled;
      case CanAuthenticateResponse.errorNoHardware:
        return appLocalizations.biometricErrorNoHardware;
      case CanAuthenticateResponse.errorPasscodeNotSet:
        return appLocalizations.biometricErrorPasscodeNotSet;
      case CanAuthenticateResponse.unsupported:
        return appLocalizations.biometricErrorUnsupported;
      default:
        return appLocalizations.biometricErrorUnkown;
    }
  }

  static Future<bool> isBiometricAvailable() async {
    final response = await BiometricStorage().canAuthenticate();
    if (response != CanAuthenticateResponse.success) {
      switch (response) {
        case CanAuthenticateResponse.errorHwUnavailable:
          ILogger.info(
              "BiometricStorage", "Biometric hardware is not available");
          break;
        case CanAuthenticateResponse.errorNoBiometricEnrolled:
          ILogger.info(
              "BiometricStorage", "No biometric enrolled on this device");
          break;
        case CanAuthenticateResponse.errorNoHardware:
          ILogger.info(
              "BiometricStorage", "No biometric hardware on this device");
          break;
        case CanAuthenticateResponse.errorPasscodeNotSet:
          ILogger.info("BiometricStorage", "No passcode set on this device");
          break;
        default:
          ILogger.info("BiometricStorage", "Unknown error");
          break;
      }
    }
    return response == CanAuthenticateResponse.success;
  }

  static Future<void> initStorage({
    bool forceInit = false,
  }) async {
    bool isAvailable = await isBiometricAvailable();
    if (!isAvailable) return;
    databasePassswordStorage = await BiometricStorage().getStorage(
      databasePassswordStorageKey,
      forceInit: forceInit,
    );
  }

  static Future<bool> exists() async {
    try {
      await initStorage(forceInit: true);
      return false;
    } catch (e) {
      return true;
    }
  }

  static Future<String?> getDatabasePassword() async {
    if (databasePassswordStorage == null) {
      await initStorage();
    }
    if (databasePassswordStorage == null) {
      return null;
    }
    return await databasePassswordStorage!.read(
      promptInfo: PromptInfo(
        androidPromptInfo: AndroidPromptInfo(
          title: appLocalizations.biometricSignInTitle,
          subtitle: appLocalizations.biometricToDecryptDatabase,
          negativeButton: appLocalizations.biometricCancelButton,
        ),
      ),
    );
  }

  static Future<bool> setDatabasePassword(String password) async {
    if (databasePassswordStorage == null) {
      await initStorage();
    }
    if (databasePassswordStorage == null) {
      return false;
    }
    try {
      await databasePassswordStorage!.write(
        password,
        promptInfo: PromptInfo(
          androidPromptInfo: AndroidPromptInfo(
            title: appLocalizations.biometricSignInTitle,
            subtitle: appLocalizations.biometricToSaveDatabasePassword,
            negativeButton: appLocalizations.biometricCancelButton,
          ),
        ),
      );
      return true;
    } catch (e, t) {
      ILogger.error("Failed to save database password: $e\n$t");
      if (e is AuthException) {
        switch (e.code) {
          case AuthExceptionCode.userCanceled:
            IToast.showTop(appLocalizations.biometricUserCanceled);
            break;
          case AuthExceptionCode.timeout:
            IToast.showTop(appLocalizations.biometricTimeout);
            break;
          case AuthExceptionCode.unknown:
            IToast.showTop(appLocalizations.biometricLockout);
            break;
          case AuthExceptionCode.canceled:
          default:
            IToast.showTop(appLocalizations.biometricError);
            break;
        }
      }
      return false;
    }
  }

  static Future<void> clearDatabasePassword() async {
    if (databasePassswordStorage == null) {
      return;
    }
    try {
      await databasePassswordStorage!.delete();
    } catch (e, t) {
      ILogger.error("Failed to delete database password: $e\n$t");
    }
  }
}
