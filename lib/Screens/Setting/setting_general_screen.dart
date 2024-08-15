import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:cloudotp/TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/input_password_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloudotp/Utils/Tuple/tuple.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Database/database_manager.dart';
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
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => _GeneralSettingScreenState();
}

class _GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet =
  HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey, defaultValue: true);
  FontEnum _currentFont = FontEnum.getCurrentFont();
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

  bool hideAppbarWhenScrolling =
  HiveUtil.getBool(HiveUtil.hideAppbarWhenScrollingKey);
  bool hideBottombarWhenScrolling =
  HiveUtil.getBool(HiveUtil.hideBottombarWhenScrollingKey);
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
  }

  scrollToSetAutoBackupPassword() {
    if (_setAutoBackupPasswordKey.currentContext != null) {
      Scrollable.ensureVisible(
        _setAutoBackupPasswordKey.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
          title: S.current.generalSetting,
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
            S.current.setting,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.apply(fontWeightDelta: 2),
          ),
          center: true,
          actions: [
            ItemBuilder.buildBlankIconButton(context),
            const SizedBox(width: 5),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              ..._generalSettings(),
              ..._apperanceSettings(),
              if (ResponsiveUtil.isDesktop()) ..._desktopSettings(),
              if (ResponsiveUtil.isMobile()) ..._mobileSettings(),
              const SizedBox(height: 30),
            ],
          ),
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
        selector: (context, appProvider) => appProvider.themeMode,
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
        tip: _currentFont.intlFontName,
        bottomRadius: true,
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

  _generalSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.generalSetting),
      Selector<AppProvider, Locale?>(
        selector: (context, appProvider) => appProvider.locale,
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
        context: context,
        value: hideAppbarWhenScrolling,
        title: S.current.hideAppbarWhenScrolling,
        onTap: () {
          setState(() {
            hideAppbarWhenScrolling = !hideAppbarWhenScrolling;
            appProvider.hideAppbarWhenScrolling = hideAppbarWhenScrolling;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: hideBottombarWhenScrolling,
        title: S.current.hideBottombarWhenScrolling,
        onTap: () {
          setState(() {
            hideBottombarWhenScrolling = !hideBottombarWhenScrolling;
            appProvider.hideBottombarWhenScrolling = hideBottombarWhenScrolling;
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
}
