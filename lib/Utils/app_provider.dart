import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../Screens/home_screen.dart';
import '../generated/l10n.dart';
import 'enums.dart';
import 'hive_util.dart';

GlobalKey<NavigatorState> desktopNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get desktopNavigatorState => desktopNavigatorKey.currentState;

NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

GlobalKey<DialogWrapperWidgetState> dialogNavigatorKey =
    GlobalKey<DialogWrapperWidgetState>();

DialogWrapperWidgetState? get dialogNavigatorState =>
    dialogNavigatorKey.currentState;

GlobalKey<MyScaffoldState> homeScaffoldKey = GlobalKey<MyScaffoldState>();

MyScaffoldState? get homeScaffoldState => homeScaffoldKey.currentState;

GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

HomeScreenState? get homeScreenState => homeScreenKey.currentState;

BuildContext get rootContext => globalNavigatorState!.context;

bool get canPopByKey =>
    desktopNavigatorState != null && desktopNavigatorState!.canPop();

RouteObserver<PageRoute> routeObserver = RouteObserver();

AppProvider appProvider = AppProvider();

class AppProvider with ChangeNotifier {
  String _captchaToken = "";

  String get captchaToken => _captchaToken;

  set captchaToken(String value) {
    _captchaToken = value;
    notifyListeners();
  }

  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    HiveUtil.put(HiveUtil.enableLandscapeInTabletKey, value).then((value) {
      ResponsiveUtil.restartApp(rootContext);
    });
    notifyListeners();
  }

  bool _canPopByProvider = false;

  bool get canPopByProvider => _canPopByProvider;

  set canPopByProvider(bool value) {
    _canPopByProvider = value;
    notifyListeners();
  }

  ThemeData _lightTheme = HiveUtil.getLightTheme().toThemeData();

  ThemeData get lightTheme => _lightTheme;

  setLightTheme(int index) {
    HiveUtil.setLightTheme(index);
    _lightTheme = HiveUtil.getLightTheme().toThemeData();
    notifyListeners();
  }

  ThemeData _darkTheme = HiveUtil.getDarkTheme().toThemeData();

  ThemeData get darkTheme => _darkTheme;

  setDarkTheme(int index) {
    HiveUtil.setDarkTheme(index);
    _darkTheme = HiveUtil.getDarkTheme().toThemeData();
    notifyListeners();
  }

  Locale? _locale = HiveUtil.getLocale();

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value != _locale) {
      _locale = value;
      notifyListeners();
      HiveUtil.setLocale(value);
    }
  }

  int? _fontSize = HiveUtil.getFontSize();

  int? get fontSize => _fontSize;

  set fontSize(int? value) {
    if (value != _fontSize) {
      _fontSize = value;
      notifyListeners();
      HiveUtil.setFontSize(value);
    }
  }

  ActiveThemeMode _themeMode = HiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
      HiveUtil.setThemeMode(value);
    }
  }

  static String getThemeModeLabel(ActiveThemeMode themeMode) {
    switch (themeMode) {
      case ActiveThemeMode.system:
        return S.current.followSystem;
      case ActiveThemeMode.light:
        return S.current.lightTheme;
      case ActiveThemeMode.dark:
        return S.current.darkTheme;
    }
  }

  static List<Tuple2<String, ActiveThemeMode>> getSupportedThemeMode() {
    return [
      Tuple2(S.current.followSystem, ActiveThemeMode.system),
      Tuple2(S.current.lightTheme, ActiveThemeMode.light),
      Tuple2(S.current.darkTheme, ActiveThemeMode.dark),
    ];
  }

  int _autoLockTime = HiveUtil.getInt(HiveUtil.autoLockTimeKey);

  int get autoLockTime => _autoLockTime;

  set autoLockTime(int value) {
    if (value != _autoLockTime) {
      _autoLockTime = value;
      notifyListeners();
      HiveUtil.put(HiveUtil.autoLockTimeKey, value);
    }
  }

  static String getAutoLockOptionLabel(int time) {
    if (time == 0)
      return "立即锁定";
    else
      return "处于后台$time分钟后锁定";
  }

  static List<Tuple2<String, int>> getAutoLockOptions() {
    return [
      Tuple2("立即锁定", 0),
      Tuple2("处于后台1分钟后锁定", 1),
      Tuple2("处于后台5分钟后锁定", 5),
      Tuple2("处于后台10分钟后锁定", 10),
    ];
  }

  Brightness? getBrightness() {
    if (_themeMode == ActiveThemeMode.system) {
      return null;
    } else {
      return _themeMode == ActiveThemeMode.light
          ? Brightness.light
          : Brightness.dark;
    }
  }
}
