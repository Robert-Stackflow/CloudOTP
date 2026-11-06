import 'System/screen_protection_coordinator.dart';
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
  static final _iosProtection = ScreenProtectionCoordinator();

  static Future<void> setSafeMode(bool enabled) async {
    if (ResponsiveUtil.isIOS()) {
      try {
        await _iosProtection.set(enabled, (value) async {
          if (value) { await enableSafeMode(); } else { await disableSafeMode(); }
        });
      } catch (error, stack) {
        ILogger.error('Unable to update iOS screen protection', error, stack);
      }
      return;
    }
    if (ResponsiveUtil.isMobile()) {
      if (enabled) {
        enableSafeMode();
      } else {
        disableSafeMode();
      }
    }
  }

  static Future<void> enableSafeMode() async {
    if (ResponsiveUtil.isIOS()) {
      await ScreenProtector.preventScreenshotOn();
      // Legacy inactive covers also obscure Face ID. A scene-aware native
      // cover now handles actual background entry, while screenshot prevention
      // stays enabled independently.
      await ScreenProtector.protectDataLeakageOff();
      await const MethodChannel('cloudotp/ios').invokeMethod('setPrivacyCover', {'enabled': true});
    } else if (ResponsiveUtil.isAndroid()) {
      await ScreenProtector.protectDataLeakageOn();
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  static Future<void> disableSafeMode() async {
    if (ResponsiveUtil.isIOS()) {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      await const MethodChannel('cloudotp/ios').invokeMethod('setPrivacyCover', {'enabled': false});
    } else if (ResponsiveUtil.isAndroid()) {
      await ScreenProtector.protectDataLeakageOff();
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

  static Timer? _clipboardClearTimer;

  static void copy(
    BuildContext context,
    dynamic data, {
    String? toastText,
    bool autoClear = false,
    Duration autoClearDuration = const Duration(seconds: 30),
  }) async {
    if (ResponsiveUtil.isIOS()) {
      if (!await awaitIOSCopy(data.toString(), autoClear ? autoClearDuration : null)) return;
      if ((toastText ?? chewieLocalizations.copySuccess).isNotEmpty) {
        IToast.showTop(toastText ?? chewieLocalizations.copySuccess);
      }
      HapticFeedback.mediumImpact();
      return;
    }
    Clipboard.setData(ClipboardData(text: data.toString())).then((value) {
      toastText ??= chewieLocalizations.copySuccess;
      if (toastText.notNullOrEmpty) {
        IToast.showTop(toastText ?? "",
            icon: const Icon(LucideIcons.copyCheck));
      }
    });
    HapticFeedback.mediumImpact();
    if (autoClear) {
      _clipboardClearTimer?.cancel();
      _clipboardClearTimer = Timer(autoClearDuration, () {
        Clipboard.setData(const ClipboardData(text: ''));
      });
    }
  }

  static Future<bool> awaitIOSCopy(String text, Duration? expiration) async {
    try {
      await const MethodChannel('cloudotp/ios').invokeMethod('copy', {
        'text': text,
        'expiresIn': expiration?.inSeconds,
      });
      return true;
    } on PlatformException catch (error, stack) {
      ILogger.error('Unable to copy to iOS pasteboard', error, stack);
      IToast.showTop(error.message ?? 'Unable to copy');
      return false;
    }
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
