import 'dart:io';

import 'package:cloudotp/Utils/route_util.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
import 'package:window_manager/window_manager.dart';

import '../Screens/main_screen.dart';
import 'app_provider.dart';

class ResponsiveUtil {
  static String deviceName = "";

  static init() async {
    deviceName = await getDeviceName();
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

  static Future<void> restartApp(BuildContext context) async {
    if (ResponsiveUtil.isDesktop()) {
    } else {
      Restart.restartApp();
    }
  }

  static Future<void> returnToMainScreen(BuildContext context) async {
    if (ResponsiveUtil.isDesktop()) {
      desktopNavigatorKey = GlobalKey<NavigatorState>();
      globalNavigatorState?.pushAndRemoveUntil(
        RouteUtil.getFadeRoute(const MainScreen(), duration: Duration.zero),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => const MainScreen()),
          (route) => false);
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
    double longestSide = MediaQuery.sizeOf(rootContext).longestSide;
    double shortestSide = MediaQuery.sizeOf(rootContext).shortestSide;
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
    Orientation orientation = MediaQuery.of(rootContext).orientation;
    return isTablet() && orientation == Orientation.landscape;
  }

  static bool isTablet() {
    double shortestThreshold = 600;
    double longestThreshold = 900;
    double longestSide = MediaQuery.sizeOf(rootContext).longestSide;
    double shortestSide = MediaQuery.sizeOf(rootContext).shortestSide;
    bool sizeCondition =
        longestSide >= longestThreshold && shortestSide >= shortestThreshold;
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid) && sizeCondition;
  }

  static bool isPortaitTablet() {
    Orientation orientation = MediaQuery.of(rootContext).orientation;
    return isTablet() && orientation == Orientation.portrait;
  }

  static bool isLandscape([bool useAppProvider = true]) {
    return isWeb() ||
        isDesktop() ||
        (useAppProvider &&
            appProvider.enableLandscapeInTablet &&
            isLandscapeTablet());
  }

  static bool isWideLandscape([bool useAppProvider = true]) {
    return isWeb() ||
        isDesktop() ||
        (useAppProvider && appProvider.enableLandscapeInTablet && isTablet());
  }
}
