import 'dart:convert';

import 'package:cloudotp/Resources/theme_color_data.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/Utils/enums.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'constant.dart';

class HiveUtil {
  //Database
  static const String database = "CloudOTP";

  //HiveBox
  static const String settingsBox = "settings";

  //Auth
  static const String deviceIdKey = "deviceId";
  static const String cookieKey = "cookieKey";

  //General
  static const String layoutTypeKey = "layoutType";
  static const String autoCompleteParameterKey = "autoCompleteParameter";
  static const String localeKey = "locale";
  static const String recordWindowStateKey = "recordWindowState";
  static const String windowSizeKey = "windowSize";
  static const String windowPositionKey = "windowPosition";
  static const String enableCloseToTrayKey = "enableCloseToTray";
  static const String enableCloseNoticeKey = "enableCloseNotice";
  static const String autoCheckUpdateKey = "autoCheckUpdate";
  static const String inappWebviewKey = "inappWebview";

  //Appearance
  static const String enableLandscapeInTabletKey = "enableLandscapeInTablet";
  static const String fontFamilyKey = "fontFamily";
  static const String lightThemeIndexKey = "lightThemeIndex";
  static const String darkThemeIndexKey = "darkThemeIndex";
  static const String lightThemePrimaryColorIndexKey =
      "lightThemePrimaryColorIndex";
  static const String darkThemePrimaryColorIndexKey =
      "darkThemePrimaryColorIndex";
  static const String customLightThemePrimaryColorKey =
      "customLightThemePrimaryColor";
  static const String customDarkThemePrimaryColorKey =
      "customDarkThemePrimaryColor";
  static const String customLightThemeListKey = "customLightThemeList";
  static const String customDarkThemeListKey = "customDarkThemeListKey";
  static const String themeModeKey = "themeMode";
  static const String navItemsKey = "navItems";

  //Privacy
  static const String enableGuesturePasswdKey = "enableGuesturePasswd";
  static const String guesturePasswdKey = "guesturePasswd";
  static const String enableBiometricKey = "enableBiometric";
  static const String autoLockKey = "autoLock";
  static const String autoLockTimeKey = "autoLockTime";
  static const String enableSafeModeKey = "enableSafeMode";

  //System
  static const String firstLoginKey = "firstLogin";

  static initConfig() async {
    HiveUtil.put(HiveUtil.inappWebviewKey, true);
  }

  static setLayoutType(LayoutType type) {
    HiveUtil.put(HiveUtil.layoutTypeKey, type.index);
  }

  static LayoutType getLayoutType() {
    return LayoutType.values[Utils.patchEnum(
        HiveUtil.getInt(HiveUtil.layoutTypeKey), LayoutType.values.length)];
  }

  static void setWindowSize(Size size) {
    HiveUtil.put(HiveUtil.windowSizeKey, "${size.width},${size.height}");
  }

  static Size getWindowSize() {
    if (!HiveUtil.getBool(HiveUtil.recordWindowStateKey)) {
      return defaultWindowSize;
    }
    String? size = HiveUtil.getString(HiveUtil.windowSizeKey);
    if (size == null || size.isEmpty) {
      return defaultWindowSize;
    }
    try {
      List<String> list = size.split(",");
      return Size(double.parse(list[0]), double.parse(list[1]));
    } catch (e) {
      return defaultWindowSize;
    }
  }

  static void setWindowPosition(Offset offset) {
    HiveUtil.put(HiveUtil.windowPositionKey, "${offset.dx},${offset.dy}");
  }

  static Offset getWindowPosition() {
    if (!HiveUtil.getBool(HiveUtil.recordWindowStateKey)) return Offset.zero;
    String? position = HiveUtil.getString(HiveUtil.windowPositionKey);
    if (position == null || position.isEmpty) {
      return Offset.zero;
    }
    try {
      List<String> list = position.split(",");
      return Offset(double.parse(list[0]), double.parse(list[1]));
    } catch (e) {
      return Offset.zero;
    }
  }

  static bool isFirstLogin() {
    if (getBool(firstLoginKey, defaultValue: true) == true) return true;
    return false;
  }

  static void setFirstLogin() {
    HiveUtil.put(firstLoginKey, false);
  }

  static Locale? stringToLocale(String? localeString) {
    if (localeString == null || localeString.isEmpty) {
      return null;
    }
    var splitted = localeString.split('_');
    if (splitted.length > 1) {
      return Locale(splitted[0], splitted[1]);
    } else {
      return Locale(localeString);
    }
  }

  static Locale? getLocale() {
    return stringToLocale(HiveUtil.getString(HiveUtil.localeKey));
  }

  static void setLocale(Locale? locale) {
    if (locale == null) {
      HiveUtil.delete(HiveUtil.localeKey);
    } else {
      HiveUtil.put(HiveUtil.localeKey, locale.toString());
    }
  }

  static int? getFontSize() {
    return 2;
    // return HiveUtil.getInt( HiveUtil.fontSizeKey,defaultValue: 2);
  }

  static void setFontSize(int? fontSize) {
    HiveUtil.put(HiveUtil.fontFamilyKey, fontSize);
  }

  static ActiveThemeMode getThemeMode() {
    return ActiveThemeMode.values[HiveUtil.getInt(HiveUtil.themeModeKey)];
  }

  static void setThemeMode(ActiveThemeMode themeMode) {
    HiveUtil.put(HiveUtil.themeModeKey, themeMode.index);
  }

  static int getLightThemeIndex() {
    int index = HiveUtil.getInt(HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return Utils.patchEnum(index, ThemeColorData.defaultLightThemes.length);
    }
  }

  static int getDarkThemeIndex() {
    int index = HiveUtil.getInt(HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        return 0;
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          return 0;
        } else {
          return index;
        }
      }
    } else {
      return Utils.patchEnum(index, ThemeColorData.defaultDarkThemes.length);
    }
  }

  static ThemeColorData getLightTheme() {
    int index = HiveUtil.getInt(HiveUtil.lightThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultLightThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customLightThemeListKey);
      if (json == null || json.isEmpty) {
        setLightTheme(0);
        return ThemeColorData.defaultLightThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultLightThemes.length + list.length) {
          setLightTheme(0);
          return ThemeColorData.defaultLightThemes[0];
        } else {
          return ThemeColorData.fromJson(
              list[index - ThemeColorData.defaultLightThemes.length]);
        }
      }
    } else {
      return ThemeColorData.defaultLightThemes[
          Utils.patchEnum(index, ThemeColorData.defaultLightThemes.length)];
    }
  }

  static ThemeColorData getDarkTheme() {
    int index = HiveUtil.getInt(HiveUtil.darkThemeIndexKey, defaultValue: 0);
    if (index > ThemeColorData.defaultDarkThemes.length) {
      String? json = HiveUtil.getString(HiveUtil.customDarkThemeListKey);
      if (json == null || json.isEmpty) {
        setDarkTheme(0);
        return ThemeColorData.defaultDarkThemes[0];
      } else {
        List<dynamic> list = jsonDecode(json);
        if (index > ThemeColorData.defaultDarkThemes.length + list.length) {
          setDarkTheme(0);
          return ThemeColorData.defaultDarkThemes[0];
        } else {
          return ThemeColorData.fromJson(
              list[index - ThemeColorData.defaultDarkThemes.length]);
        }
      }
    } else {
      return ThemeColorData.defaultDarkThemes[
          Utils.patchEnum(index, ThemeColorData.defaultDarkThemes.length)];
    }
  }

  static void setLightTheme(int index) =>
      HiveUtil.put(HiveUtil.lightThemeIndexKey, index);

  static void setDarkTheme(int index) =>
      HiveUtil.put(HiveUtil.darkThemeIndexKey, index);

  static bool shouldAutoLock() =>
      canLock() && HiveUtil.getBool(HiveUtil.autoLockKey);

  static bool canLock() =>
      HiveUtil.getBool(HiveUtil.enableGuesturePasswdKey) &&
      HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;

  static Map<String, String> getCookie() {
    Map<String, String> map = {};
    String str = getString(cookieKey) ?? "";
    if (str.isNotEmpty) {
      List<String> list = str.split("; ");
      for (String item in list) {
        int equalIndex = item.indexOf("=");
        if (equalIndex != -1) {
          map[item.substring(0, equalIndex)] = item.substring(equalIndex + 1);
        }
      }
    }
    return map;
  }

  static int getInt(
    String key, {
    String boxName = HiveUtil.settingsBox,
    int defaultValue = 0,
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static bool getBool(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool defaultValue = true,
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static String? getString(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool autoCreate = true,
    String? defaultValue,
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static Map<String, dynamic> getMap(
    String key, {
    String boxName = HiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(name: boxName);
    Map<String, dynamic> res = {};
    if (box.get(key) != null) {
      res = Map<String, dynamic>.from(box.get(key));
    }
    return res;
  }

  static List<dynamic>? getList(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool autoCreate = true,
    List<dynamic> defaultValue = const [],
  }) {
    final Box box = Hive.box(name: boxName);
    if (!box.containsKey(key)) {
      if (!autoCreate) {
        return null;
      }
      put(key, defaultValue, boxName: boxName);
    }
    return box.get(key);
  }

  static List<String>? getStringList(
    String key, {
    String boxName = HiveUtil.settingsBox,
    bool autoCreate = true,
    List<dynamic> defaultValue = const [],
  }) {
    return getList(
      key,
      boxName: boxName,
      autoCreate: autoCreate,
      defaultValue: defaultValue,
    )!
        .map((e) => e.toString())
        .toList();
  }

  static Future<void> put(
    String key,
    dynamic value, {
    String boxName = HiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(name: boxName);
    return box.put(key, value);
  }

  static Future<void> delete(
    String key, {
    String boxName = HiveUtil.settingsBox,
  }) async {
    final Box box = Hive.box(name: boxName);
    box.delete(key);
  }

  static bool contains(
    String key, {
    String boxName = HiveUtil.settingsBox,
  }) {
    final Box box = Hive.box(name: boxName);
    return box.containsKey(key);
  }
}
