import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/token_dao.dart';
import '../../Models/github_response.dart';
import '../../Resources/fonts.dart';
import '../../Resources/theme_color_data.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cache_util.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/locale_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  static const String routeName = "/setting";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey, defaultValue: true);
  FontEnum _currentFont = FontEnum.getCurrentFont();
  bool _enableGuesturePasswd =
      HiveUtil.getBool(HiveUtil.enableGuesturePasswdKey);
  bool _autoBackup = HiveUtil.getBool(HiveUtil.autoBackupKey);
  bool _useBackupPasswordToExportImport =
      HiveUtil.getBool(HiveUtil.useBackupPasswordToExportImportKey);
  bool _hasGuesturePasswd =
      HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
          HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
  bool _autoLock = HiveUtil.getBool(HiveUtil.autoLockKey);
  bool _enableSafeMode = HiveUtil.getBool(HiveUtil.enableSafeModeKey);
  bool _enableBiometric = HiveUtil.getBool(HiveUtil.enableBiometricKey);
  bool _biometricAvailable = false;
  bool enableMinimizeToTray = HiveUtil.getBool(HiveUtil.enableCloseToTrayKey);
  bool recordWindowState = HiveUtil.getBool(HiveUtil.recordWindowStateKey);
  bool enableCloseNotice = HiveUtil.getBool(HiveUtil.enableCloseNoticeKey);
  List<Tuple2<String, Locale?>> _supportedLocaleTuples = [];
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = HiveUtil.getBool(HiveUtil.autoCheckUpdateKey);
  String _cacheSize = "";
  bool inAppBrowser = HiveUtil.getBool(HiveUtil.inappWebviewKey);
  bool clipToCopy = HiveUtil.getBool(HiveUtil.clickToCopyKey);
  bool autoDisplayNextCode = HiveUtil.getBool(HiveUtil.autoDisplayNextCodeKey);
  bool autoCopyNextCode = HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey);
  bool autoHideCode = HiveUtil.getBool(HiveUtil.autoHideCodeKey);
  String _autoBackupPath = HiveUtil.getString(HiveUtil.backupPathKey) ?? "";
  String _autoBackupPassword =
      HiveUtil.getString(HiveUtil.backupPasswordKey) ?? "";

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.setting, context: context, transparent: true),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: [
            ..._generalSettings(),
            ..._apperanceSettings(),
            ..._operationSettings(),
            ..._backupSettings(),
            ..._privacySettings(),
            if (ResponsiveUtil.isDesktop()) ..._desktopSettings(),
            if (ResponsiveUtil.isMobile()) ..._mobileSettings(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  _apperanceSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.themeSetting),
      Selector<AppProvider, ActiveThemeMode>(
        selector: (context, globalProvider) => globalProvider.themeMode,
        builder: (context, themeMode, child) => ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.themeMode,
          tip: AppProvider.getThemeModeLabel(themeMode),
          onTap: () {
            BottomSheetBuilder.showListBottomSheet(
              context,
              (context) => TileList.fromOptions(
                AppProvider.getSupportedThemeMode(),
                (item2) {
                  appProvider.themeMode = item2;
                  Navigator.pop(context);
                },
                selected: themeMode,
                context: context,
                title: S.current.chooseThemeMode,
                onCloseTap: () => Navigator.pop(context),
              ),
            );
          },
        ),
      ),
      Selector<AppProvider, ThemeColorData>(
        selector: (context, appProvider) => appProvider.lightTheme,
        builder: (context, lightTheme, child) =>
            Selector<AppProvider, ThemeColorData>(
          selector: (context, appProvider) => appProvider.darkTheme,
          builder: (context, darkTheme, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: S.current.selectTheme,
            tip: "${lightTheme.intlName}/${darkTheme.intlName}",
            onTap: () {
              RouteUtil.pushCupertinoRoute(context, const SelectThemeScreen());
            },
          ),
        ),
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.fontFamily,
        bottomRadius: true,
        tip: _currentFont.intlFontName,
        onTap: () {
          BottomSheetBuilder.showListBottomSheet(
            context,
            (sheetContext) => TileList.fromOptions(
              FontEnum.getFontList(),
              (item2) async {
                FontEnum t = item2 as FontEnum;
                _currentFont = t;
                Navigator.pop(sheetContext);
                setState(() {});
                FontEnum.loadFont(context, t, autoRestartApp: true);
              },
              selected: _currentFont,
              context: context,
              title: S.current.chooseFontFamily,
              onCloseTap: () => Navigator.pop(context),
            ),
          );
        },
      ),
    ];
  }

  _operationSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.operationSetting),
      ItemBuilder.buildRadioItem(
        context: context,
        value: clipToCopy,
        title: S.current.clickToCopy,
        description: S.current.clickToCopyTip,
        onTap: () {
          setState(() {
            clipToCopy = !clipToCopy;
            HiveUtil.put(HiveUtil.clickToCopyKey, clipToCopy);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoDisplayNextCode,
        title: S.current.autoDisplayNextCode,
        description: S.current.autoDisplayNextCodeTip,
        onTap: () {
          setState(() {
            autoDisplayNextCode = !autoDisplayNextCode;
            HiveUtil.put(HiveUtil.autoDisplayNextCodeKey, autoDisplayNextCode);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        disabled: !clipToCopy,
        value: autoCopyNextCode,
        title: S.current.autoCopyNextCode,
        description: S.current.autoCopyNextCodeTip,
        onTap: () {
          setState(() {
            autoCopyNextCode = !autoCopyNextCode;
            HiveUtil.put(HiveUtil.autoCopyNextCodeKey, autoCopyNextCode);
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoHideCode,
        title: S.current.autoHideCode,
        description: S.current.autoHideCodeTip,
        onTap: () {
          setState(() {
            autoHideCode = !autoHideCode;
            HiveUtil.put(HiveUtil.autoHideCodeKey, autoHideCode);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        bottomRadius: true,
        title: S.current.resetCopyTimes,
        description: S.current.resetCopyTimesTip,
        onTap: () async {
          await TokenDao.resetTokenCopyTimes();
          homeScreenState?.refresh();
          IToast.showTop(S.current.resetSuccess);
        },
      ),
    ];
  }

  _backupSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.backupSetting),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _autoBackup,
        title: S.current.autoBackup,
        description: S.current.autoBackupTip,
        disabled: _autoBackupPath.isEmpty || _autoBackupPassword.isEmpty,
        onTap: () {
          setState(() {
            _autoBackup = !_autoBackup;
            HiveUtil.put(HiveUtil.autoBackupKey, _autoBackup);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.autoBackupPath,
        description: S.current.autoBackupPathTip,
        tip: _autoBackupPath,
        onTap: () {},
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.autoBackupPassword,
        description: S.current.autoBackupPasswordTip,
        tip: _autoBackupPassword,
        onTap: () {},
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _useBackupPasswordToExportImport,
        bottomRadius: true,
        title: S.current.useBackupPasswordToExportImport,
        description: S.current.useBackupPasswordToExportImportTip,
        disabled: _autoBackupPassword.isEmpty,
        onTap: () {
          setState(() {
            _useBackupPasswordToExportImport =
                !_useBackupPasswordToExportImport;
            HiveUtil.put(HiveUtil.useBackupPasswordToExportImportKey,
                _useBackupPasswordToExportImport);
          });
        },
      ),
    ];
  }

  _privacySettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.privacySetting),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _enableGuesturePasswd,
        title: S.current.enableGestureLock,
        onTap: onEnablePinTapped,
      ),
      Visibility(
        visible: _enableGuesturePasswd,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: _hasGuesturePasswd
              ? S.current.changeGestureLock
              : S.current.setGestureLock,
          description:
              _hasGuesturePasswd ? "" : S.current.haveToSetGestureLockTip,
          onTap: onChangePinTapped,
        ),
      ),
      Visibility(
        visible:
            _enableGuesturePasswd && _hasGuesturePasswd && _biometricAvailable,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _enableBiometric,
          disabled: ResponsiveUtil.isMacOS() || ResponsiveUtil.isLinux(),
          title: S.current.biometric,
          description: S.current.biometricTip,
          onTap: onBiometricTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _autoLock,
          title: S.current.autoLock,
          description: S.current.autoLockTip,
          onTap: onEnableAutoLockTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd && _autoLock,
        child: Selector<AppProvider, int>(
          selector: (context, globalProvider) => globalProvider.autoLockTime,
          builder: (context, autoLockTime, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: S.current.autoLockDelay,
            tip: AppProvider.getAutoLockOptionLabel(autoLockTime),
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (context) => TileList.fromOptions(
                  AppProvider.getAutoLockOptions(),
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
      ItemBuilder.buildRadioItem(
        context: context,
        value: _enableSafeMode,
        title: S.current.safeMode,
        disabled: ResponsiveUtil.isDesktop(),
        bottomRadius: true,
        description: S.current.safeModeTip,
        onTap: onSafeModeTapped,
      ),
    ];
  }

  _generalSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.generalSetting),
      Selector<AppProvider, Locale?>(
        selector: (context, globalProvider) => globalProvider.locale,
        builder: (context, locale, child) => ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.language,
          tip: LocaleUtil.getLabel(locale)!,
          onTap: () {
            filterLocale();
            BottomSheetBuilder.showListBottomSheet(
              context,
              (context) => TileList.fromOptions(
                _supportedLocaleTuples,
                (item2) {
                  appProvider.locale = item2;
                  Navigator.pop(context);
                },
                selected: locale,
                context: context,
                title: S.current.chooseLanguage,
                onCloseTap: () => Navigator.pop(context),
              ),
            );
          },
        ),
      ),
      ItemBuilder.buildRadioItem(
        value: autoCheckUpdate,
        context: context,
        title: S.current.autoCheckUpdates,
        onTap: () {
          setState(() {
            autoCheckUpdate = !autoCheckUpdate;
            HiveUtil.put(HiveUtil.autoCheckUpdateKey, autoCheckUpdate);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.checkUpdates,
        bottomRadius: true,
        description: Utils.compareVersion(latestVersion, currentVersion) > 0
            ? S.current.newVersion(latestVersion)
            : S.current.alreadyLatestVersion,
        descriptionColor:
            Utils.compareVersion(latestVersion, currentVersion) > 0
                ? Colors.redAccent
                : null,
        tip: currentVersion,
        onTap: () {
          fetchReleases(true);
        },
      ),
    ];
  }

  _desktopSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.desktopSetting),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.closeWindowOption,
        tip:
            enableMinimizeToTray ? S.current.minimizeToTray : S.current.exitApp,
        onTap: () {
          List<Tuple2<String, dynamic>> options = [
            Tuple2(S.current.minimizeToTray, 0),
            Tuple2(S.current.exitApp, 1),
          ];
          BottomSheetBuilder.showListBottomSheet(
            context,
            (sheetContext) => TileList.fromOptions(
              options,
              (idx) {
                Navigator.pop(sheetContext);
                if (idx == 0) {
                  setState(() {
                    enableMinimizeToTray = true;
                    HiveUtil.put(
                        HiveUtil.enableCloseToTrayKey, enableMinimizeToTray);
                  });
                } else if (idx == 1) {
                  setState(() {
                    enableMinimizeToTray = false;
                    HiveUtil.put(
                        HiveUtil.enableCloseToTrayKey, enableMinimizeToTray);
                  });
                }
              },
              selected: enableMinimizeToTray ? 0 : 1,
              title: S.current.chooseCloseWindowOption,
              context: context,
              onCloseTap: () => Navigator.pop(sheetContext),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          );
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.autoMemoryWindowPositionAndSize,
        value: recordWindowState,
        description: S.current.autoMemoryWindowPositionAndSizeTip,
        bottomRadius: true,
        onTap: () async {
          setState(() {
            recordWindowState = !recordWindowState;
            HiveUtil.put(HiveUtil.recordWindowStateKey, recordWindowState);
          });
          HiveUtil.setWindowSize(await windowManager.getSize());
          HiveUtil.setWindowPosition(await windowManager.getPosition());
        },
      ),
    ];
  }

  _mobileSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.mobileSetting),
      if (ResponsiveUtil.isTablet())
        ItemBuilder.buildRadioItem(
          value: _enableLandscapeInTablet,
          context: context,
          title: S.current.useDesktopLayoutWhenLandscape,
          description: S.current.haveToRestartWhenChange,
          onTap: () {
            setState(() {
              _enableLandscapeInTablet = !_enableLandscapeInTablet;
              appProvider.enableLandscapeInTablet = _enableLandscapeInTablet;
            });
          },
        ),
      ItemBuilder.buildRadioItem(
        value: inAppBrowser,
        context: context,
        title: S.current.inAppBrowser,
        onTap: () {
          setState(() {
            inAppBrowser = !inAppBrowser;
            HiveUtil.put(HiveUtil.inappWebviewKey, inAppBrowser);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.clearCache,
        bottomRadius: true,
        tip: _cacheSize,
        onTap: () {
          CustomLoadingDialog.showLoading(title: S.current.clearingCache);
          getTemporaryDirectory().then((tempDir) {
            CacheUtil.delDir(tempDir).then((value) {
              CacheUtil.loadCache().then((value) {
                setState(() {
                  _cacheSize = value;
                  CustomLoadingDialog.dismissLoading();
                  IToast.showTop(S.current.clearCacheSuccess);
                });
              });
            });
          });
        },
      ),
    ];
  }

  void getCacheSize() {
    CacheUtil.loadCache().then((value) {
      setState(() {
        _cacheSize = value;
      });
    });
  }

  void filterLocale() {
    _supportedLocaleTuples = [];
    List<Locale> locales = S.delegate.supportedLocales;
    _supportedLocaleTuples.add(Tuple2(S.current.followSystem, null));
    for (Locale locale in locales) {
      dynamic tuple = LocaleUtil.getTuple(locale);
      if (tuple != null) {
        _supportedLocaleTuples.add(tuple);
      }
    }
  }

  Future<void> fetchReleases(bool showTip) async {
    setState(() {});
    Utils.getReleases(
      context: context,
      showLoading: showTip,
      showUpdateDialog: showTip,
      showNoUpdateToast: showTip,
      onGetCurrentVersion: (currentVersion) {
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        setState(() {
          this.latestVersion = latestVersion;
          this.latestReleaseItem = latestReleaseItem;
        });
      },
    );
  }

  initBiometricAuthentication() async {
    LocalAuthentication localAuth = LocalAuthentication();
    bool available = await localAuth.canCheckBiometrics;
    setState(() {
      _biometricAvailable = available;
    });
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
    if (!_enableBiometric) {
      RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            IToast.showTop(S.current.enableBiometricSuccess);
            setState(() {
              _enableBiometric = !_enableBiometric;
              HiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _enableBiometric = !_enableBiometric;
        HiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
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
