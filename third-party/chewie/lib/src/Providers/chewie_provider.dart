import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

ChewieProvider chewieProvider = ChewieProvider();

class ChewieProvider with ChangeNotifier {
  Size defaultWindowSize = const Size(1280, 720);
  Size minimumWindowSize = const Size(1000, 640);

  String latestVersion = "";

  Size _windowSize = ChewieHiveUtil.getWindowSize();

  Size get windowSize => _windowSize;

  set windowSize(Size value) {
    _windowSize = value;
    ChewieHiveUtil.setWindowSize(value);
    notifyListeners();
  }

  Offset _mousePosition = ChewieHiveUtil.getWindowPosition();

  Offset get mousePosition => _mousePosition;

  set mousePosition(Offset value) {
    _mousePosition = value;
    notifyListeners();
  }

  Offset _windowPosition = Offset.zero;

  Offset get windowPosition => _windowPosition;

  set windowPosition(Offset value) {
    _windowPosition = value;
    ChewieHiveUtil.setWindowPosition(value);
    notifyListeners();
  }

  Widget Function(double size, bool forceDark) loadingWidgetBuilder =
      (size, forceDark) => const Center(child: CircularProgressIndicator());

  RouteObserver routeObserver = RouteObserver();

  GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

  BuildContext get rootContext => globalNavigatorState!.context;

  GlobalKey<DialogWrapperWidgetState> dialogNavigatorKey =
      GlobalKey<DialogWrapperWidgetState>();

  DialogWrapperWidgetState? get dialogNavigatorState =>
      dialogNavigatorKey.currentState;

  GlobalKey<BasePanelScreenState> panelScreenKey =
      GlobalKey<BasePanelScreenState>();

  BasePanelScreenState? get panelScreenState => panelScreenKey.currentState;

  CustomFont _currentFont = CustomFont.getCurrentFont();

  CustomFont get currentFont => _currentFont;

  set currentFont(CustomFont value) {
    _currentFont = value;
    notifyListeners();
  }

  ProxyConfig _proxyConfig = ChewieHiveUtil.getProxyConfig() ??
      ProxyConfig(proxyType: ProxyType.NoProxy);

  ProxyConfig get proxyConfig => _proxyConfig;

  set proxyConfig(ProxyConfig value) {
    _proxyConfig = value;
    ChewieHiveUtil.setProxyConfig(value);
    notifyListeners();
    ProxyUtil.refresh();
  }

  bool _enableLandscapeInTablet =
      ChewieHiveUtil.getBool(ChewieHiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    ChewieHiveUtil.put(ChewieHiveUtil.enableLandscapeInTabletKey, value);
    notifyListeners();
  }

  ChewieThemeColorData _lightTheme = ChewieHiveUtil.getLightTheme();

  ChewieThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ChewieThemeColorData value) {
    _lightTheme = value;
    notifyListeners();
  }

  setLightTheme(int index) {
    ChewieHiveUtil.setLightTheme(index);
    _lightTheme = ChewieHiveUtil.getLightTheme();
    notifyListeners();
  }

  ChewieThemeColorData _darkTheme = ChewieHiveUtil.getDarkTheme();

  ChewieThemeColorData get darkTheme => _darkTheme;

  set darkTheme(ChewieThemeColorData value) {
    _darkTheme = value;
    notifyListeners();
  }

  setDarkTheme(int index) {
    ChewieHiveUtil.setDarkTheme(index);
    _darkTheme = ChewieHiveUtil.getDarkTheme();
    notifyListeners();
  }

  static List<SelectionItemModel<ActiveThemeMode>> getSupportedThemeMode() {
    return [
      SelectionItemModel(ChewieS.current.followSystem, ActiveThemeMode.system),
      SelectionItemModel(ChewieS.current.lightTheme, ActiveThemeMode.light),
      SelectionItemModel(ChewieS.current.darkTheme, ActiveThemeMode.dark),
    ];
  }

  Locale? _locale = ChewieHiveUtil.getLocale();

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value != _locale) {
      _locale = value;
      notifyListeners();
      ChewieHiveUtil.setLocale(value);
    }
  }

  int? _fontSize = ChewieHiveUtil.getFontSize();

  int? get fontSize => _fontSize;

  set fontSize(int? value) {
    if (value != _fontSize) {
      _fontSize = value;
      notifyListeners();
      ChewieHiveUtil.setFontSize(value);
    }
  }

  ActiveThemeMode _themeMode = ChewieHiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
      ChewieHiveUtil.setThemeMode(value);
    }
  }

  static String getThemeModeLabel(ActiveThemeMode themeMode) {
    switch (themeMode) {
      case ActiveThemeMode.system:
        return ChewieS.current.followSystem;
      case ActiveThemeMode.light:
        return ChewieS.current.lightTheme;
      case ActiveThemeMode.dark:
        return ChewieS.current.darkTheme;
    }
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

abstract class BasePanelScreenState<T extends StatefulWidget> extends State<T> {
  FutureOr pushPage(Widget page);

  FutureOr popPage();

  void updateStatusBar();

  void refreshScrollControllers();

  void showBottomNavigationBar();

  FutureOr popAll([bool initPage = true]);

  void jumpToPage(int index);
}
