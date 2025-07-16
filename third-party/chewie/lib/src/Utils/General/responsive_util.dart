import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shell_executor/shell_executor.dart';
import 'package:window_manager/window_manager.dart';

enum LinuxOSType {
  Gnome,
  KDE;

  String get captureProcessName {
    switch (this) {
      case LinuxOSType.Gnome:
        return "gnome-screenshot";
      case LinuxOSType.KDE:
        return "spectacle";
    }
  }
}

class ResponsiveUtil {
  static String buildNumber = "";
  static String version = "";
  static String appName = "";
  static String packageName = "";
  static String deviceName = "";
  static String deviceDescription = "";
  static const buildType = String.fromEnvironment('BUILD_TYPE');

  static String get platformName {
    if (Platform.isAndroid) {
      return "Android";
    } else if (Platform.isIOS) {
      return "iOS";
    } else if (Platform.isMacOS) {
      return "MacOS";
    } else if (Platform.isWindows) {
      return "Windows";
    } else if (Platform.isLinux) {
      return "Linux";
    } else {
      return "Unknown";
    }
  }

  static bool isAppBundle() {
    ILogger.debug("BUILD_TYPE is $buildType");
    if (Platform.isAndroid) {
      if (buildType == 'appbundle') {
        ILogger.debug("Building appbundle for google play store");
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  static init() async {
    buildNumber = (await PackageInfo.fromPlatform()).buildNumber;
    version = (await PackageInfo.fromPlatform()).version;
    appName = (await PackageInfo.fromPlatform()).appName;
    packageName = (await PackageInfo.fromPlatform()).packageName;
    deviceName = await getDeviceName();
    deviceDescription = await getDeviceDescription();
  }

  static Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return "Android-${(await deviceInfo.androidInfo).brand}-${(await deviceInfo.androidInfo).model}";
    } else if (Platform.isIOS) {
      return "iOS-${(await deviceInfo.iosInfo).name}";
    } else if (Platform.isMacOS) {
      return "MacOS-${(await deviceInfo.macOsInfo).computerName}";
    } else if (Platform.isWindows) {
      return "Windows-${(await deviceInfo.windowsInfo).computerName}";
    } else if (Platform.isLinux) {
      return "Linux-${(await deviceInfo.linuxInfo).prettyName}";
    } else {
      return "Unknown";
    }
  }

  static Future<String> getDeviceDescription() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceOverview = await getDeviceName();
      String deviceDescription = "";
      if (Platform.isAndroid) {
        deviceDescription = (await deviceInfo.androidInfo).data.toString();
      } else if (Platform.isIOS) {
        deviceDescription = (await deviceInfo.iosInfo).data.toString();
      } else if (Platform.isMacOS) {
        deviceDescription = (await deviceInfo.macOsInfo).data.toString();
      } else if (Platform.isWindows) {
        deviceDescription = (await deviceInfo.windowsInfo).data.toString();
      } else if (Platform.isLinux) {
        deviceDescription = (await deviceInfo.linuxInfo).data.toString();
      } else {
        deviceDescription = "Unknown";
      }
      return "Device overview:$deviceOverview\nDevice description:$deviceDescription";
    } catch (e, t) {
      ILogger.error("Failed to device description", e, t);
      return "Get Device Description Error: $e";
    }
  }

  static Future<void> restartApp([BuildContext? context]) async {
    if (ResponsiveUtil.isDesktop()) {
    } else {
      Restart.restartApp();
    }
  }

  static Future<void> maximizeOrRestore() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isWindows() {
    return Platform.isWindows;
  }

  static bool isMacOS() {
    return Platform.isMacOS;
  }

  static bool isLinux() {
    return Platform.isLinux;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isMobile() {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  static bool isDesktop() {
    return !kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  }

  static checkSizeCondition() {
    double shortestThreshold = 600;
    double longestThreshold = 900;
    double longestSide =
        MediaQuery.sizeOf(chewieProvider.rootContext).longestSide;
    double shortestSide =
        MediaQuery.sizeOf(chewieProvider.rootContext).shortestSide;
    bool sizeCondition =
        longestSide >= longestThreshold && shortestSide >= shortestThreshold;
    if (!sizeCondition) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  static bool isLandscapeTablet() {
    Orientation orientation =
        MediaQuery.of(chewieProvider.rootContext).orientation;
    return isTablet() && orientation == Orientation.landscape;
  }

  static bool isTablet() {
    double shortestThreshold = 600;
    double longestThreshold = 900;
    double longestSide =
        MediaQuery.sizeOf(chewieProvider.rootContext).longestSide;
    double shortestSide =
        MediaQuery.sizeOf(chewieProvider.rootContext).shortestSide;
    bool sizeCondition =
        longestSide >= longestThreshold && shortestSide >= shortestThreshold;
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid) && sizeCondition;
  }

  static bool isPortaitTablet() {
    Orientation orientation =
        MediaQuery.of(chewieProvider.rootContext).orientation;
    return isTablet() && orientation == Orientation.portrait;
  }

  static bool isLandscape([bool useAppProvider = true]) {
    return isWeb() ||
        isDesktop() ||
        (useAppProvider &&
            chewieProvider.enableLandscapeInTablet &&
            isLandscapeTablet());
  }

  static Widget buildLandscapeWidget({
    required Widget landscape,
    required Widget portrait,
    bool useAppProvider = true,
    bool andCondition = true,
    bool orCondition = false,
  }) {
    return (isLandscape(useAppProvider) || orCondition) && andCondition
        ? landscape
        : portrait;
  }

  static Widget buildGeneralWidget({
    required Widget desktop,
    required Widget landscape,
    required Widget portrait,
  }) {
    if (!ResponsiveUtil.isLandscape()) {
      return portrait;
    } else if (ResponsiveUtil.isMobile()) {
      return landscape;
    } else {
      return desktop;
    }
  }

  static Widget? buildLandscapeWidgetNullable({
    required Widget? landscape,
    required Widget? portrait,
    bool useAppProvider = true,
    bool andCondition = true,
    bool orCondition = false,
  }) {
    return (isLandscape(useAppProvider) || orCondition) && andCondition
        ? landscape
        : portrait;
  }

  static Widget buildDesktopWidget({
    Widget? desktop,
    Widget? mobile,
    bool useAppProvider = true,
    bool andCondition = true,
    bool orCondition = false,
  }) {
    return (isDesktop() || orCondition) && andCondition
        ? desktop ?? const SizedBox.shrink()
        : mobile ?? const SizedBox.shrink();
  }

  static void doInDesktop({Function()? desktop, Function()? mobile}) {
    if (isDesktop()) {
      desktop?.call();
    } else {
      mobile?.call();
    }
  }

  static void doInLandscape({Function()? landscape, Function()? portrait}) {
    if (isLandscape()) {
      landscape?.call();
    } else {
      portrait?.call();
    }
  }

  static bool isWideLandscape([bool useAppProvider = true]) {
    return isWeb() || isDesktop() || (useAppProvider && isTablet());
  }

  static LinuxOSType getLinuxOSType() {
    if (Platform.isLinux) {
      bool? isKdeDesktop;
      try {
        final result = ShellExecutor.global.execSync('pgrep', ['plasmashell']);
        isKdeDesktop = result.exitCode == 0;
      } catch (_) {
        isKdeDesktop = false;
      }
      if (isKdeDesktop) {
        return LinuxOSType.KDE;
      } else {
        return LinuxOSType.Gnome;
      }
    }
    return LinuxOSType.Gnome;
  }
}
