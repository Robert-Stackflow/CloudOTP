import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Resources/theme_color_data.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/main_screen.dart';
import 'package:cloudotp/Utils/Tuple/tuple.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Custom/loading_icon.dart';
import 'package:cloudotp/Widgets/Dialog/widgets/dialog_wrapper_widget.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:queue/queue.dart';

import '../Resources/fonts.dart';
import '../Screens/home_screen.dart';
import '../Widgets/Custom/keyboard_handler.dart';
import '../generated/l10n.dart';
import 'enums.dart';
import 'hive_util.dart';

GlobalKey<NavigatorState> desktopNavigatorKey = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get desktopNavigatorState => desktopNavigatorKey.currentState;

NavigatorState? get globalNavigatorState => globalNavigatorKey.currentState;

GlobalKey<GeneralSettingScreenState> generalSettingScreenKey =
    GlobalKey<GeneralSettingScreenState>();

GeneralSettingScreenState? get generalSettingScreenState =>
    generalSettingScreenKey.currentState;

GlobalKey<DialogWrapperWidgetState> dialogNavigatorKey =
    GlobalKey<DialogWrapperWidgetState>();

DialogWrapperWidgetState? get dialogNavigatorState =>
    dialogNavigatorKey.currentState;

GlobalKey<MyScaffoldState> homeScaffoldKey = GlobalKey<MyScaffoldState>();

MyScaffoldState? get homeScaffoldState => homeScaffoldKey.currentState;

GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

GlobalKey<KeyboardHandlerState> keyboardHandlerKey =
    GlobalKey<KeyboardHandlerState>();

HomeScreenState? get homeScreenState => homeScreenKey.currentState;

MainScreenState? get mainScreenState => mainScreenKey.currentState;

KeyboardHandlerState? get keyboardHandlerState =>
    keyboardHandlerKey.currentState;

BuildContext get rootContext => globalNavigatorState!.context;

bool get canPopByKey =>
    desktopNavigatorState != null && desktopNavigatorState!.canPop();

RouteObserver<PageRoute> routeObserver = RouteObserver();

Queue autoBackupQueue = Queue();

AppProvider appProvider = AppProvider();

enum AutoLockTime {
  immediately,
  after30Seconds,
  after1Minute,
  after3Minutes,
  after5Minutes,
  after10Minutes;

  int get seconds {
    switch (this) {
      case AutoLockTime.immediately:
        return 0;
      case AutoLockTime.after30Seconds:
        return 30;
      case AutoLockTime.after1Minute:
        return 60;
      case AutoLockTime.after3Minutes:
        return 60 * 3;
      case AutoLockTime.after5Minutes:
        return 60 * 5;
      case AutoLockTime.after10Minutes:
        return 60 * 10;
    }
  }

  String get label {
    switch (this) {
      case AutoLockTime.immediately:
        return S.current.immediatelyLock;
      case AutoLockTime.after30Seconds:
        return S.current.after30SecondsLock;
      case AutoLockTime.after1Minute:
        return S.current.after1MinuteLock;
      case AutoLockTime.after3Minutes:
        return S.current.after3MinutesLock;
      case AutoLockTime.after5Minutes:
        return S.current.after5MinutesLock;
      case AutoLockTime.after10Minutes:
        return S.current.after10MinutesLock;
      default:
        return "";
    }
  }

  static List<Tuple2<String, AutoLockTime>> options() {
    return [
      Tuple2(S.current.immediatelyLock, AutoLockTime.immediately),
      Tuple2(S.current.after30SecondsLock, AutoLockTime.after30Seconds),
      Tuple2(S.current.after1MinuteLock, AutoLockTime.after1Minute),
      Tuple2(S.current.after3MinutesLock, AutoLockTime.after3Minutes),
      Tuple2(S.current.after5MinutesLock, AutoLockTime.after5Minutes),
      Tuple2(S.current.after10MinutesLock, AutoLockTime.after10Minutes),
    ];
  }
}

class AppProvider with ChangeNotifier {
  String currentDatabasePassword = "";

  String latestVersion = "";

  bool hasJumpToFilePicker = false;

  final List<AutoBackupLog> _autoBackupLogs = [];

  List<AutoBackupLog> get autoBackupLogs => _autoBackupLogs;

  pushAutoBackupLog(AutoBackupLog value) {
    _autoBackupLogs.insert(0, value);
    notifyListeners();
  }

  clearAutoBackupLogs() {
    _autoBackupLogs.removeWhere((element) => element.lastStatus.isCompleted);
    notifyListeners();
  }

  LoadingStatus _autoBackupStatus = LoadingStatus.none;

  LoadingStatus get autoBackupLoadingStatus => _autoBackupStatus;

  set autoBackupLoadingStatus(LoadingStatus value) {
    _autoBackupStatus = value;
    notifyListeners();
  }

  bool _showCloudEntry = false;

  bool get canShowCloudBackupButton => _showCloudEntry;

  set canShowCloudBackupButton(bool value) {
    _showCloudEntry = value;
    notifyListeners();
  }

  bool _autoHideCode = HiveUtil.getBool(HiveUtil.autoHideCodeKey);

  bool get autoHideCode => _autoHideCode;

  set autoHideCode(bool value) {
    _autoHideCode = value;
    HiveUtil.put(HiveUtil.autoHideCodeKey, value);
    notifyListeners();
  }

  bool _autoDisplayNextCode = HiveUtil.getBool(HiveUtil.autoDisplayNextCodeKey);

  bool get autoDisplayNextCode => _autoDisplayNextCode;

  set autoDisplayNextCode(bool value) {
    _autoDisplayNextCode = value;
    HiveUtil.put(HiveUtil.autoDisplayNextCodeKey, value);
    notifyListeners();
  }

  bool _hideProgressBar = HiveUtil.getBool(HiveUtil.hideProgressBarKey);

  bool get hideProgressBar => _hideProgressBar;

  set hideProgressBar(bool value) {
    _hideProgressBar = value;
    HiveUtil.put(HiveUtil.hideProgressBarKey, value);
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

  bool _showCloudBackupButton = HiveUtil.getBool(
      HiveUtil.showCloudBackupButtonKey,
      defaultValue: ResponsiveUtil.isLandscape(false));

  bool get showCloudBackupButton => _showCloudBackupButton;

  set showCloudBackupButton(bool value) {
    _showCloudBackupButton = value;
    HiveUtil.put(HiveUtil.showCloudBackupButtonKey, value);
    notifyListeners();
  }

  bool _showLayoutButton = HiveUtil.getBool(HiveUtil.showLayoutButtonKey);

  bool get showLayoutButton => _showLayoutButton;

  set showLayoutButton(bool value) {
    _showLayoutButton = value;
    HiveUtil.put(HiveUtil.showLayoutButtonKey, value);
    notifyListeners();
  }

  bool _showSortButton = HiveUtil.getBool(HiveUtil.showSortButtonKey);

  bool get showSortButton => _showSortButton;

  set showSortButton(bool value) {
    _showSortButton = value;
    HiveUtil.put(HiveUtil.showSortButtonKey, value);
    notifyListeners();
  }

  bool _showBackupLogButton = HiveUtil.getBool(HiveUtil.showBackupLogButtonKey,
      defaultValue: ResponsiveUtil.isLandscape(false));

  bool get showBackupLogButton => _showBackupLogButton;

  set showBackupLogButton(bool value) {
    _showBackupLogButton = value;
    HiveUtil.put(HiveUtil.showBackupLogButtonKey, value);
    notifyListeners();
  }

  bool _dragToReorder = HiveUtil.getBool(HiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());

  bool get dragToReorder => _dragToReorder;

  set dragToReorder(bool value) {
    _dragToReorder = value;
    HiveUtil.put(HiveUtil.dragToReorderKey, value);
    notifyListeners();
  }

  bool _enableFrostedGlassEffect = HiveUtil.getBool(
      HiveUtil.enableFrostedGlassEffectKey,
      defaultValue: false);

  bool get enableFrostedGlassEffect => _enableFrostedGlassEffect;

  set enableFrostedGlassEffect(bool value) {
    _enableFrostedGlassEffect = value;
    HiveUtil.put(HiveUtil.enableFrostedGlassEffectKey, value);
    notifyListeners();
  }

  bool _hideAppbarWhenScrolling =
      HiveUtil.getBool(HiveUtil.hideAppbarWhenScrollingKey);

  bool get hideAppbarWhenScrolling => _hideAppbarWhenScrolling;

  set hideAppbarWhenScrolling(bool value) {
    _hideAppbarWhenScrolling = value;
    HiveUtil.put(HiveUtil.hideAppbarWhenScrollingKey, value);
    notifyListeners();
  }

  bool _hideBottombarWhenScrolling =
      HiveUtil.getBool(HiveUtil.hideBottombarWhenScrollingKey);

  bool get hideBottombarWhenScrolling => _hideBottombarWhenScrolling;

  set hideBottombarWhenScrolling(bool value) {
    _hideBottombarWhenScrolling = value;
    HiveUtil.put(HiveUtil.hideBottombarWhenScrollingKey, value);
    notifyListeners();
  }

  Map<Type, Action<Intent>> _dynamicShortcuts =
      KeyboardHandlerState.mainScreenShortcuts;

  Map<Type, Action<Intent>> get dynamicShortcuts => _dynamicShortcuts;

  set dynamicShortcuts(Map<Type, Action<Intent>> value) {
    _dynamicShortcuts = value;
    notifyListeners();
  }

  ThemeColorData _lightTheme = HiveUtil.getLightTheme();

  ThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ThemeColorData value) {
    _lightTheme = value;
    notifyListeners();
  }

  setLightTheme(int index) {
    HiveUtil.setLightTheme(index);
    _lightTheme = HiveUtil.getLightTheme();
    notifyListeners();
  }

  ThemeColorData _darkTheme = HiveUtil.getDarkTheme();

  ThemeColorData get darkTheme => _darkTheme;

  set darkTheme(ThemeColorData value) {
    _darkTheme = value;
    notifyListeners();
  }

  setDarkTheme(int index) {
    HiveUtil.setDarkTheme(index);
    _darkTheme = HiveUtil.getDarkTheme();
    notifyListeners();
  }

  CustomFont _currentFont = CustomFont.getCurrentFont();

  CustomFont get currentFont => _currentFont;

  set currentFont(CustomFont value) {
    _currentFont = value;
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

  AutoLockTime _autoLockTime = HiveUtil.getAutoLockTime();

  AutoLockTime get autoLockTime => _autoLockTime;

  set autoLockTime(AutoLockTime value) {
    if (value != _autoLockTime) {
      _autoLockTime = value;
      notifyListeners();
      HiveUtil.setAutoLockTime(value);
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
