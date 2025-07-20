import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:window_manager/window_manager.dart';

class ChewieUtils {
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
    await ScreenProtector.protectDataLeakageWithBlur();
    await ScreenProtector.protectDataLeakageWithColor(
        ChewieTheme.scaffoldBackgroundColor);
    if (ResponsiveUtil.isAndroid()) {
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarColor: Colors.white));
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_BLUR_BEHIND);
    }
  }

  static Future<void> disableSafeMode() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    await ScreenProtector.protectDataLeakageWithBlurOff();
    await ScreenProtector.protectDataLeakageWithColorOff();
    if (ResponsiveUtil.isAndroid()) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  static getDownloadUrl(String version, String name) {
    return "$downloadPkgsUrl/$version/$name";
  }

  static Brightness currentBrightness(BuildContext context) {
    return chewieProvider.getBrightness() ??
        MediaQuery.of(context).platformBrightness;
  }

  static String processEmpty(String? str, {String defaultValue = ""}) {
    return str.nullOrEmpty ? defaultValue : str!;
  }

  static String getHeroTag({
    String? tagPrefix,
    String? tagSuffix,
    String? url,
  }) {
    return "${processEmpty(tagPrefix)}-${processEmpty(url)}-${processEmpty(tagSuffix)}";
  }

  static double getMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeArea = MediaQuery.of(context).padding;
    final appBarHeight = AppBar().preferredSize.height;
    return screenHeight - appBarHeight - safeArea.top;
  }

  static patchEnum(int? index, int length, {int defaultValue = 0}) {
    return index == null
        ? defaultValue
        : index < 0 || index > length - 1
            ? defaultValue
            : index;
  }

  static List<T> deepCopy<T>(List<T> list) {
    return List<T>.from(list);
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
    Clipboard.setData(ClipboardData(text: data.toString())).then((value) {
      toastText ??= chewieLocalizations.copySuccess;
      if (toastText.notNullOrEmpty) {
        IToast.showTop(toastText ?? "",
            icon: const Icon(LucideIcons.copyCheck));
      }
    });
    HapticFeedback.mediumImpact();
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

  static compareVersion(String a, String b) {
    if (a.nullOrEmpty || b.nullOrEmpty) {
      // ILogger.warn("Version is empty, compare failed between $a and $b");
      return a.compareTo(b);
    }
    try {
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
      ILogger.error("Failed to compare version $a and $b", e, t);
      return a.compareTo(b);
    }
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
    String userName = "Robert-Stackflow",
    String? repoName,
  }) async {
    ResponsiveUtil.isAppBundle();
    if (showLoading) {
      CustomLoadingDialog.showLoading(
          title: chewieLocalizations.checkingUpdates);
    }
    String currentVersion = (await PackageInfo.fromPlatform()).version;
    onGetCurrentVersion?.call(currentVersion);
    String latestVersion = "0.0.0";
    await GithubApi.getReleases(userName, repoName ?? ResponsiveUtil.appName)
        .then((releases) async {
      if (showLoading) {
        CustomLoadingDialog.dismissLoading();
      }
      if (releases.isEmpty) {
        if (showFailedToast) {
          IToast.showTop(
              noUpdateToastText ?? chewieLocalizations.checkUpdatesFailed);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            chewieLocalizations.checkUpdatesFailed,
            body: chewieLocalizations.checkUpdatesFailedTip,
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
      ILogger.info(
          "Current version: $currentVersion, Latest version: $latestVersion");
      if (compareVersion(latestVersion, currentVersion) > 0) {
        onUpdate?.call(latestVersion, latestReleaseItem!);
        chewieProvider.latestVersion = latestVersion;
        if (showUpdateDialog && latestReleaseItem != null) {
          if (ResponsiveUtil.isMobile()) {
            DialogBuilder.showConfirmDialog(
              context,
              renderHtml: true,
              messageTextAlign: TextAlign.start,
              title: chewieLocalizations.getNewVersion(latestVersion),
              message: chewieLocalizations.doesImmediateUpdate +
                  chewieLocalizations.changelogAsFollow(
                      "<br/>${StringUtil.replaceLineBreak(latestReleaseItem.body ?? "")}"),
              confirmButtonText: ResponsiveUtil.isAndroid()
                  ? chewieLocalizations.immediatelyDownload
                  : chewieLocalizations.goToUpdate,
              cancelButtonText: chewieLocalizations.updateLater,
              onTapConfirm: () async {
                if (ResponsiveUtil.isAppBundle()) {
                  UriUtil.launchUri(await UriUtil.getGooglePlayStoreUrl());
                } else {
                  UriUtil.openExternal(latestReleaseItem!.htmlUrl);
                }
              },
              onTapCancel: () {},
            );
          } else {
            showDialog(ReleaseItem latestReleaseItem) {
              DialogBuilder.showPageDialog(
                context,
                child: UpdateScreen(
                  currentVersion: currentVersion,
                  latestReleaseItem: latestReleaseItem,
                  latestVersion: latestVersion,
                ),
              );
              ChewieUtils.displayApp();
            }

            if (showDesktopNotification) {
              IToast.showDesktopNotification(
                chewieLocalizations.getNewVersion(latestVersion),
                body: chewieLocalizations
                    .changelogAsFollow("\n${latestReleaseItem.body ?? ""}"),
                actions: [
                  chewieLocalizations.updateLater,
                  chewieLocalizations.goToUpdate
                ],
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
        chewieProvider.latestVersion = "";
        if (showLatestToast) {
          IToast.showTop(chewieLocalizations.alreadyLatestVersion);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            chewieLocalizations.alreadyLatestVersion,
            body: chewieLocalizations.alreadyLatestVersionTip(currentVersion),
          );
        }
      }
    });
  }

  static displayApp() {
    windowManager.show();
    windowManager.focus();
    // windowManager.restore();
  }

  static localAuth({Function()? onAuthed}) async {
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
          biometricOnly: false,
        ),
        localizedReason: ' ',
      ).then((value) {
        if (value) {
          onAuthed?.call();
        }
      });
    } on PlatformException catch (e, t) {
      ILogger.error("Failed to local authenticate by PlatformException", e, t);
      if (e.code == auth_error.notAvailable) {
        IToast.showTop(chewieLocalizations.biometricNotAvailable);
      } else if (e.code == auth_error.notEnrolled) {
        IToast.showTop(chewieLocalizations.biometricNotEnrolled);
      } else if (e.code == auth_error.lockedOut) {
        IToast.showTop(chewieLocalizations.biometricLockout);
      } else if (e.code == auth_error.permanentlyLockedOut) {
        IToast.showTop(chewieLocalizations.biometricLockoutPermanent);
      } else {
        IToast.showTop(chewieLocalizations.biometricOtherReason(e));
      }
    } catch (e, t) {
      ILogger.error("Failed to local authenticate", e, t);
    }
  }
}
