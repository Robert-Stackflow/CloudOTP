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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/utils.dart';
import '../../generated/app_localizations.dart';
import '../../l10n/l10n.dart';
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

class GeneralSettingScreenState extends BaseDynamicState<GeneralSettingScreen>
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

  late SelectionItemModel<int> _currentTrayOption;

  @override
  void initState() {
    super.initState();
    if (ResponsiveUtil.isMobile()) getCacheSize();
    fetchReleases(false);
    getLogSize();
    filterLocale();
    _currentTrayOption = getTrayOption();
  }

  @override
  void onLocaleChanged(Locale newLocale) {
    super.onLocaleChanged(newLocale);
    filterLocale();
    _currentTrayOption = getTrayOption();
    print(_currentTrayOption.key);
  }

  refreshLauchAtStartup() {
    setState(() {
      launchAtStartup =
          ChewieHiveUtil.getBool(ChewieHiveUtil.launchAtStartupKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.generalSetting,
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
      title: appLocalizations.language,
      children: [
        SearchableBuilderWidget(
          title: appLocalizations.language,
          builder: (_, title, description, searchText, searchConfig) =>
              Selector<AppProvider, Locale?>(
            selector: (context, appProvider) => appProvider.locale,
            builder: (context, locale, child) =>
                InlineSelectionItem<SelectionItemModel<Locale?>>(
              searchText: searchText,
              title: title,
              description: description,
              searchConfig: searchConfig,
              selections: _supportedLocaleTuples,
              selected: _supportedLocaleTuples
                  .firstWhere((element) => element.value == appProvider.locale),
              hint: appLocalizations.chooseLanguage,
              onChanged: (item) {
                appProvider.locale = item?.value;
              },
            ),
          ),
        ),
      ],
    );
  }

  _updateSetting() {
    return SearchableCaptionItem(
      title: appLocalizations.autoCheckUpdates,
      children: [
        CheckboxItem(
          value: autoCheckUpdate,
          title: appLocalizations.autoCheckUpdates,
          onTap: () {
            setState(() {
              autoCheckUpdate = !autoCheckUpdate;
              ChewieHiveUtil.put(
                  ChewieHiveUtil.autoCheckUpdateKey, autoCheckUpdate);
            });
          },
        ),
        EntryItem(
          title: appLocalizations.checkUpdates,
          description:
              ChewieUtils.compareVersion(latestVersion, currentVersion) > 0
                  ? appLocalizations.newVersion(latestVersion)
                  : appLocalizations.alreadyLatestVersion,
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
      title: appLocalizations.exportLog,
      children: [
        EntryItem(
          title: appLocalizations.exportLog,
          description: appLocalizations.exportLogHint,
          trailing: LucideIcons.fileUp,
          onTap: () {
            FileUtil.exportLogs();
          },
        ),
        EntryItem(
          title: appLocalizations.clearLog,
          tip: _logSize,
          onTap: () async {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.clearLogTitle,
              message: appLocalizations.clearLogHint,
              onTapConfirm: () async {
                CustomLoadingDialog.showLoading(
                    title: appLocalizations.clearingLog);
                try {
                  await FileOutput.clearLogs();
                  await getLogSize();
                  IToast.showTop(appLocalizations.clearLogSuccess);
                } catch (e, t) {
                  ILogger.error("Failed to clear logs", e, t);
                  IToast.showTop(appLocalizations.clearLogFailed);
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
      title: appLocalizations.desktopSetting,
      children: [
        CheckboxItem(
          title: appLocalizations.launchAtStartup,
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
          title: appLocalizations.showTray,
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
            title: appLocalizations.closeWindowOption,
            selections: [
              SelectionItemModel(appLocalizations.minimizeToTray, 0),
              SelectionItemModel(appLocalizations.exitApp, 1),
            ],
            hint: appLocalizations.chooseCloseWindowOption,
            selected: _currentTrayOption,
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
          title: appLocalizations.autoMemoryWindowPositionAndSize,
          value: recordWindowState,
          description: appLocalizations.autoMemoryWindowPositionAndSizeTip,
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

  SelectionItemModel<int> getTrayOption() {
    return SelectionItemModel(
      enableMinimizeToTray
          ? appLocalizations.minimizeToTray
          : appLocalizations.exitApp,
      enableMinimizeToTray ? 0 : 1,
    );
  }

  _mobileSettings() {
    return SearchableCaptionItem(
      title: appLocalizations.mobileSetting,
      children: [
        CheckboxItem(
          value: inAppBrowser,
          title: appLocalizations.inAppBrowser,
          onTap: () {
            setState(() {
              inAppBrowser = !inAppBrowser;
              ChewieHiveUtil.put(ChewieHiveUtil.inappWebviewKey, inAppBrowser);
            });
          },
        ),
        EntryItem(
          title: appLocalizations.clearCache,
          tip: _cacheSize,
          onTap: () {
            CustomLoadingDialog.showLoading(
                title: appLocalizations.clearingCache);
            getTemporaryDirectory().then((tempDir) {
              CacheUtil.delDir(tempDir).then((value) {
                CacheUtil.loadCache().then((value) {
                  setState(() {
                    _cacheSize = value;
                    CustomLoadingDialog.dismissLoading();
                    IToast.showTop(appLocalizations.clearCacheSuccess);
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
    List<Locale> locales = AppLocalizations.supportedLocales;
    _supportedLocaleTuples
        .add(SelectionItemModel(appLocalizations.followSystem, null));
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
