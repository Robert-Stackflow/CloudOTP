import 'package:biometric_storage/biometric_storage.dart';
import 'package:cloudotp/Utils/biometric_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_password_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';

import '../../Database/database_manager.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';

class SafeSettingScreen extends StatefulWidget {
  const SafeSettingScreen({super.key});

  static const String routeName = "/setting/privacy";

  @override
  State<SafeSettingScreen> createState() => _SafeSettingScreenState();
}

class _SafeSettingScreenState extends State<SafeSettingScreen>
    with TickerProviderStateMixin {
  bool _enableGuesturePasswd =
      HiveUtil.getBool(HiveUtil.enableGuesturePasswdKey);
  bool _hasGuesturePasswd =
      Utils.isNotEmpty(HiveUtil.getString(HiveUtil.guesturePasswdKey));
  bool _autoLock = HiveUtil.getBool(HiveUtil.autoLockKey);
  bool _enableSafeMode = HiveUtil.getBool(HiveUtil.enableSafeModeKey,
      defaultValue: defaultEnableSafeMode);
  bool _allowGuestureBiometric = HiveUtil.getBool(HiveUtil.enableBiometricKey);
  bool _allowDatabaseBiometric =
      HiveUtil.getBool(HiveUtil.allowDatabaseBiometricKey, defaultValue: false);
  EncryptDatabaseStatus _encryptDatabaseStatus =
      HiveUtil.getEncryptDatabaseStatus();
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
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.safeSetting,
                context: context,
                transparent: true,
              )
            : ItemBuilder.buildAppBar(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  S.current.safeSetting,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
                actions: [
                  ItemBuilder.buildBlankIconButton(context),
                  const SizedBox(width: 5),
                ],
              ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ..._databaseSettings(),
              ..._gestureSettings(),
              if (_autoLockAvailable) ..._autoLockSettings(),
              ..._safeModeSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _gestureSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        topRadius: true,
        disabled: _encryptedAndCustomPassword,
        value: _enableGuesturePasswd,
        title: S.current.enableGestureLock,
        bottomRadius: !_geusturePasswdAvailable,
        description: S.current.enableGestureLockTip,
        onTap: onEnablePinTapped,
      ),
      Visibility(
        visible: _geusturePasswdAvailable,
        child: ItemBuilder.buildEntryItem(
          context: context,
          bottomRadius: !_gesturePasswdAvailableAndSet || !_biometricAvailable,
          title: _hasGuesturePasswd
              ? S.current.changeGestureLock
              : S.current.setGestureLock,
          description:
              _hasGuesturePasswd ? "" : S.current.haveToSetGestureLockTip,
          onTap: onChangePinTapped,
        ),
      ),
      Visibility(
        visible: _gesturePasswdAvailableAndSet && _biometricAvailable,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _allowGuestureBiometric,
          title: S.current.biometricUnlock,
          bottomRadius: true,
          disabled: canAuthenticateResponse?.isSuccess != true,
          description:
              canAuthenticateResponseString ?? S.current.biometricUnlockTip,
          onTap: onBiometricTapped,
        ),
      ),
    ];
  }

  _databaseSettings() {
    return [
      Visibility(
        visible: DatabaseManager.isDatabaseEncrypted,
        child: ItemBuilder.buildEntryItem(
          context: context,
          topRadius: true,
          bottomRadius: _encryptedAndDefaultPassword,
          title: S.current.editEncryptDatabasePassword,
          description: S.current.encryptDatabaseTip,
          tip: _encryptDatabaseStatus == EncryptDatabaseStatus.defaultPassword
              ? S.current.defaultEncryptDatabasePassword
              : S.current.customEncryptDatabasePassword,
          onTap: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              useWideLandscape: true,
              (context) => InputPasswordBottomSheet(
                title: S.current.editEncryptDatabasePassword,
                message: S.current.editEncryptDatabasePasswordTip,
                onConfirm: (passord, confirmPassword) async {},
                onValidConfirm: (passord, confirmPassword) async {
                  bool res = await DatabaseManager.changePassword(passord);
                  if (res) {
                    IToast.showTop(S.current.editSuccess);
                    HiveUtil.setEncryptDatabaseStatus(
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
                      HiveUtil.put(HiveUtil.allowDatabaseBiometricKey,
                          _allowDatabaseBiometric);
                    }
                  } else {
                    IToast.showTop(S.current.editFailed);
                  }
                },
              ),
            );
          },
        ),
      ),
      Visibility(
        visible: _encryptedAndCustomPassword,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.clearEncryptDatabasePassword,
          description: S.current.clearEncryptDatabasePasswordTip,
          bottomRadius: !_biometricAvailable,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.clearEncryptDatabasePassword,
              message: S.current.clearEncryptDatabasePasswordTip,
              onTapConfirm: () async {
                bool res = await DatabaseManager.changePassword(
                    await HiveUtil.regeneratePassword());
                if (res) {
                  HiveUtil.setEncryptDatabaseStatus(
                      EncryptDatabaseStatus.defaultPassword);
                  setState(() {
                    _encryptDatabaseStatus =
                        EncryptDatabaseStatus.defaultPassword;
                  });
                  if (_biometricAvailable && _allowDatabaseBiometric) {
                    await BiometricUtil.clearDatabasePassword();
                  }
                  IToast.showTop(S.current.clearEncryptDatabasePasswordSuccess);
                } else {
                  IToast.showTop(S.current.clearEncryptDatabasePasswordFailed);
                }
              },
              onTapCancel: () {},
            );
          },
        ),
      ),
      Visibility(
        visible: _encryptedAndCustomPassword && _biometricAvailable,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _allowDatabaseBiometric,
          disabled: canAuthenticateResponse?.isSuccess != true,
          bottomRadius: true,
          description: canAuthenticateResponseString ??
              S.current.biometricDecryptDatabaseTip,
          title: S.current.biometricDecryptDatabase,
          onTap: () async {
            if (canAuthenticateResponse != CanAuthenticateResponse.success) {
              return;
            }
            if (!_allowDatabaseBiometric) {
              _allowDatabaseBiometric = await BiometricUtil.setDatabasePassword(
                  appProvider.currentDatabasePassword);
              if (_allowDatabaseBiometric) {
                IToast.showTop(S.current.enableBiometricSuccess);
              }
              setState(() {});
            } else {
              _allowDatabaseBiometric = false;
              setState(() {});
            }
            HiveUtil.put(
                HiveUtil.allowDatabaseBiometricKey, _allowDatabaseBiometric);
          },
        ),
      ),
    ];
  }

  _autoLockSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        bottomRadius: !_autoLock,
        topRadius: true,
        context: context,
        value: _autoLock,
        title: S.current.autoLock,
        description: S.current.autoLockTip,
        onTap: onEnableAutoLockTapped,
      ),
      Visibility(
        visible: _autoLock,
        child: Selector<AppProvider, AutoLockTime>(
          selector: (context, appProvider) => appProvider.autoLockTime,
          builder: (context, autoLockTime, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: S.current.autoLockDelay,
            bottomRadius: true,
            tip: autoLockTime.label,
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (context) => TileList.fromOptions(
                  AutoLockTime.options(),
                  (item2) {
                    appProvider.autoLockTime = item2;
                    Navigator.pop(context);
                  },
                  selected: autoLockTime,
                  context: context,
                  title: S.current.chooseAutoLockDelay,
                  onCloseTap: () => Navigator.pop(context),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }

  _safeModeSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _enableSafeMode,
        topRadius: true,
        bottomRadius: true,
        title: S.current.safeMode,
        disabled: ResponsiveUtil.isDesktop(),
        description: S.current.safeModeTip,
        onTap: onSafeModeTapped,
      ),
    ];
  }

  initBiometricAuthentication() async {
    canAuthenticateResponse = await BiometricUtil.canAuthenticate();
    canAuthenticateResponseString =
        await BiometricUtil.getCanAuthenticateResponseString();
    bool exist = await BiometricUtil.exists();
    if (!exist) {
      _allowDatabaseBiometric = false;
      HiveUtil.put(HiveUtil.allowDatabaseBiometricKey, _allowDatabaseBiometric);
    }
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
                  ? S.current.enableGestureLockSuccess
                  : S.current.disableGestureLockSuccess);
              HiveUtil.put(
                  HiveUtil.enableGuesturePasswdKey, _enableGuesturePasswd);
              _hasGuesturePasswd =
                  HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
                      HiveUtil.getString(HiveUtil.guesturePasswdKey)!
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
            IToast.showTop(S.current.enableBiometricSuccess);
            setState(() {
              _allowGuestureBiometric = !_allowGuestureBiometric;
              HiveUtil.put(
                  HiveUtil.enableBiometricKey, _allowGuestureBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _allowGuestureBiometric = !_allowGuestureBiometric;
        HiveUtil.put(HiveUtil.enableBiometricKey, _allowGuestureBiometric);
      });
    }
  }

  onChangePinTapped() {
    setState(() {
      RouteUtil.pushCupertinoRoute(context, const PinChangeScreen())
          .then((value) {
        setState(() {
          _hasGuesturePasswd =
              HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
                  HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
        });
      });
    });
  }

  onEnableAutoLockTapped() {
    setState(() {
      _autoLock = !_autoLock;
      HiveUtil.put(HiveUtil.autoLockKey, _autoLock);
    });
  }

  onSafeModeTapped() {
    setState(() {
      _enableSafeMode = !_enableSafeMode;
      if (ResponsiveUtil.isMobile()) {
        if (_enableSafeMode) {
          FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        } else {
          FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        }
      }
      HiveUtil.put(HiveUtil.enableSafeModeKey, _enableSafeMode);
    });
  }
}
