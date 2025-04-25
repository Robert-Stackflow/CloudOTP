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
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import 'base_setting_screen.dart';

class GeneralSettingScreen extends BaseSettingScreen {
  const GeneralSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/general";

  @override
  State<GeneralSettingScreen> createState() => GeneralSettingScreenState();
}

class GeneralSettingScreenState extends State<GeneralSettingScreen>
    with TickerProviderStateMixin {
  bool enableMinimizeToTray =
      ChewieHiveUtil.getBool(ChewieHiveUtil.enableCloseToTrayKey);
  bool launchAtStartup =
      ChewieHiveUtil.getBool(ChewieHiveUtil.launchAtStartupKey);
  bool recordWindowState =
      ChewieHiveUtil.getBool(ChewieHiveUtil.recordWindowStateKey);
  bool showTray = ChewieHiveUtil.getBool(ChewieHiveUtil.showTrayKey);
  bool enableCloseNotice =
      ChewieHiveUtil.getBool(ChewieHiveUtil.enableCloseNoticeKey);
  List<SelectionItemModel<Locale?>> _supportedLocaleTuples = [];
  String currentVersion = "";
  String latestVersion = "";
  ReleaseItem? latestReleaseItem;
  bool autoCheckUpdate =
      ChewieHiveUtil.getBool(ChewieHiveUtil.autoCheckUpdateKey);
  String _cacheSize = "";
  String _logSize = "";
  bool inAppBrowser = ChewieHiveUtil.getBool(ChewieHiveUtil.inappWebviewKey);

  @override
  void initState() {
    super.initState();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
    getLogSize();
    filterLocale();
  }

  refreshLauchAtStartup() {
    setState(() {
      launchAtStartup =
          ChewieHiveUtil.getBool(ChewieHiveUtil.launchAtStartupKey);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: S.current.generalSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        _languageSetting(),
        _updateSetting(),
        if (ResponsiveUtil.isDesktop()) _desktopSettings(),
        if (ResponsiveUtil.isMobile()) _mobileSettings(),
        _logSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _languageSetting() {
    return SearchableCaptionItem(
      title: S.current.language,
      children: [
        SearchableBuilderWidget(
          title: S.current.language,
          builder: (_, title, description, searchText, searchConfig) =>
              Selector<ChewieProvider, Locale?>(
            selector: (context, globalProvider) => globalProvider.locale,
            builder: (context, locale, child) =>
                InlineSelectionItem<SelectionItemModel<Locale?>>(
              searchText: searchText,
              title: title,
              description: description,
              searchConfig: searchConfig,
              selections: _supportedLocaleTuples,
              selected: _supportedLocaleTuples.firstWhere(
                  (element) => element.value == chewieProvider.locale),
              hint: S.current.chooseLanguage,
              onChanged: (item) {
                chewieProvider.locale = item?.value;
              },
            ),
          ),
        ),
      ],
    );
  }

  _updateSetting() {
    return SearchableCaptionItem(
      title: S.current.autoCheckUpdates,
      children: [
        CheckboxItem(
          value: autoCheckUpdate,
          title: S.current.autoCheckUpdates,
          onTap: () {
            setState(() {
              autoCheckUpdate = !autoCheckUpdate;
              ChewieHiveUtil.put(
                  ChewieHiveUtil.autoCheckUpdateKey, autoCheckUpdate);
            });
          },
        ),
        EntryItem(
          title: S.current.checkUpdates,
          description:
              ChewieUtils.compareVersion(latestVersion, currentVersion) > 0
                  ? S.current.newVersion(latestVersion)
                  : S.current.alreadyLatestVersion,
          descriptionColor:
              ChewieUtils.compareVersion(latestVersion, currentVersion) > 0
                  ? ChewieTheme.errorColor
                  : null,
          tip: currentVersion,
          onTap: () {
            fetchReleases(true);
          },
        ),
      ],
    );
  }

  _logSettings() {
    return SearchableCaptionItem(
      title: S.current.exportLog,
      children: [
        EntryItem(
          title: S.current.exportLog,
          description: S.current.exportLogHint,
          onTap: () {
            FileUtil.exportLogs();
          },
        ),
        EntryItem(
          title: S.current.clearLog,
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
                  ILogger.error("Failed to clear logs", e, t);
                  IToast.showTop(S.current.clearLogFailed);
                } finally {
                  CustomLoadingDialog.dismissLoading();
                }
              },
            );
          },
        ),
      ],
    );
  }

  _desktopSettings() {
    return SearchableCaptionItem(
      title: S.current.desktopSetting,
      children: [
        CheckboxItem(
          title: S.current.launchAtStartup,
          value: launchAtStartup,
          onTap: () async {
            setState(() {
              launchAtStartup = !launchAtStartup;
              ChewieHiveUtil.put(
                  ChewieHiveUtil.launchAtStartupKey, launchAtStartup);
            });
            if (launchAtStartup) {
              await LaunchAtStartup.instance.enable();
            } else {
              await LaunchAtStartup.instance.disable();
            }
            Utils.initTray();
          },
        ),
        CheckboxItem(
          title: S.current.showTray,
          value: showTray,
          onTap: () async {
            setState(() {
              showTray = !showTray;
              ChewieHiveUtil.put(ChewieHiveUtil.showTrayKey, showTray);
              if (showTray) {
                Utils.initTray();
              } else {
                Utils.removeTray();
              }
            });
          },
        ),
        if (showTray)
          InlineSelectionItem<SelectionItemModel<int>>(
            title: S.current.closeWindowOption,
            selections: [
              SelectionItemModel(S.current.minimizeToTray, 0),
              SelectionItemModel(S.current.exitApp, 1),
            ],
            hint: S.current.chooseCloseWindowOption,
            selected: SelectionItemModel(
                enableMinimizeToTray
                    ? S.current.minimizeToTray
                    : S.current.exitApp,
                enableMinimizeToTray ? 0 : 1),
            onChanged: (item) {
              if (item?.value == 0) {
                setState(() {
                  enableMinimizeToTray = true;
                  ChewieHiveUtil.put(ChewieHiveUtil.enableCloseToTrayKey,
                      enableMinimizeToTray);
                });
              } else if (item?.value == 1) {
                setState(() {
                  enableMinimizeToTray = false;
                  ChewieHiveUtil.put(ChewieHiveUtil.enableCloseToTrayKey,
                      enableMinimizeToTray);
                });
              }
            },
          ),
        CheckboxItem(
          title: S.current.autoMemoryWindowPositionAndSize,
          value: recordWindowState,
          description: S.current.autoMemoryWindowPositionAndSizeTip,
          onTap: () async {
            setState(() {
              recordWindowState = !recordWindowState;
              ChewieHiveUtil.put(
                  ChewieHiveUtil.recordWindowStateKey, recordWindowState);
            });
            ChewieHiveUtil.setWindowSize(await windowManager.getSize());
            ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
          },
        ),
      ],
    );
  }

  _mobileSettings() {
    return SearchableCaptionItem(
      title: S.current.mobileSetting,
      children: [
        CheckboxItem(
          value: inAppBrowser,
          title: S.current.inAppBrowser,
          onTap: () {
            setState(() {
              inAppBrowser = !inAppBrowser;
              ChewieHiveUtil.put(ChewieHiveUtil.inappWebviewKey, inAppBrowser);
            });
          },
        ),
        EntryItem(
          title: S.current.clearCache,
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
      ],
    );
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
    _supportedLocaleTuples
        .add(SelectionItemModel(S.current.followSystem, null));
    for (Locale locale in locales) {
      SelectionItemModel<Locale?>? tuple =
          LocaleUtil.getSelectionItemModel(locale);
      if (tuple != null) {
        _supportedLocaleTuples.add(tuple);
      }
    }
  }

  Future<void> fetchReleases(bool showTip) async {
    setState(() {});
    ChewieUtils.getReleases(
      context: context,
      showLoading: showTip,
      showUpdateDialog: showTip,
      showFailedToast: showTip,
      showLatestToast: showTip,
      onGetCurrentVersion: (currentVersion) {
        this.currentVersion = currentVersion;
        if (mounted) setState(() {});
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        this.latestVersion = latestVersion;
        this.latestReleaseItem = latestReleaseItem;
        if (mounted) setState(() {});
      },
    );
  }
}
