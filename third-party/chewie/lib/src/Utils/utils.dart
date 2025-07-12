import 'dart:async';

import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:window_manager/window_manager.dart';

import 'package:awesome_chewie/src/Api/github_api.dart';
import 'package:awesome_chewie/src/Models/github_response.dart';
import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/dialog_builder.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/update_screen.dart';
import 'constant.dart';
import 'ilogger.dart';
import 'itoast.dart';

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
    await ScreenProtector.protectDataLeakageWithColor(
        Theme.of(chewieProvider.rootContext).scaffoldBackgroundColor);
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
      toastText ??= ChewieS.current.copySuccess;
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
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: ChewieS.current.checkingUpdates);
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
              noUpdateToastText ?? ChewieS.current.checkUpdatesFailed);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            ChewieS.current.checkUpdatesFailed,
            body: ChewieS.current.checkUpdatesFailedTip,
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
              title: ChewieS.current.getNewVersion(latestVersion),
              message: ChewieS.current.doesImmediateUpdate +
                  ChewieS.current.changelogAsFollow(
                      "<br/>${StringUtil.replaceLineBreak(latestReleaseItem.body ?? "")}"),
              confirmButtonText: ResponsiveUtil.isAndroid()
                  ? ChewieS.current.immediatelyDownload
                  : ChewieS.current.goToUpdate,
              cancelButtonText: ChewieS.current.updateLater,
              onTapConfirm: () async {
                if (ResponsiveUtil.isAndroid()) {
                  ReleaseAsset androidAssset = await FileUtil.getAndroidAsset(
                      latestVersion, latestReleaseItem!);
                  ILogger.info(ResponsiveUtil.appName,
                      "Get android asset: $androidAssset");
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
              ChewieUtils.displayApp();
            }

            if (showDesktopNotification) {
              IToast.showDesktopNotification(
                ChewieS.current.getNewVersion(latestVersion),
                body: ChewieS.current
                    .changelogAsFollow("\n${latestReleaseItem.body ?? ""}"),
                actions: [
                  ChewieS.current.updateLater,
                  ChewieS.current.goToUpdate
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
          IToast.showTop(ChewieS.current.alreadyLatestVersion);
        }
        if (showDesktopNotification) {
          IToast.showDesktopNotification(
            ChewieS.current.alreadyLatestVersion,
            body: ChewieS.current.alreadyLatestVersionTip(currentVersion),
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
        IToast.showTop(ChewieS.current.biometricNotAvailable);
      } else if (e.code == auth_error.notEnrolled) {
        IToast.showTop(ChewieS.current.biometricNotEnrolled);
      } else if (e.code == auth_error.lockedOut) {
        IToast.showTop(ChewieS.current.biometricLockout);
      } else if (e.code == auth_error.permanentlyLockedOut) {
        IToast.showTop(ChewieS.current.biometricLockoutPermanent);
      } else {
        IToast.showTop(ChewieS.current.biometricOtherReason(e));
      }
    } catch (e, t) {
      ILogger.error("Failed to local authenticate", e, t);
    }
  }
}
