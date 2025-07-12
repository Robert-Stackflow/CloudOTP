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
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';

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
  //Backup
  static const String enableAutoBackupKey = "enableAutoBackup";
  static const String enableLocalBackupKey = "enableLocalBackup";
  static const String maxBackupsCountKey = "maxBackupsCount";
  static const String enableCloudBackupKey = "enableCloudBackup";
  static const String backupPathKey = "backupPath";
  static const String useBackupPasswordToExportImportKey =
      "useBackupPasswordToExportImport";

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

  //System
  static const String oldVersionKey = "oldVersion";

  static initConfig() async {
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.layoutTypeKey, LayoutType.Compact.index);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.autoFocusSearchBarKey, false);
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.maxBackupsCountKey, defaultMaxBackupCount);
    await ChewieHiveUtil.put(CloudOTPHiveUtil.backupPathKey, "");
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.dragToReorderKey, !ResponsiveUtil.isMobile());
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey, false);
  }

  static bool canLock() => canGuestureLock() || canDatabaseLock();

  static bool canGuestureLock() =>
      ChewieHiveUtil.getBool(enableGuesturePasswdKey) &&
      ChewieHiveUtil.getString(guesturePasswdKey).notNullOrEmpty;

  static bool canDatabaseLock() =>
      getEncryptDatabaseStatus() == EncryptDatabaseStatus.customPassword &&
      DatabaseManager.isDatabaseEncrypted;

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

  static Future<String> regeneratePassword() async {
    String password = MockUtil.getRandomString(length: 16);
    await ChewieHiveUtil.put(
        CloudOTPHiveUtil.defaultDatabasePasswordKey, password);
    return password;
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
