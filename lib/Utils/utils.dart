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
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/github_response.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Screens/Setting/update_screen.dart';
import 'package:cloudotp/Utils/enums.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:cloudotp/Utils/uri_util.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

import '../Api/github_api.dart';
import '../Screens/Setting/about_setting_screen.dart';
import '../Screens/Setting/setting_navigation_screen.dart';
import '../Screens/Setting/setting_safe_screen.dart';
import '../TokenUtils/code_generator.dart';
import '../Widgets/Custom/keymap_widget.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/Dialog/dialog_builder.dart';
import '../generated/l10n.dart';
import './ilogger.dart';
import 'app_provider.dart';
import 'constant.dart';
import 'hive_util.dart';
import 'itoast.dart';

class Utils {
  static String generateUid() {
    return const Uuid().v4();
  }

  static bool isUid(String uid) {
    return RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
        .hasMatch(uid);
  }

  static Future<void> setSafeMode(bool enabled) async {
    if (ResponsiveUtil.isMobile()) {
      if (enabled) {
        enableSafeMode();
      } else {
        disableSafeMode();
      }
    }
  }

  static Future<void> enableSafeMode() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.protectDataLeakageWithColor(
        Theme.of(rootContext).scaffoldBackgroundColor);
    if (ResponsiveUtil.isAndroid()) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  static Future<void> disableSafeMode() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    await ScreenProtector.protectDataLeakageWithColorOff();
    if (ResponsiveUtil.isAndroid()) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  static Brightness currentBrightness(BuildContext context) {
    return appProvider.getBrightness() ??
        MediaQuery.of(context).platformBrightness;
  }

  static String processEmpty(String? str, {String defaultValue = ""}) {
    return isEmpty(str) ? defaultValue : str!;
  }

  static bool isEmpty(String? str) {
    return str == null || str.isEmpty;
  }

  static bool isNotEmpty(String? str) {
    return !isEmpty(str);
  }

  static double getMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeArea = MediaQuery.of(context).padding;
    final appBarHeight = AppBar().preferredSize.height;
    return screenHeight - appBarHeight - safeArea.top;
  }

  static Future<Rect> getWindowRect(BuildContext context) async {
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    return Rect.fromLTWH(
        0, 0, primaryDisplay.size.width, primaryDisplay.size.height);
  }

  static String getRandomString({int length = 8}) {
    final random = Random();
    const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
    return randomString;
  }

  static isDark(BuildContext context) {
    return (appProvider.themeMode == ActiveThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark) ||
        appProvider.themeMode == ActiveThemeMode.dark;
  }

  static Color getDarkColor(Color color, {Color darkColor = Colors.black}) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? color
        : darkColor;
  }

  static String extractTextFromHtml(String html) {
    var document = parse(html);
    return document.body?.text ?? "";
  }

  static List<String> extractImagesFromHtml(String html) {
    var document = parse(html);
    var images = document.getElementsByTagName("img");
    return images.map((e) => e.attributes["src"] ?? "").toList();
  }

  static String replaceLineBreak(String str) {
    return str.replaceAll(RegExp(r"\r\n"), "<br/>");
  }

  static bool isGIF(String str) {
    return str.contains(".gif");
  }

  static int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  static String intToHex(int value) {
    return value.toRadixString(16);
  }

  static patchEnum(int index, int length, {int defaultValue = 0}) {
    return index < 0 || index > length - 1 ? defaultValue : index;
  }

  static List<T> deepCopyList<T>(List<T> list) {
    return List<T>.from(list);
  }

  static int parseToInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      try {
        return int.parse(value);
      } catch (e, t) {
        ILogger.error("CloudOTP", "Failed to parse int from $value", e, t);
        return 0;
      }
    } else {
      return 0;
    }
  }

  static Map formatCountToMap(int count) {
    if (count < 10000) {
      return {"count": count.toString()};
    } else {
      return {"count": (count / 10000).toStringAsFixed(1), "scale": "万"};
    }
  }

  static String formatCount(int count) {
    if (count < 10000) {
      return count.toString();
    } else {
      return "${(count / 10000).toStringAsFixed(1)}万";
    }
  }

  static String formatDuration(int duration) {
    var minutes = duration ~/ 60;
    var seconds = duration % 60;
    return "${minutes < 10 ? "0$minutes" : minutes}:${seconds < 10 ? "0$seconds" : seconds}";
  }

  static String limitString(String str, {int limit = 30}) {
    return str.length > limit ? str.substring(0, limit) : str;
  }

  static String clearBlank(String str, {bool keepOne = true}) {
    return str.trim().replaceAll(RegExp(r"\s+"), keepOne ? " " : "");
  }

  static Future<String?> getClipboardData() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static void copy(
    BuildContext context,
    dynamic data, {
    String? toastText,
  }) {
    toastText ??= S.current.copySuccess;
    Clipboard.setData(ClipboardData(text: data.toString())).then((value) {
      if (Utils.isNotEmpty(toastText)) {
        IToast.showTop(toastText ?? "");
      }
    });
    HapticFeedback.mediumImpact();
  }

  static String formatYearMonth(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy年MM月");
    return dateFormat.format(date);
  }

  static String timestampToDateString(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss:SSS");
    return dateFormat.format(date);
  }

  static String formatTimestamp(int timestamp) {
    var now = DateTime.now();
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var dateFormat = DateFormat("yyyy-MM-dd");
    var dateFormat2 = DateFormat("MM-dd");
    var diff = now.difference(date);
    if (date.year != now.year) {
      return dateFormat.format(date);
    } else if (diff.inDays > 7) {
      return dateFormat2.format(date);
    } else if (diff.inDays > 0) {
      return S.current.dayAgo(diff.inDays + 1);
    } else if (diff.inHours > 0) {
      return "${date.hour < 10 ? "0${date.hour}" : date.hour}:${date.minute < 10 ? "0${date.minute}" : date.minute}";
    } else if (diff.inSeconds > 60) {
      return S.current.minuteAgo(diff.inMinutes);
    } else if (diff.inSeconds > 3) {
      return S.current.secondAgo(diff.inSeconds);
    } else {
      return S.current.rightnow;
    }
  }

  static Map<String, dynamic> parseJson(String jsonStr) {
    return json.decode(jsonStr);
  }

  static List<dynamic> parseJsonList(String jsonStr) {
    return json.decode(jsonStr);
  }

  static int binarySearch<T>(
      List<T> sortedList, T value, int Function(T, T) compare) {
    var min = 0;
    var max = sortedList.length;
    while (min < max) {
      var mid = min + ((max - min) >> 1);
      var element = sortedList[mid];
      var comp = compare(element, value);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }

  static final _urlRegex = RegExp(
    r"^https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,63}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*$)",
    caseSensitive: false,
  );

  static bool isUrl(String url) => _urlRegex.hasMatch(url.trim());

  static Future<String?> fetchFavicon(String url) async {
    try {
      url = url.split("/").getRange(0, 3).join("/");
      var uri = Uri.parse(url);
      var result = await http.get(uri);
      if (result.statusCode == 200) {
        var htmlStr = result.body;
        var dom = parse(htmlStr);
        var links = dom.getElementsByTagName("link");
        for (var link in links) {
          var rel = link.attributes["rel"];
          if ((rel == "icon" || rel == "shortcut icon") &&
              link.attributes.containsKey("href")) {
            var href = link.attributes["href"]!;
            var parsedUrl = Uri.parse(url);
            if (href.startsWith("//")) {
              return "${parsedUrl.scheme}:$href";
            } else if (href.startsWith("/")) {
              return url + href;
            } else {
              return href;
            }
          }
        }
      }
      url = "$url/favicon.ico";
      if (await Utils.validateFavicon(url)) {
        return url;
      } else {
        return null;
      }
    } catch (exp) {
      return null;
    }
  }

  static Future<bool> validateFavicon(String url) async {
    var flag = false;
    var uri = Uri.parse(url);
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var contentType =
          result.headers["Content-Type"] ?? result.headers["content-type"];
      if (contentType != null && contentType.startsWith("image")) flag = true;
    }
    return flag;
  }

  static compareVersion(String a, String b) {
    try {
      if (a.isEmpty || b.isEmpty) {
        return a.compareTo(b);
      }
      List<String> aList = a.split(".");
      List<String> bList = b.split(".");
      for (int i = 0; i < aList.length; i++) {
        if (int.parse(aList[i]) > int.parse(bList[i])) {
          return 1;
        } else if (int.parse(aList[i]) < int.parse(bList[i])) {
          return -1;
        }
      }
      return 0;
    } catch (e, t) {
      ILogger.error(
          "CloudOTP", "Failed to compare version between $a and $b", e, t);
      return a.compareTo(b);
    }
  }

  static displayApp() {
    windowManager.show();
    windowManager.focus();
    // windowManager.restore();
  }

  static getDownloadUrl(String version, String name) {
    return "$downloadPkgsUrl/$version/$name";
  }

  static getReleases({
    required BuildContext context,
    Function(String)? onGetCurrentVersion,
    Function(List<ReleaseItem>)? onGetReleases,
    Function(String, ReleaseItem)? onGetLatestRelease,
    Function(String, ReleaseItem)? onUpdate,
    bool showLoading = false,
    bool showUpdateDialog = true,
    bool showFailedToast = true,
    bool showLatestToast = true,
    bool showDesktopNotification = false,
    String? noUpdateToastText,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.checkingUpdates);
    }
    String currentVersion = (await PackageInfo.fromPlatform()).version;
    onGetCurrentVersion?.call(currentVersion);
    String latestVersion = "0.0.0";
    await GithubApi.getReleases("Robert-Stackflow", "CloudOTP")
        .then((releases) async {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
      if (releases.isEmpty) {
        if (showFailedToast) {
          IToast.showTop(noUpdateToastText ?? S.current.checkUpdatesFailed);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            S.current.checkUpdatesFailed,
            body: S.current.checkUpdatesFailedTip,
          );
        }
        return;
      }
      onGetReleases?.call(releases);
      ReleaseItem? latestReleaseItem;
      for (var release in releases) {
        String tagName = release.tagName;
        tagName = tagName.replaceAll(RegExp(r'[a-zA-Z]'), '');
        if (compareVersion(latestVersion, tagName) <= 0) {
          latestVersion = tagName;
          latestReleaseItem = release;
        }
      }
      onGetLatestRelease?.call(latestVersion, latestReleaseItem!);
      Utils.initTray();
      ILogger.info("CloudOTP",
          "Current version: $currentVersion, Latest version: $latestVersion");
      if (compareVersion(latestVersion, currentVersion) > 0) {
        onUpdate?.call(latestVersion, latestReleaseItem!);
        appProvider.latestVersion = latestVersion;
        if (showUpdateDialog && latestReleaseItem != null) {
          if (ResponsiveUtil.isMobile()) {
            DialogBuilder.showConfirmDialog(
              context,
              renderHtml: true,
              messageTextAlign: TextAlign.start,
              title: S.current.getNewVersion(latestVersion),
              message: S.current.doesImmediateUpdate +
                  S.current.changelogAsFollow(
                      "<br/>${Utils.replaceLineBreak(latestReleaseItem.body ?? "")}"),
              confirmButtonText: ResponsiveUtil.isAndroid()
                  ? S.current.immediatelyDownload
                  : S.current.goToUpdate,
              cancelButtonText: S.current.updateLater,
              onTapConfirm: () async {
                if (ResponsiveUtil.isAndroid()) {
                  ReleaseAsset androidAssset = await FileUtil.getAndroidAsset(
                      latestVersion, latestReleaseItem!);
                  ILogger.info("CloudOTP", "Get android asset: $androidAssset");
                  FileUtil.downloadAndUpdate(
                    context,
                    androidAssset.pkgsDownloadUrl,
                    latestReleaseItem.htmlUrl,
                    version: latestVersion,
                  );
                } else {
                  UriUtil.openExternal(latestReleaseItem!.htmlUrl);
                  return;
                }
              },
              onTapCancel: () {},
            );
          } else {
            showDialog(ReleaseItem latestReleaseItem) {
              GlobalKey<DialogWrapperWidgetState> overrideDialogNavigatorKey =
                  GlobalKey();
              DialogBuilder.showPageDialog(
                context,
                overrideDialogNavigatorKey: overrideDialogNavigatorKey,
                child: UpdateScreen(
                  currentVersion: currentVersion,
                  latestReleaseItem: latestReleaseItem,
                  latestVersion: latestVersion,
                  overrideDialogNavigatorKey: overrideDialogNavigatorKey,
                ),
              );
              Utils.displayApp();
            }

            if (showDesktopNotification) {
              IToast.showDesktopNotification(
                S.current.getNewVersion(latestVersion),
                body: S.current
                    .changelogAsFollow("\n${latestReleaseItem.body ?? ""}"),
                actions: [S.current.updateLater, S.current.goToUpdate],
                onClick: () {
                  showDialog(latestReleaseItem!);
                },
                onClickAction: (index) {
                  if (index == 1) {
                    showDialog(latestReleaseItem!);
                  }
                },
              );
            } else {
              showDialog(latestReleaseItem);
            }
          }
        }
      } else {
        appProvider.latestVersion = "";
        if (showLatestToast) {
          IToast.showTop(S.current.alreadyLatestVersion);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            S.current.alreadyLatestVersion,
            body: S.current.alreadyLatestVersionTip(currentVersion),
          );
        }
      }
    });
  }

  static localAuth({Function()? onAuthed}) async {
    if (ResponsiveUtil.isDesktop()) return;
    LocalAuthentication localAuth = LocalAuthentication();
    try {
      await localAuth.authenticate(
        authMessages: [
          androidAuthMessages,
          androidAuthMessages,
          androidAuthMessages
        ],
        options: const AuthenticationOptions(
          useErrorDialogs: false,
          stickyAuth: true,
          biometricOnly: true,
        ),
        localizedReason: ' ',
      ).then((value) {
        if (value) {
          onAuthed?.call();
        }
      });
    } on PlatformException catch (e, t) {
      ILogger.error("CloudOTP",
          "Failed to local authenticate by PlatformException", e, t);
      if (e.code == auth_error.notAvailable) {
        IToast.showTop(S.current.biometricNotAvailable);
      } else if (e.code == auth_error.notEnrolled) {
        IToast.showTop(S.current.biometricNotEnrolled);
      } else if (e.code == auth_error.lockedOut) {
        IToast.showTop(S.current.biometricLockout);
      } else if (e.code == auth_error.permanentlyLockedOut) {
        IToast.showTop(S.current.biometricLockoutPermanent);
      } else {
        IToast.showTop(S.current.biometricOtherReason(e));
      }
    } catch (e, t) {
      ILogger.error("CloudOTP", "Failed to local authenticate", e, t);
    }
  }

  static String getFormattedDate(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd-HH-mm-ss").format(dateTime);
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
          label: S.current.allTokens,
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
    if (!ResponsiveUtil.isDesktop()) return;
    await trayManager.destroy();
    if (!HiveUtil.getBool(HiveUtil.showTrayKey)) {
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

    var packageInfo = await PackageInfo.fromPlatform();
    bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
    if (!ResponsiveUtil.isLinux()) {
      await trayManager.setToolTip(packageInfo.appName);
    }
    Menu menu = Menu(
      items: [
        MenuItem(
          key: TrayKey.checkUpdates.key,
          label: appProvider.latestVersion.isNotEmpty
              ? S.current.getNewVersion(appProvider.latestVersion)
              : S.current.checkUpdates,
        ),
        MenuItem(
          key: TrayKey.shortcutHelp.key,
          label: S.current.shortcutHelp,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.displayApp.key,
          label: S.current.displayAppTray,
        ),
        MenuItem(
          key: TrayKey.lockApp.key,
          label: S.current.lockAppTray,
        ),
        ...await getTrayTokenMenuItems(),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.setting.key,
          label: S.current.setting,
        ),
        MenuItem(
          key: TrayKey.officialWebsite.key,
          label: S.current.officialWebsiteTray,
        ),
        MenuItem(
          key: TrayKey.about.key,
          label: S.current.about,
        ),
        MenuItem(
          key: TrayKey.githubRepository.key,
          label: S.current.repoTray,
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          checked: lauchAtStartup,
          key: TrayKey.launchAtStartup.key,
          label: S.current.launchAtStartup,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.exitApp.key,
          label: S.current.exitAppTray,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  static Future<void> initSimpleTray() async {
    if (!ResponsiveUtil.isDesktop()) return;
    await trayManager.destroy();
    if (!HiveUtil.getBool(HiveUtil.showTrayKey)) {
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

    var packageInfo = await PackageInfo.fromPlatform();
    bool lauchAtStartup = await LaunchAtStartup.instance.isEnabled();
    if (!ResponsiveUtil.isLinux()) {
      await trayManager.setToolTip(packageInfo.appName);
    }
    Menu menu = Menu(
      items: [
        MenuItem(
          key: TrayKey.displayApp.key,
          label: S.current.displayAppTray,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.officialWebsite.key,
          label: S.current.officialWebsiteTray,
        ),
        MenuItem(
          key: TrayKey.githubRepository.key,
          label: S.current.repoTray,
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          checked: lauchAtStartup,
          key: TrayKey.launchAtStartup.key,
          label: S.current.launchAtStartup,
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayKey.exitApp.key,
          label: S.current.exitAppTray,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  static showHelp(BuildContext context) {
    if (appProvider.shownShortcutHelp) return;
    appProvider.shownShortcutHelp = true;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return KeyboardWidget(
          bindings: defaultCloudOTPShortcuts,
          callbackOnHide: () {
            appProvider.shownShortcutHelp = false;
            entry.remove();
          },
          title: Text(
            S.current.shortcut,
            style: Theme.of(rootContext).textTheme.titleLarge,
          ),
        );
      },
    );
    Overlay.of(context).insert(entry);
    return null;
  }

  static processTrayMenuItemClick(
    BuildContext context,
    MenuItem menuItem, [
    bool isSimple = false,
  ]) async {
    if (menuItem.key == TrayKey.displayApp.key) {
      Utils.displayApp();
    } else if (menuItem.key == TrayKey.shortcutHelp.key) {
      Utils.displayApp();
      Utils.showHelp(context);
    } else if (menuItem.key == TrayKey.lockApp.key) {
      if (HiveUtil.canLock()) {
        mainScreenState?.jumpToLock();
      } else {
        IToast.showDesktopNotification(
          S.current.noGestureLock,
          body: S.current.noGestureLockTip,
          actions: [S.current.cancel, S.current.goToSetGestureLock],
          onClick: () {
            Utils.displayApp();
            RouteUtil.pushDialogRoute(context, const SafeSettingScreen());
          },
          onClickAction: (index) {
            if (index == 1) {
              Utils.displayApp();
              RouteUtil.pushDialogRoute(context, const SafeSettingScreen());
            }
          },
        );
      }
    } else if (menuItem.key == TrayKey.setting.key) {
      Utils.displayApp();
      RouteUtil.pushDialogRoute(context, const SettingNavigationScreen());
    } else if (menuItem.key == TrayKey.about.key) {
      Utils.displayApp();
      RouteUtil.pushDialogRoute(context, const AboutSettingScreen());
    } else if (menuItem.key == TrayKey.officialWebsite.key) {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (Utils.isNotEmpty(menuItem.key) &&
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
        if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
            currentProgress < autoCopyNextCodeProgressThrehold) {
          Utils.copy(context, CodeGenerator.getNextCode(token),
              toastText: S.current.alreadyCopiedNextCode);
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            S.current.alreadyCopiedNextCode,
            body: CodeGenerator.getNextCode(token),
          );
        } else {
          Utils.copy(context, CodeGenerator.getCurrentCode(token));
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            S.current.copySuccess,
            body: CodeGenerator.getCurrentCode(token),
          );
        }
      }
    } else if (menuItem.key == TrayKey.githubRepository.key) {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == TrayKey.checkUpdates.key) {
      Utils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showFailedToast: false,
        showLatestToast: false,
        showDesktopNotification: true,
      );
    } else if (menuItem.key == TrayKey.launchAtStartup.key) {
      menuItem.checked = !(menuItem.checked == true);
      HiveUtil.put(HiveUtil.launchAtStartupKey, menuItem.checked);
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
