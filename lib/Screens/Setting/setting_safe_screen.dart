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
import 'package:cloudotp/Utils/biometric_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_password_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../Database/database_manager.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';
import 'base_setting_screen.dart';

class SafeSettingScreen extends BaseSettingScreen {
  const SafeSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/privacy";

  @override
  State<SafeSettingScreen> createState() => _SafeSettingScreenState();
}

class _SafeSettingScreenState extends BaseDynamicState<SafeSettingScreen>
    with TickerProviderStateMixin {
  bool _enableGuesturePasswd =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableGuesturePasswdKey);
  bool _hasGuesturePasswd =
      ChewieHiveUtil.getString(CloudOTPHiveUtil.guesturePasswdKey)
          .notNullOrEmpty;
  bool _autoLock = ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoLockKey);
  bool _enableSafeMode = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.enableSafeModeKey,
      defaultValue: defaultEnableSafeMode);
  bool _allowGuestureBiometric =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableBiometricKey);
  bool _allowDatabaseBiometric = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.allowDatabaseBiometricKey,
      defaultValue: false);
  EncryptDatabaseStatus _encryptDatabaseStatus =
      CloudOTPHiveUtil.getEncryptDatabaseStatus();
  String? canAuthenticateResponseString;
  CanAuthenticateResponse? canAuthenticateResponse;

  bool get _biometricAvailable => canAuthenticateResponse?.isAvailable ?? false;

  bool get _geusturePasswdAvailable =>
      _enableGuesturePasswd && !_encryptedAndCustomPassword;

  bool get _gesturePasswdAvailableAndSet =>
      _geusturePasswdAvailable && _hasGuesturePasswd;

  bool get _encryptedAndCustomPassword =>
      DatabaseManager.isDatabaseEncrypted &&
      _encryptDatabaseStatus == EncryptDatabaseStatus.customPassword;

  bool get _encryptedAndDefaultPassword =>
      DatabaseManager.isDatabaseEncrypted &&
      _encryptDatabaseStatus == EncryptDatabaseStatus.defaultPassword;

  bool get _autoLockAvailable =>
      _gesturePasswdAvailableAndSet || _encryptedAndCustomPassword;

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.safeSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        if (!DatabaseManager.isDatabaseEncrypted) ...[
          const SizedBox(height: 10),
          TipBanner(message: appLocalizations.databaseNotEncrypted),
        ],
        if (DatabaseManager.isDatabaseEncrypted) _databaseSettings(),
        _gestureSettings(),
        if (_autoLockAvailable) _autoLockSettings(),
        if (ResponsiveUtil.isMobile()) _safeModeSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  _gestureSettings() {
    return CaptionItem(
      title: appLocalizations.gestureLockSettings,
      children: [
        const SizedBox(height: 10),
        CheckboxItem(
          disabled: _encryptedAndCustomPassword,
          value: _enableGuesturePasswd,
          title: appLocalizations.enableGestureLock,
          description: appLocalizations.enableGestureLockTip,
          onTap: onEnablePinTapped,
        ),
        Visibility(
          visible: _geusturePasswdAvailable,
          child: EntryItem(
            title: _hasGuesturePasswd
                ? appLocalizations.changeGestureLock
                : appLocalizations.setGestureLock,
            description: _hasGuesturePasswd
                ? ""
                : appLocalizations.haveToSetGestureLockTip,
            onTap: onChangePinTapped,
          ),
        ),
        Visibility(
          visible: _gesturePasswdAvailableAndSet && _biometricAvailable,
          child: CheckboxItem(
            value: _allowGuestureBiometric,
            title: appLocalizations.biometricUnlock,
            disabled: canAuthenticateResponse?.isSuccess != true,
            description: canAuthenticateResponseString ??
                appLocalizations.biometricUnlockTip,
            onTap: onBiometricTapped,
          ),
        ),
      ],
    );
  }

  _databaseSettings() {
    return CaptionItem(
      title: appLocalizations.databaseEncryptionSettings,
      children: [
        Visibility(
          visible: DatabaseManager.isDatabaseEncrypted,
          child: EntryItem(
            title: appLocalizations.editEncryptDatabasePassword,
            description: appLocalizations.encryptDatabaseTip,
            tip: _encryptDatabaseStatus == EncryptDatabaseStatus.defaultPassword
                ? appLocalizations.defaultEncryptDatabasePassword
                : appLocalizations.customEncryptDatabasePassword,
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                useWideLandscape: true,
                (context) => InputPasswordBottomSheet(
                  title: appLocalizations.editEncryptDatabasePassword,
                  message: appLocalizations.editEncryptDatabasePasswordTip,
                  onConfirm: (passord, confirmPassword) async {},
                  onValidConfirm: (passord, confirmPassword) async {
                    bool res = await DatabaseManager.changePassword(passord);
                    if (res) {
                      IToast.showTop(appLocalizations.editSuccess);
                      CloudOTPHiveUtil.setEncryptDatabaseStatus(
                          EncryptDatabaseStatus.customPassword);
                      setState(() {
                        _encryptDatabaseStatus =
                            EncryptDatabaseStatus.customPassword;
                      });
                      if (_biometricAvailable && _allowDatabaseBiometric) {
                        _allowDatabaseBiometric =
                            await BiometricUtil.setDatabasePassword(
                                appProvider.currentDatabasePassword);
                        setState(() {});
                        ChewieHiveUtil.put(
                            CloudOTPHiveUtil.allowDatabaseBiometricKey,
                            _allowDatabaseBiometric);
                      }
                    } else {
                      IToast.showTop(appLocalizations.editFailed);
                    }
                  },
                ),
              );
            },
          ),
        ),
        Visibility(
          visible: _encryptedAndCustomPassword,
          child: EntryItem(
            title: appLocalizations.clearEncryptDatabasePassword,
            description: appLocalizations.clearEncryptDatabasePasswordTip,
            trailing: LucideIcons.refreshCcw,
            onTap: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.clearEncryptDatabasePassword,
                message: appLocalizations.clearEncryptDatabasePasswordTip,
                onTapConfirm: () async {
                  bool res = await DatabaseManager.changePassword(
                      await CloudOTPHiveUtil.regeneratePassword());
                  if (res) {
                    CloudOTPHiveUtil.setEncryptDatabaseStatus(
                        EncryptDatabaseStatus.defaultPassword);
                    setState(() {
                      _encryptDatabaseStatus =
                          EncryptDatabaseStatus.defaultPassword;
                    });
                    if (_biometricAvailable && _allowDatabaseBiometric) {
                      await BiometricUtil.clearDatabasePassword();
                    }
                    IToast.showTop(
                        appLocalizations.clearEncryptDatabasePasswordSuccess);
                  } else {
                    IToast.showTop(
                        appLocalizations.clearEncryptDatabasePasswordFailed);
                  }
                },
                onTapCancel: () {},
              );
            },
          ),
        ),
        Visibility(
          visible: _encryptedAndCustomPassword && _biometricAvailable,
          child: CheckboxItem(
            value: _allowDatabaseBiometric,
            disabled: canAuthenticateResponse?.isSuccess != true,
            description: canAuthenticateResponseString ??
                appLocalizations.biometricDecryptDatabaseTip,
            title: appLocalizations.biometricDecryptDatabase,
            onTap: () async {
              if (canAuthenticateResponse != CanAuthenticateResponse.success) {
                return;
              }
              if (!_allowDatabaseBiometric) {
                _allowDatabaseBiometric =
                    await BiometricUtil.setDatabasePassword(
                        appProvider.currentDatabasePassword);
                if (_allowDatabaseBiometric) {
                  IToast.showTop(appLocalizations.enableBiometricSuccess);
                } else {
                  IToast.showTop(appLocalizations.biometricError);
                }
                setState(() {});
              } else {
                _allowDatabaseBiometric = false;
                setState(() {});
              }
              ChewieHiveUtil.put(CloudOTPHiveUtil.allowDatabaseBiometricKey,
                  _allowDatabaseBiometric);
            },
          ),
        ),
      ],
    );
  }

  _autoLockSettings() {
    return CaptionItem(
      title: appLocalizations.autoLockSettings,
      children: [
        CheckboxItem(
          value: _autoLock,
          title: appLocalizations.autoLock,
          description: appLocalizations.autoLockTip,
          onTap: onEnableAutoLockTapped,
        ),
        Visibility(
          visible: _autoLock,
          child: Selector<AppProvider, AutoLockTime>(
            selector: (context, appProvider) => appProvider.autoLockTime,
            builder: (context, autoLockTime, child) =>
                InlineSelectionItem<AutoLockOption>(
              title: appLocalizations.autoLockDelay,
              hint: appLocalizations.chooseAutoLockDelay,
              selections: AutoLockOption.getOptions(),
              selected: AutoLockOption.fromAutoLockTime(autoLockTime),
              onChanged: (autoLockOption) {
                if (autoLockOption == null) return;
                appProvider.autoLockTime = autoLockOption.autoLockTime;
                ChewieHiveUtil.put(CloudOTPHiveUtil.autoLockTimeKey,
                    autoLockOption.autoLockTime);
              },
            ),
          ),
        ),
      ],
    );
  }

  _safeModeSettings() {
    return CaptionItem(
      title: appLocalizations.safeMode,
      children: [
        CheckboxItem(
          value: _enableSafeMode,
          title: appLocalizations.safeMode,
          disabled: ResponsiveUtil.isDesktop(),
          description: appLocalizations.safeModeTip,
          onTap: onSafeModeTapped,
        ),
      ],
    );
  }

  initBiometricAuthentication() async {
    canAuthenticateResponse = await BiometricUtil.canAuthenticate();
    canAuthenticateResponseString =
        await BiometricUtil.getCanAuthenticateResponseString();
    bool exist = await BiometricUtil.exists();
    if (!exist) {
      _allowDatabaseBiometric = false;
      ChewieHiveUtil.put(
          CloudOTPHiveUtil.allowDatabaseBiometricKey, _allowDatabaseBiometric);
    }
    setState(() {});
  }

  onEnablePinTapped() {
    setState(() {
      RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            setState(() {
              _enableGuesturePasswd = !_enableGuesturePasswd;
              IToast.showTop(_enableGuesturePasswd
                  ? appLocalizations.enableGestureLockSuccess
                  : appLocalizations.disableGestureLockSuccess);
              ChewieHiveUtil.put(CloudOTPHiveUtil.enableGuesturePasswdKey,
                  _enableGuesturePasswd);
              _hasGuesturePasswd = ChewieHiveUtil.getString(
                          CloudOTPHiveUtil.guesturePasswdKey) !=
                      null &&
                  ChewieHiveUtil.getString(CloudOTPHiveUtil.guesturePasswdKey)!
                      .isNotEmpty;
            });
          },
          isModal: false,
        ),
      );
    });
  }

  onBiometricTapped() {
    if (!_allowGuestureBiometric) {
      RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            IToast.showTop(appLocalizations.enableBiometricSuccess);
            setState(() {
              _allowGuestureBiometric = !_allowGuestureBiometric;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.enableBiometricKey, _allowGuestureBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _allowGuestureBiometric = !_allowGuestureBiometric;
        ChewieHiveUtil.put(
            CloudOTPHiveUtil.enableBiometricKey, _allowGuestureBiometric);
      });
    }
  }

  onChangePinTapped() {
    setState(() {
      RouteUtil.pushCupertinoRoute(
        context,
        const PinChangeScreen(),
        onThen: (value) {
          setState(() {
            _hasGuesturePasswd = ChewieHiveUtil.getString(
                        CloudOTPHiveUtil.guesturePasswdKey) !=
                    null &&
                ChewieHiveUtil.getString(CloudOTPHiveUtil.guesturePasswdKey)!
                    .isNotEmpty;
          });
        },
      );
    });
  }

  onEnableAutoLockTapped() {
    setState(() {
      _autoLock = !_autoLock;
      ChewieHiveUtil.put(CloudOTPHiveUtil.autoLockKey, _autoLock);
    });
  }

  onSafeModeTapped() {
    setState(() {
      _enableSafeMode = !_enableSafeMode;
      ChewieUtils.setSafeMode(_enableSafeMode);
      ChewieHiveUtil.put(CloudOTPHiveUtil.enableSafeModeKey, _enableSafeMode);
    });
  }
}
