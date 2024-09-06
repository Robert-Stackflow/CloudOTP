import 'package:biometric_storage/biometric_storage.dart';
import 'package:cloudotp/Utils/ilogger.dart';

import '../generated/l10n.dart';

class BiometricUtil {
  static const String databasePassswordStorageKey = "CloudOTP-DatabasePassword";
  static BiometricStorageFile? databasePassswordStorage;

  static Future<CanAuthenticateResponse> canAuthenticate() async {
    return await BiometricStorage().canAuthenticate();
  }

  static Future<bool> isBiometricAvailable() async {
    final response = await BiometricStorage().canAuthenticate();
    if (response != CanAuthenticateResponse.success) {
      switch (response) {
        case CanAuthenticateResponse.errorHwUnavailable:
          ILogger.info("Biometric hardware is not available");
          break;
        case CanAuthenticateResponse.errorNoBiometricEnrolled:
          ILogger.info("No biometric enrolled on this device");
          break;
        case CanAuthenticateResponse.errorNoHardware:
          ILogger.info("No biometric hardware on this device");
          break;
        case CanAuthenticateResponse.errorPasscodeNotSet:
          ILogger.info("No passcode set on this device");
          break;
        default:
          ILogger.info("Unknown error");
          break;
      }
    }
    return response == CanAuthenticateResponse.success;
  }

  static Future<void> initStorage() async {
    bool isAvailable = await isBiometricAvailable();
    if (!isAvailable) {
      return;
    }
    databasePassswordStorage = await BiometricStorage().getStorage(
      databasePassswordStorageKey,
    );
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
          title: S.current.biometricSignInTitle,
          subtitle: S.current.biometricToDecryptDatabase,
          negativeButton: S.current.biometricCancelButton,
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
            title: S.current.biometricSignInTitle,
            subtitle: S.current.biometricToSaveDatabasePassword,
            negativeButton: S.current.biometricCancelButton,
          ),
        ),
      );
      return true;
    } catch (e, t) {
      ILogger.error("Failed to save database password: $e\n$t");
      return false;
    }
  }
}
