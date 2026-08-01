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

import 'dart:convert';
import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:hashlib/hashlib.dart';

import '../Database/database_manager.dart';
import 'constant.dart';

class CloudOTPHiveUtil {
  //Database
  static const String database = "CloudOTP";

  //HiveBox
  static const String settingsBox = "settings";

  //Auth
  static const String defaultDatabasePasswordKey = "defaultDatabasePassword";

  static const String dragToReorderKey = "dragToReorder";
  static const String layoutTypeKey = "layoutType";
  static const String orderTypeKey = "orderType";
  static const String selectedCategoryUidKey = "selectedCategoryUid";
  static const String autoCompleteParameterKey = "autoCompleteParameter";
  static const String clickToCopyKey = "clickToCopy";
  static const String autoFocusSearchBarKey = "autoFocusSearchBar";
  static const String autoCopyNextCodeKey = "autoCopyNextCode";
  static const String autoDisplayNextCodeKey = "autoDisplayNextCode";
  static const String autoMinimizeAfterClickToCopyKey =
      "autoMinimizeAfterClickToCopy";
  static const String autoMinimizeAfterClickToCopyOptionKey =
      "autoMinimizeAfterClickToCopyOption";
  static const String hideProgressBarKey = "hideProgressBar";
  static const String autoHideCodeKey = "autoHideCode";
  static const String defaultHideCodeKey = "defaultHideCode";
  static const String showEyeKey = "showEye";
  static const String issuerAndAccountShowOptionKey =
      "issuerAndAccountShowOption";

  //Appearance
  static const String showCloudBackupButtonKey = "showCloudBackupButton";
  static const String showSortButtonKey = "showSortButton";
  static const String showLayoutButtonKey = "showLayoutButton";
  static const String showBackupLogButtonKey = "showBackupLogButton";
  static const String enableFrostedGlassEffectKey = "enableFrostedGlassEffect";
  static const String hideAppbarWhenScrollingKey = "hideAppbarWhenScrolling";
  static const String hideBottombarWhenScrollingKey =
      "hideBottombarWhenScrolling";
  static const String enableLandscapeInTabletKey = "enableLandscapeInTablet";
  static const String enableModalSheetKey = "enableModalSheet";

  //Backup
  static const String enableAutoBackupKey = "enableAutoBackup";
  static const String enableLocalBackupKey = "enableLocalBackup";
  static const String maxBackupsCountKey = "maxBackupsCount";
  static const String enableCloudBackupKey = "enableCloudBackup";
  static const String backupPathKey = "backupPath";
  static const String useBackupPasswordToExportImportKey =
      "useBackupPasswordToExportImport";
  static const String enableBackupOnLaunchKey = "enableBackupOnLaunch";
  static const String enablePeriodicBackupKey = "enablePeriodicBackup";
  static const String periodicBackupIntervalKey = "periodicBackupInterval";

  //Encrypt
  static const String encryptDatabaseStatusKey = "encryptDatabaseStatus";

  //Privacy
  static const String enableGuesturePasswdKey = "enableGuesturePasswd";
  static const String guesturePasswdKey = "guesturePasswd";
  static const String enableBiometricKey = "enableBiometric";
  static const String allowDatabaseBiometricKey = "allowDatabaseBiometric";
  static const String autoLockKey = "autoLock";
  static const String autoLockTimeKey = "autoLockTime";
  static const String enableSafeModeKey = "enableSafeMode";
  static const String hideGestureTrailKey = "hideGestureTrail";
  static const String followSystemTextScaleKey = "followSystemTextScale";
  static const String gestureFailedAttemptsKey = "gestureFailedAttempts";
  static const String gestureLockoutEndKey = "gestureLockoutEnd";

  //System
  static const String oldVersionKey = "oldVersion";
  static const String haveShowQAuthDialogKey = "haveShowQAuthDialog";
  static const String haveShownCoachMarkKey = "haveShownCoachMark";
  static const String haveShownDesktopCoachMarkKey =
      "haveShownDesktopCoachMark";
  static const String haveShownWelcome4Key = "haveShownWelcome4";

  static initConfig() async {
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.layoutTypeKey, LayoutType.List.index);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.autoFocusSearchBarKey, false);
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.maxBackupsCountKey, defaultMaxBackupCount);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.backupPathKey, "");
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.dragToReorderKey, !ResponsiveUtil.isMobile());
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey, false);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.hideGestureTrailKey, false);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.showSortButtonKey, true);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.showLayoutButtonKey, true);
  }

  static bool canLock() => canGuestureLock() || canDatabaseLock();

  static bool canGuestureLock() =>
      ChewieHiveUtil.getBool(enableGuesturePasswdKey) &&
      ChewieHiveUtil.getString(guesturePasswdKey).notNullOrEmpty;

  static bool shouldAutoLock() =>
      ChewieHiveUtil.getBool(autoLockKey) && canLock();

  static bool canDatabaseLock() =>
      getEncryptDatabaseStatus() == EncryptDatabaseStatus.customPassword &&
      DatabaseManager.isDatabaseEncrypted;

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _hashWithSalt(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).hex();

  static bool _isLegacyHash(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);

  static bool _isSaltedHash(String value) =>
      value.length == 97 && value[32] == '\$';

  static void setGesturePassword(String password) {
    final salt = _generateSalt();
    final hash = _hashWithSalt(password, salt);
    ChewieHiveUtil.put(guesturePasswdKey, '$salt\$$hash');
  }

  static bool verifyGesturePassword(String input) {
    final stored = ChewieHiveUtil.getString(guesturePasswdKey);
    if (stored == null || stored.isEmpty) return false;
    if (_isSaltedHash(stored)) {
      final salt = stored.substring(0, 32);
      final hash = stored.substring(33);
      return hash == _hashWithSalt(input, salt);
    }
    if (_isLegacyHash(stored)) {
      final legacyHash = sha256.convert(utf8.encode(input)).hex();
      if (stored == legacyHash) {
        setGesturePassword(input);
        return true;
      }
      return false;
    }
    // Legacy plaintext
    if (stored == input) {
      setGesturePassword(input);
      return true;
    }
    return false;
  }

  static Future<bool> showCloudEntry() async {
    String autoBackupPassword = (await ConfigDao.getConfig()).backupPassword;
    bool enableCloudBackup =
        ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableCloudBackupKey);
    return enableCloudBackup && autoBackupPassword.isNotEmpty;
  }

  static AutoLockTime getAutoLockTime() {
    return AutoLockTime.values[
        ChewieHiveUtil.getInt(CloudOTPHiveUtil.autoLockTimeKey)
            .clamp(0, AutoLockTime.values.length - 1)];
  }

  static Future<void> setAutoLockTime(AutoLockTime time) async {
    await ChewieHiveUtil.put(CloudOTPHiveUtil.autoLockTimeKey, time.index);
  }

  static int getMaxBackupsCount() {
    return ChewieHiveUtil.getInt(CloudOTPHiveUtil.maxBackupsCountKey,
        defaultValue: defaultMaxBackupCount);
  }

  static Future<void> setMaxBackupsCount(int count) async {
    await ChewieHiveUtil.put(CloudOTPHiveUtil.maxBackupsCountKey, count);
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _secureDbPasswordKey = 'cloudotp_db_password';

  static String generateDatabasePassword() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Future<void> _writeAndVerifySecurePassword(String password) async {
    await _secureStorage.write(key: _secureDbPasswordKey, value: password);
    final persisted = await _secureStorage.read(key: _secureDbPasswordKey);
    if (persisted != password) {
      throw const DatabasePasswordStorageException(
        'Database password could not be verified in secure storage.',
      );
    }
  }

  static Future<void> saveDatabasePassword(String password) async {
    await _writeAndVerifySecurePassword(password);
    await ChewieHiveUtil.delete(defaultDatabasePasswordKey);
  }

  static Future<String> regeneratePassword() async {
    final password = generateDatabasePassword();
    await saveDatabasePassword(password);
    return password;
  }

  static Future<String> getDatabasePassword() async {
    String? securePassword;
    try {
      securePassword = await _secureStorage.read(key: _secureDbPasswordKey);
    } catch (e, t) {
      ILogger.error("Secure storage unavailable, falling back to Hive", e, t);
    }
    String? hivePassword =
        ChewieHiveUtil.getString(CloudOTPHiveUtil.defaultDatabasePasswordKey);
    if (securePassword != null && securePassword.isNotEmpty) {
      if (hivePassword != null && hivePassword.isNotEmpty) {
        await ChewieHiveUtil.delete(defaultDatabasePasswordKey);
      }
      return securePassword;
    }
    if (hivePassword != null && hivePassword.isNotEmpty) {
      try {
        await _writeAndVerifySecurePassword(hivePassword);
        await ChewieHiveUtil.delete(defaultDatabasePasswordKey);
        ILogger.info('Migrated database password to secure storage');
      } catch (e, t) {
        ILogger.error(
          'Database password migration deferred; the legacy copy was kept',
          e,
          t,
        );
      }
      return hivePassword;
    }
    return '';
  }

  static Future<String> getBackupPath() async {
    String res = ChewieHiveUtil.getString(CloudOTPHiveUtil.backupPathKey,
            defaultValue: "") ??
        "";
    if (res.isEmpty) res = await FileUtil.getBackupDir();
    return res;
  }

  static Future<bool> canImportOrExportUseBackupPassword() async {
    return ChewieHiveUtil.getBool(
            CloudOTPHiveUtil.useBackupPasswordToExportImportKey) &&
        await ConfigDao.hasBackupPassword();
  }

  static Future<bool> canAutoBackup() async {
    return ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableAutoBackupKey) &&
        (await CloudOTPHiveUtil.getBackupPath()).notNullOrEmpty &&
        await ConfigDao.hasBackupPassword();
  }

  static Future<bool> canBackup() async {
    return (await getBackupPath()).notNullOrEmpty &&
        await ConfigDao.hasBackupPassword();
  }

  static setLayoutType(LayoutType type) {
    ChewieHiveUtil.put(CloudOTPHiveUtil.layoutTypeKey, type.index);
  }

  static LayoutType getLayoutType() {
    return LayoutType.values[ChewieUtils.patchEnum(
        ChewieHiveUtil.getInt(CloudOTPHiveUtil.layoutTypeKey),
        LayoutType.values.length,
        defaultValue: LayoutType.Compact.index)];
  }

  static setSelectedCategoryUid(String uid) {
    ChewieHiveUtil.put(CloudOTPHiveUtil.selectedCategoryUidKey, uid);
  }

  static String getSelectedCategoryId() {
    return ChewieHiveUtil.getString(CloudOTPHiveUtil.selectedCategoryUidKey) ??
        "";
  }

  static EncryptDatabaseStatus getEncryptDatabaseStatus() {
    return EncryptDatabaseStatus.values[ChewieUtils.patchEnum(
        ChewieHiveUtil.getInt(CloudOTPHiveUtil.encryptDatabaseStatusKey),
        EncryptDatabaseStatus.values.length)];
  }

  static Future<void> setEncryptDatabaseStatus(
      EncryptDatabaseStatus status) async {
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.encryptDatabaseStatusKey, status.index);
  }

  static setOrderType(OrderType type) {
    ChewieHiveUtil.put(CloudOTPHiveUtil.orderTypeKey, type.index);
  }

  static OrderType getOrderType() {
    return OrderType.values[ChewieUtils.patchEnum(
        ChewieHiveUtil.getInt(CloudOTPHiveUtil.orderTypeKey),
        OrderType.values.length)];
  }
}

class DatabasePasswordStorageException implements Exception {
  final String message;

  const DatabasePasswordStorageException(this.message);

  @override
  String toString() => 'DatabasePasswordStorageException: $message';
}
