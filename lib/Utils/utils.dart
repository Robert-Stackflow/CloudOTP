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

import 'dart:async';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../TokenUtils/Cloud/cloud_service.dart';
import '../TokenUtils/code_generator.dart';
import '../l10n/l10n.dart';
import 'app_provider.dart';
import 'constant.dart';
import 'hive_util.dart';

class Utils {
  static showQAuthDialog(BuildContext context, [bool force = false]) {
    bool haveShowQAuthDialog = ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.haveShowQAuthDialogKey,
        defaultValue: false);
    if (force || !haveShowQAuthDialog) {
      ChewieHiveUtil.put(CloudOTPHiveUtil.haveShowQAuthDialogKey, true);
      DialogBuilder.showInfoDialog(
        context,
        title: appLocalizations.cloudOAuthDialogTitle,
        message: appLocalizations.cloudOAuthDialogMessage(
            CloudService.serverEndpoint,
            CloudService.serverGithubRepoName,
            CloudService.serverGithubUrl),
        renderHtml: true,
        // cancelButtonText: appLocalizations.cloudOAuthDialogGoToRepo,
        buttonText: appLocalizations.cloudOAuthDialogConfirm,
        onTapDismiss: () {},
      );
    }
  }

  static Future<Rect> getWindowRect(BuildContext context) async {
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    return Rect.fromLTWH(
        0, 0, primaryDisplay.size.width, primaryDisplay.size.height);
  }

  static Map<String, dynamic> parseEndpoint(String endpoint) {
    final parts = endpoint.split(':');
    if (parts.length == 2) {
      return {
        'host': parts[0],
        'port': int.tryParse(parts[1]),
      };
    } else {
      return {
        'host': endpoint,
        'port': null,
      };
    }
  }

  static Future<List<MenuItem>> getTrayTokenMenuItems() async {
    List<TokenCategory> categories =
        DatabaseManager.initialized ? await CategoryDao.listCategories() : [];
    List<OtpToken> tokens =
        DatabaseManager.initialized ? await TokenDao.listTokens() : [];
    tokens.sort((a, b) => a.issuer.compareTo(b.issuer));
    for (TokenCategory category in categories) {
      category.tokens = await BindingDao.getTokens(category.uid);
      category.tokens.sort((a, b) => a.issuer.compareTo(b.issuer));
    }
    List<TokenCategory> haveTokenCategories =
        categories.where((e) => e.tokens.isNotEmpty).toList();
    if (DatabaseManager.initialized && tokens.isNotEmpty) {
      return [
        MenuItem.separator(),
        MenuItem.submenu(
          key: TrayKey.copyTokenCode.key,
          label: appLocalizations.allTokens,
          submenu: Menu(
            items: tokens
                .map(
                  (e) => MenuItem(
                    key: "${TrayKey.copyTokenCode.key}_${e.uid}",
                    label: e.issuer,
                  ),
                )
                .toList(),
          ),
        ),
        ...haveTokenCategories.map(
          (category) => MenuItem.submenu(
            key: "${TrayKey.copyTokenCode.key}_category_${category.uid}",
            label: category.title,
            submenu: Menu(
              items: category.tokens
                  .map(
                    (e) => MenuItem(
                      key: "${TrayKey.copyTokenCode.key}_${e.uid}",
                      label: e.issuer,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ];
    } else {
      return [];
    }
  }

  static Future<void> removeTray() async {
    await trayManager.destroy();
  }

  static Future<void> initTray() async {
    try {
      if (!ResponsiveUtil.isDesktop()) return;
      ILogger.debug("Initializing tray...");
      await trayManager.destroy();
      if (!ChewieHiveUtil.getBool(ChewieHiveUtil.showTrayKey)) {
        ILogger.debug("Tray is disabled, not initializing.");
        await trayManager.destroy();
        return;
      }
      // Ensure tray icon display in linux sandboxed environments
      if (Platform.environment.containsKey('FLATPAK_ID') ||
          Platform.environment.containsKey('SNAP')) {
        await trayManager.setIcon('com.cloudchewie.cloudotp');
      } else if (ResponsiveUtil.isWindows()) {
        await trayManager.setIcon('assets/logo-transparent.ico');
      } else {
        await trayManager.setIcon('assets/logo-transparent.png');
      }

      bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
      if (!ResponsiveUtil.isLinux()) {
        ILogger.debug(
            "Setting tray tooltip to app name ${ResponsiveUtil.appName}");
        await trayManager.setToolTip(ResponsiveUtil.appName);
      }
      Menu menu = Menu(
        items: [
          MenuItem(
            key: TrayKey.checkUpdates.key,
            label: appProvider.latestVersion.isNotEmpty
                ? appLocalizations.getNewVersion(appProvider.latestVersion)
                : appLocalizations.checkUpdates,
          ),
          MenuItem(
            key: TrayKey.shortcutHelp.key,
            label: appLocalizations.shortcutHelp,
          ),
          MenuItem.separator(),
          MenuItem(
            key: TrayKey.displayApp.key,
            label: appLocalizations.displayAppTray,
          ),
          MenuItem(
            key: TrayKey.lockApp.key,
            label: appLocalizations.lockAppTray,
          ),
          ...await getTrayTokenMenuItems(),
          MenuItem.separator(),
          MenuItem(
            key: TrayKey.setting.key,
            label: appLocalizations.setting,
          ),
          MenuItem(
            key: TrayKey.officialWebsite.key,
            label: appLocalizations.officialWebsiteTray,
          ),
          MenuItem(
            key: TrayKey.about.key,
            label: appLocalizations.about,
          ),
          MenuItem(
            key: TrayKey.githubRepository.key,
            label: appLocalizations.repoTray,
          ),
          MenuItem.separator(),
          MenuItem.checkbox(
            checked: lauchAtStartup,
            key: TrayKey.launchAtStartup.key,
            label: appLocalizations.launchAtStartup,
          ),
          MenuItem.separator(),
          MenuItem(
            key: TrayKey.exitApp.key,
            label: appLocalizations.exitAppTray,
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      ILogger.debug("Tray initialized successfully.");
    } catch (e, t) {
      ILogger.error("Failed to initialize simple tray", e, t);
    }
  }

  static Future<void> initSimpleTray() async {
    try {
      if (!ResponsiveUtil.isDesktop()) return;
      ILogger.debug("Initializing simple tray...");
      await trayManager.destroy();
      if (!ChewieHiveUtil.getBool(ChewieHiveUtil.showTrayKey)) {
        ILogger.debug("Tray is disabled, not initializing.");
        await trayManager.destroy();
        return;
      }

      // Ensure tray icon display in linux sandboxed environments
      if (Platform.environment.containsKey('FLATPAK_ID') ||
          Platform.environment.containsKey('SNAP')) {
        await trayManager.setIcon('com.cloudchewie.cloudotp');
      } else if (ResponsiveUtil.isWindows()) {
        await trayManager.setIcon('assets/logo-transparent.ico');
      } else {
        await trayManager.setIcon('assets/logo-transparent.png');
      }

      bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
      if (!ResponsiveUtil.isLinux()) {
        await trayManager.setToolTip(ResponsiveUtil.appName);
      }
      Menu menu = Menu(
        items: [
          MenuItem(
            key: TrayKey.displayApp.key,
            label: appLocalizations.displayAppTray,
          ),
          MenuItem.separator(),
          MenuItem(
            key: TrayKey.officialWebsite.key,
            label: appLocalizations.officialWebsiteTray,
          ),
          MenuItem(
            key: TrayKey.githubRepository.key,
            label: appLocalizations.repoTray,
          ),
          MenuItem.separator(),
          MenuItem.checkbox(
            checked: lauchAtStartup,
            key: TrayKey.launchAtStartup.key,
            label: appLocalizations.launchAtStartup,
          ),
          MenuItem.separator(),
          MenuItem(
            key: TrayKey.exitApp.key,
            label: appLocalizations.exitAppTray,
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      ILogger.debug("Simple tray initialized successfully.");
    } catch (e, t) {
      ILogger.error("Failed to initialize simple tray", e, t);
    }
  }

  static processTrayMenuItemClick(
    BuildContext context,
    MenuItem menuItem, [
    bool isSimple = false,
  ]) async {
    ILogger.debug("Processing tray menu item click: ${menuItem.key}");
    if (menuItem.key == TrayKey.displayApp.key) {
      ChewieUtils.displayApp();
    } else if (menuItem.key == TrayKey.shortcutHelp.key) {
      ChewieUtils.displayApp();
      ShortcutsUtil.showShortcutHelp(context);
    } else if (menuItem.key == TrayKey.lockApp.key) {
      ShortcutsUtil.lock(context);
    } else if (menuItem.key == TrayKey.setting.key) {
      ChewieUtils.displayApp();
      ShortcutsUtil.jumpToSetting(context);
    } else if (menuItem.key == TrayKey.about.key) {
      ChewieUtils.displayApp();
      ShortcutsUtil.jumpToAbout(context);
    } else if (menuItem.key == TrayKey.officialWebsite.key) {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (menuItem.key.notNullOrEmpty &&
        menuItem.key!.startsWith(TrayKey.copyTokenCode.key)) {
      String uid = menuItem.key!.split('_').last;
      OtpToken? token = await TokenDao.getTokenByUid(uid);
      if (token != null) {
        double currentProgress = token.period == 0
            ? 0
            : (token.period * 1000 -
                    (DateTime.now().millisecondsSinceEpoch %
                        (token.period * 1000))) /
                (token.period * 1000);
        if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoCopyNextCodeKey) &&
            currentProgress < autoCopyNextCodeProgressThrehold) {
          ChewieUtils.copy(context, CodeGenerator.getNextCode(token),
              toastText: appLocalizations.alreadyCopiedNextCode);
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            appLocalizations.alreadyCopiedNextCode,
            body: CodeGenerator.getNextCode(token),
          );
        } else {
          ChewieUtils.copy(context, CodeGenerator.getCurrentCode(token));
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            appLocalizations.copySuccess,
            body: CodeGenerator.getCurrentCode(token),
          );
        }
      }
    } else if (menuItem.key == TrayKey.githubRepository.key) {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == TrayKey.checkUpdates.key) {
      ChewieUtils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showFailedToast: false,
        showLatestToast: false,
        showDesktopNotification: true,
      );
    } else if (menuItem.key == TrayKey.launchAtStartup.key) {
      menuItem.checked = !(menuItem.checked == true);
      ChewieHiveUtil.put(ChewieHiveUtil.launchAtStartupKey, menuItem.checked);
      generalSettingScreenState?.refreshLauchAtStartup();
      if (menuItem.checked == true) {
        await LaunchAtStartup.instance.enable();
      } else {
        await LaunchAtStartup.instance.disable();
      }
      if (isSimple) {
        Utils.initSimpleTray();
      } else {
        Utils.initTray();
      }
    } else if (menuItem.key == TrayKey.exitApp.key) {
      windowManager.close();
    }
  }
}
