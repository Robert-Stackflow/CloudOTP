/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/auto_backup_log.dart';
import 'package:cloudotp/Screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:queue/queue.dart';

import '../Screens/home_screen.dart';
import '../l10n/l10n.dart';
import 'hive_util.dart';

GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

MainScreenState? get mainScreenState => mainScreenKey.currentState;

HomeScreenState? get homeScreenState =>
    chewieProvider.panelScreenKey.currentState as HomeScreenState?;

// GlobalKey<KeyboardHandlerState> keyboardHandlerKey =
//     GlobalKey<KeyboardHandlerState>();
//
// KeyboardHandlerState? get keyboardHandlerState =>
//     keyboardHandlerKey.currentState;

Queue autoBackupQueue = Queue();

class GlobalTokenTicker {
  static final GlobalTokenTicker _instance = GlobalTokenTicker._();
  factory GlobalTokenTicker() => _instance;
  GlobalTokenTicker._() {
    _controller = StreamController<void>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  Timer? _timer;
  late final StreamController<void> _controller;

  Stream<void> get stream => _controller.stream;

  void _start() {
    _timer ??= Timer.periodic(
        const Duration(milliseconds: 100), (_) => _controller.add(null));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final globalTokenTicker = GlobalTokenTicker();

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
        return appLocalizations.immediatelyLock;
      case AutoLockTime.after30Seconds:
        return appLocalizations.after30SecondsLock;
      case AutoLockTime.after1Minute:
        return appLocalizations.after1MinuteLock;
      case AutoLockTime.after3Minutes:
        return appLocalizations.after3MinutesLock;
      case AutoLockTime.after5Minutes:
        return appLocalizations.after5MinutesLock;
      case AutoLockTime.after10Minutes:
        return appLocalizations.after10MinutesLock;
    }
  }
}

enum IssuerAndAccountShowOption implements DropdownMixin {
  both,
  issuer,
  account;

  bool get isOnlyIssuer => this == IssuerAndAccountShowOption.issuer;

  bool get isOnlyShowAccount => this == IssuerAndAccountShowOption.account;

  bool get showIssuer =>
      this == IssuerAndAccountShowOption.both ||
      this == IssuerAndAccountShowOption.issuer;

  bool get showAccount =>
      this == IssuerAndAccountShowOption.both ||
      this == IssuerAndAccountShowOption.account;

  bool get showBoth => this == IssuerAndAccountShowOption.both;

  String get label {
    switch (this) {
      case IssuerAndAccountShowOption.issuer:
        return appLocalizations.onlyShowIssuer;
      case IssuerAndAccountShowOption.account:
        return appLocalizations.onlyShowAccount;
      case IssuerAndAccountShowOption.both:
        return appLocalizations.showIssuerAndAccount;
    }
  }

  static List<SelectionItemModel<IssuerAndAccountShowOption>> get options {
    return IssuerAndAccountShowOption.values
        .map(
            (e) => SelectionItemModel<IssuerAndAccountShowOption>(e.display, e))
        .toList();
  }

  SelectionItemModel<IssuerAndAccountShowOption> get selectionItemModel {
    return SelectionItemModel<IssuerAndAccountShowOption>(display, this);
  }

  static IssuerAndAccountShowOption fromInt(int value) {
    return IssuerAndAccountShowOption.values[value.clamp(0, values.length - 1)];
  }

  @override
  String get display => label;

  @override
  String get selection => display;
}

class AutoLockOption implements DropdownMixin {
  final String label;
  final AutoLockTime autoLockTime;

  const AutoLockOption(this.label, this.autoLockTime);

  static List<AutoLockOption> getOptions() {
    return [
      AutoLockOption(
          appLocalizations.immediatelyLock, AutoLockTime.immediately),
      AutoLockOption(
          appLocalizations.after30SecondsLock, AutoLockTime.after30Seconds),
      AutoLockOption(
          appLocalizations.after1MinuteLock, AutoLockTime.after1Minute),
      AutoLockOption(
          appLocalizations.after3MinutesLock, AutoLockTime.after3Minutes),
      AutoLockOption(
          appLocalizations.after5MinutesLock, AutoLockTime.after5Minutes),
      AutoLockOption(
          appLocalizations.after10MinutesLock, AutoLockTime.after10Minutes),
    ];
  }

  static AutoLockOption? fromAutoLockTime(AutoLockTime autoLockTime) {
    return getOptions().firstWhere(
      (option) => option.autoLockTime == autoLockTime,
      orElse: () => getOptions().first,
    );
  }

  @override
  String get display => label;

  @override
  String get selection => display;

  @override
  bool operator ==(Object other) {
    return other is AutoLockOption && autoLockTime == other.autoLockTime;
  }

  @override
  int get hashCode => autoLockTime.hashCode;
}

class AppProvider with ChangeNotifier {
  String currentDatabasePassword = "";

  String latestVersion = "";

  Timer? _preventLockTimer;
  bool _preventLock = false;

  bool get preventLock => _preventLock;

  set preventLock(bool value) {
    _preventLockTimer?.cancel();
    _preventLock = value;
    if (value) {
      _preventLockTimer = Timer(const Duration(minutes: 5), () {
        _preventLock = false;
      });
    }
  }

  FocusNode shortcutFocusNode = FocusNode();
  FocusNode searchFocusNode = FocusNode();

  IssuerAndAccountShowOption _issuerAndAccountShowOption =
      IssuerAndAccountShowOption.fromInt(ChewieHiveUtil.getInt(
          CloudOTPHiveUtil.issuerAndAccountShowOptionKey,
          defaultValue: 0));

  IssuerAndAccountShowOption get issuerAndAccountShowOption =>
      _issuerAndAccountShowOption;

  set issuerAndAccountShowOption(IssuerAndAccountShowOption value) {
    if (value != _issuerAndAccountShowOption) {
      _issuerAndAccountShowOption = value;
      ChewieHiveUtil.put(
          CloudOTPHiveUtil.issuerAndAccountShowOptionKey, value.index);
      notifyListeners();
    }
  }

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

  bool _autoHideCode = ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoHideCodeKey);

  bool get autoHideCode => _autoHideCode;

  set autoHideCode(bool value) {
    _autoHideCode = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.autoHideCodeKey, value);
    notifyListeners();
  }

  bool _autoDisplayNextCode =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoDisplayNextCodeKey);

  bool get autoDisplayNextCode => _autoDisplayNextCode;

  set autoDisplayNextCode(bool value) {
    _autoDisplayNextCode = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.autoDisplayNextCodeKey, value);
    notifyListeners();
  }

  bool _hideProgressBar =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideProgressBarKey);

  bool get hideProgressBar => _hideProgressBar;

  set hideProgressBar(bool value) {
    _hideProgressBar = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.hideProgressBarKey, value);
    notifyListeners();
  }

  bool _showEye =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showEyeKey, defaultValue: false);

  bool get showEye => _showEye;

  set showEye(bool value) {
    _showEye = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.showEyeKey, value);
    notifyListeners();
  }

  bool _enableLandscapeInTablet =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableLandscapeInTabletKey);

  bool get enableLandscapeInTablet => _enableLandscapeInTablet;

  set enableLandscapeInTablet(bool value) {
    _enableLandscapeInTablet = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.enableLandscapeInTabletKey, value)
        .then((value) {
      ResponsiveUtil.restartApp(chewieProvider.rootContext);
    });
    notifyListeners();
  }

  bool _showCloudBackupButton = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.showCloudBackupButtonKey,
      defaultValue: true);

  bool get showCloudBackupButton => _showCloudBackupButton;

  set showCloudBackupButton(bool value) {
    _showCloudBackupButton = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.showCloudBackupButtonKey, value);
    notifyListeners();
  }

  bool _showLayoutButton =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showLayoutButtonKey);

  bool get showLayoutButton => _showLayoutButton;

  set showLayoutButton(bool value) {
    _showLayoutButton = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.showLayoutButtonKey, value);
    notifyListeners();
  }

  bool _showSortButton =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showSortButtonKey);

  bool get showSortButton => _showSortButton;

  set showSortButton(bool value) {
    _showSortButton = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.showSortButtonKey, value);
    notifyListeners();
  }

  bool _showBackupLogButton =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showBackupLogButtonKey);

  bool get showBackupLogButton => _showBackupLogButton;

  set showBackupLogButton(bool value) {
    _showBackupLogButton = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.showBackupLogButtonKey, value);
    notifyListeners();
  }

  bool _dragToReorder = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());

  bool get dragToReorder => _dragToReorder;

  set dragToReorder(bool value) {
    _dragToReorder = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.dragToReorderKey, value);
    notifyListeners();
  }

  bool _enableFrostedGlassEffect = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.enableFrostedGlassEffectKey,
      defaultValue: false);

  bool get enableFrostedGlassEffect => _enableFrostedGlassEffect;

  set enableFrostedGlassEffect(bool value) {
    _enableFrostedGlassEffect = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.enableFrostedGlassEffectKey, value);
    notifyListeners();
  }

  bool _hideAppbarWhenScrolling =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideAppbarWhenScrollingKey);

  bool get hideAppbarWhenScrolling => _hideAppbarWhenScrolling;

  set hideAppbarWhenScrolling(bool value) {
    _hideAppbarWhenScrolling = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.hideAppbarWhenScrollingKey, value);
    notifyListeners();
  }

  bool _hideBottombarWhenScrolling =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideBottombarWhenScrollingKey);

  bool get hideBottombarWhenScrolling => _hideBottombarWhenScrolling;

  set hideBottombarWhenScrolling(bool value) {
    _hideBottombarWhenScrolling = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.hideBottombarWhenScrollingKey, value);
    notifyListeners();
  }

  bool _enableModalSheet =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableModalSheetKey, defaultValue: false);

  bool get enableModalSheet => _enableModalSheet;

  set enableModalSheet(bool value) {
    _enableModalSheet = value;
    ChewieHiveUtil.put(CloudOTPHiveUtil.enableModalSheetKey, value);
    notifyListeners();
  }

  // Map<Type, Action<Intent>> _dynamicShortcuts =
  //     KeyboardHandlerState.mainScreenShortcuts;

  // Map<Type, Action<Intent>> get dynamicShortcuts => _dynamicShortcuts;
  //
  // set dynamicShortcuts(Map<Type, Action<Intent>> value) {
  //   _dynamicShortcuts = value;
  //   notifyListeners();
  // }

  AutoLockTime _autoLockTime = CloudOTPHiveUtil.getAutoLockTime();

  AutoLockTime get autoLockTime => _autoLockTime;

  set autoLockTime(AutoLockTime value) {
    if (value != _autoLockTime) {
      _autoLockTime = value;
      notifyListeners();
      CloudOTPHiveUtil.setAutoLockTime(value);
    }
  }

  ActiveThemeMode _themeMode = ChewieHiveUtil.getThemeMode();

  ActiveThemeMode get themeMode => _themeMode;

  set themeMode(ActiveThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
      chewieProvider.themeMode = _themeMode;
    }
  }

  CustomFont _currentFont = CustomFont.getCurrentFont();

  CustomFont get currentFont => _currentFont;

  set currentFont(CustomFont value) {
    _currentFont = value;
    notifyListeners();
  }

  ChewieThemeColorData _lightTheme = ChewieHiveUtil.getLightTheme();

  ChewieThemeColorData get lightTheme => _lightTheme;

  set lightTheme(ChewieThemeColorData value) {
    _lightTheme = value;
    chewieProvider.lightTheme = value;
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
    chewieProvider.darkTheme = value;
    notifyListeners();
  }

  setDarkTheme(int index) {
    ChewieHiveUtil.setDarkTheme(index);
    _darkTheme = ChewieHiveUtil.getDarkTheme();
    notifyListeners();
  }

  final List<ChewieThemeColorData> _customLightThemes =
      ChewieHiveUtil.getCustomLightThemes();

  List<ChewieThemeColorData> get customLightThemes => _customLightThemes;

  final List<ChewieThemeColorData> _customDarkThemes =
      ChewieHiveUtil.getCustomDarkThemes();

  List<ChewieThemeColorData> get customDarkThemes => _customDarkThemes;

  void addCustomLightTheme(ChewieThemeColorData theme) {
    _customLightThemes.add(theme);
    ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
    notifyListeners();
  }

  void updateCustomLightTheme(int index, ChewieThemeColorData theme) {
    if (index >= 0 && index < _customLightThemes.length) {
      _customLightThemes[index] = theme;
      ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
      int activeIndex = ChewieHiveUtil.getLightThemeIndex();
      int builtInCount = ChewieThemeColorData.defaultLightThemes.length;
      if (activeIndex == builtInCount + index) {
        _lightTheme = ChewieHiveUtil.getLightTheme();
        chewieProvider.lightTheme = _lightTheme;
      }
      notifyListeners();
    }
  }

  void deleteCustomLightTheme(int index) {
    if (index < 0 || index >= _customLightThemes.length) return;
    _customLightThemes.removeAt(index);
    ChewieHiveUtil.setCustomLightThemes(_customLightThemes);
    int activeIndex = ChewieHiveUtil.getLightThemeIndex();
    int builtInCount = ChewieThemeColorData.defaultLightThemes.length;
    int deletedGlobalIndex = builtInCount + index;
    if (activeIndex == deletedGlobalIndex) {
      setLightTheme(0);
    } else if (activeIndex > deletedGlobalIndex) {
      ChewieHiveUtil.setLightTheme(activeIndex - 1);
      _lightTheme = ChewieHiveUtil.getLightTheme();
      chewieProvider.lightTheme = _lightTheme;
    }
    notifyListeners();
  }

  void addCustomDarkTheme(ChewieThemeColorData theme) {
    _customDarkThemes.add(theme);
    ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
    notifyListeners();
  }

  void updateCustomDarkTheme(int index, ChewieThemeColorData theme) {
    if (index >= 0 && index < _customDarkThemes.length) {
      _customDarkThemes[index] = theme;
      ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
      int activeIndex = ChewieHiveUtil.getDarkThemeIndex();
      int builtInCount = ChewieThemeColorData.defaultDarkThemes.length;
      if (activeIndex == builtInCount + index) {
        _darkTheme = ChewieHiveUtil.getDarkTheme();
        chewieProvider.darkTheme = _darkTheme;
      }
      notifyListeners();
    }
  }

  void deleteCustomDarkTheme(int index) {
    if (index < 0 || index >= _customDarkThemes.length) return;
    _customDarkThemes.removeAt(index);
    ChewieHiveUtil.setCustomDarkThemes(_customDarkThemes);
    int activeIndex = ChewieHiveUtil.getDarkThemeIndex();
    int builtInCount = ChewieThemeColorData.defaultDarkThemes.length;
    int deletedGlobalIndex = builtInCount + index;
    if (activeIndex == deletedGlobalIndex) {
      setDarkTheme(0);
    } else if (activeIndex > deletedGlobalIndex) {
      ChewieHiveUtil.setDarkTheme(activeIndex - 1);
      _darkTheme = ChewieHiveUtil.getDarkTheme();
      chewieProvider.darkTheme = _darkTheme;
    }
    notifyListeners();
  }

  void setLightPrimaryColorOverride(Color? color, int paletteIndex) {
    ChewieHiveUtil.setCustomLightPrimaryColor(color);
    ChewieHiveUtil.setLightThemePrimaryColorIndex(paletteIndex);
    _lightTheme = ChewieHiveUtil.getLightTheme();
    chewieProvider.lightTheme = _lightTheme;
    notifyListeners();
  }

  void setDarkPrimaryColorOverride(Color? color, int paletteIndex) {
    ChewieHiveUtil.setCustomDarkPrimaryColor(color);
    ChewieHiveUtil.setDarkThemePrimaryColorIndex(paletteIndex);
    _darkTheme = ChewieHiveUtil.getDarkTheme();
    chewieProvider.darkTheme = _darkTheme;
    notifyListeners();
  }

  Locale? _locale = ChewieHiveUtil.getLocale();

  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value != _locale) {
      _locale = value;
      Intl.defaultLocale = value?.toString();
      notifyListeners();
      ChewieHiveUtil.setLocale(value);
    }
  }

  void refreshSystemLocale() {
    if (_locale == null) {
      notifyListeners();
    }
  }
}
