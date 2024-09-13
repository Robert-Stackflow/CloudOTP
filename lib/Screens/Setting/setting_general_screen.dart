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

import 'package:cloudotp/Utils/Tuple/tuple.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/ilogger.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/github_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/cache_util.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/locale_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => GeneralSettingScreenState();
}

class GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  bool enableMinimizeToTray = HiveUtil.getBool(HiveUtil.enableCloseToTrayKey);
  bool launchAtStartup = HiveUtil.getBool(HiveUtil.launchAtStartupKey);
  bool recordWindowState = HiveUtil.getBool(HiveUtil.recordWindowStateKey);
  bool showTray = HiveUtil.getBool(HiveUtil.showTrayKey);
  bool enableCloseNotice = HiveUtil.getBool(HiveUtil.enableCloseNoticeKey);
  List<Tuple2<String, Locale?>> _supportedLocaleTuples = [];
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate = HiveUtil.getBool(HiveUtil.autoCheckUpdateKey);
  String _cacheSize = "";
  String _logSize = "";
  bool inAppBrowser = HiveUtil.getBool(HiveUtil.inappWebviewKey);

  @override
  void initState() {
    super.initState();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
    getLogSize();
  }

  refreshLauchAtStartup() {
    setState(() {
      launchAtStartup = HiveUtil.getBool(HiveUtil.launchAtStartupKey);
    });
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
                  S.current.generalSetting,
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
              ..._generalSettings(),
              if (ResponsiveUtil.isDesktop()) ..._desktopSettings(),
              if (ResponsiveUtil.isMobile()) ..._mobileSettings(),
              ..._logSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _generalSettings() {
    return [
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
                  Utils.initTray();
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

  _logSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.exportLog,
        description: S.current.exportLogHint,
        topRadius: true,
        onTap: () {
          FileUtil.exportLogs();
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.clearLog,
        bottomRadius: true,
        tip: _logSize,
        onTap: () async {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.clearLogTitle,
            message: S.current.clearLogHint,
            onTapConfirm: () async {
              CustomLoadingDialog.showLoading(title: S.current.clearingLog);
              try {
                await FileOutput.clearLogs();
                await getLogSize();
                IToast.showTop(S.current.clearLogSuccess);
              } catch (e, t) {
                ILogger.error("CloudOTP","Failed to clear logs", e, t);
                IToast.showTop(S.current.clearLogFailed);
              } finally {
                CustomLoadingDialog.dismissLoading();
              }
            },
          );
        },
      ),
    ];
  }

  _desktopSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.desktopSetting),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.launchAtStartup,
        value: launchAtStartup,
        onTap: () async {
          setState(() {
            launchAtStartup = !launchAtStartup;
            HiveUtil.put(HiveUtil.launchAtStartupKey, launchAtStartup);
          });
          if (launchAtStartup) {
            await LaunchAtStartup.instance.enable();
          } else {
            await LaunchAtStartup.instance.disable();
          }
          Utils.initTray();
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showTray,
        value: showTray,
        onTap: () async {
          setState(() {
            showTray = !showTray;
            HiveUtil.put(HiveUtil.showTrayKey, showTray);
            if (showTray) {
              Utils.initTray();
            } else {
              Utils.removeTray();
            }
          });
        },
      ),
      Visibility(
        visible: showTray,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.closeWindowOption,
          tip: enableMinimizeToTray
              ? S.current.minimizeToTray
              : S.current.exitApp,
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

  Future<void> getLogSize() async {
    double size = await FileOutput.getLogsSize();
    setState(() {
      _logSize = CacheUtil.renderSize(size);
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
        if (mounted) {
          setState(() {
            this.currentVersion = currentVersion;
          });
        }
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        if (mounted) {
          setState(() {
            this.latestVersion = latestVersion;
            this.latestReleaseItem = latestReleaseItem;
          });
        }
      },
    );
  }
}
