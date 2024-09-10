import 'package:cloudotp/Utils/utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import './ilogger.dart';

class RequestHeaderUtil {
  static const String defaultMarket = "xiaomi";
  static const String defaultUA =
      "LOFTER-Android 7.8.6 (23127PN0CC; Android 14; null) WIFI";
  static const String defaultDeviceId = "4151dea95acc4a53";
  static const String defaultAndroidId = "4151dea95acc4a53";
  static const String defaultDaDeviceId =
      "2ef9ea6c17b7c6881c71915a4fefd932edc01af0";
  static AndroidDeviceInfo? androidInfo;

  static initAndroidInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      await deviceInfo.androidInfo.then((value) => androidInfo = value);
    } catch (e, t) {
      ILogger.error("CloudOTP","Failed to get android info", e, t);
      androidInfo = null;
    }
  }

  static String getXDevice() {
    return "qv+Dz73SObtbEFG7P0Gq12HkjzNb+iOK6KHWTPKHBTEZu26C6MJOMukkAG7dETo2";
  }

  static String getUA() {
    if (androidInfo == null) {
      return defaultUA;
    }
    return "LOFTER-Android 7.8.6 (${androidInfo!.model}; Android ${androidInfo!.version.release}; null) WIFI";
  }

  static String getMarket() {
    if (androidInfo == null) {
      return "";
    }
    if (Utils.isNotEmpty(androidInfo!.manufacturer)) {
      return androidInfo!.manufacturer;
    }
    if (Utils.isNotEmpty(androidInfo!.brand)) {
      return androidInfo!.brand;
    }
    return "";
  }

  static String getDeviceId() {
    return defaultDeviceId;
  }

  static String getDaDeviceId() {
    return defaultDaDeviceId;
  }

  static String getAndroidId() {
    return defaultAndroidId;
  }

  static String getXReqId({int length = 8}) {
    return Utils.getRandomString(length: length);
  }
}
