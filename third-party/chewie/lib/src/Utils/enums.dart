import 'package:flutter/material.dart';

enum ActiveThemeMode {
  system,
  light,
  dark;

  ThemeMode get themeMode {
    switch (this) {
      case ActiveThemeMode.system:
        return ThemeMode.system;
      case ActiveThemeMode.light:
        return ThemeMode.light;
      case ActiveThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

enum InitPhase {
  haveNotConnected,
  connecting,
  successful,
  failed;
}

enum TrayKey {
  displayApp("displayApp"),
  lockApp("lockApp"),
  copyTokenCode("copyTokenCode"),
  setting("setting"),
  officialWebsite("officialWebsite"),
  githubRepository("githubRepository"),
  about("about"),
  launchAtStartup("launchAtStartup"),
  checkUpdates("checkUpdates"),
  shortcutHelp("shortcutHelp"),
  exitApp("exitApp");

  final String key;

  const TrayKey(this.key);
}

enum SideBarChoice {
  ClipBoardManage("clipBoardManage"),
  Shortcut("Shortcut"),
  Backup("backup"),
  RecyclingBin("recyclingBin"),
  Settings("Settings");

  final String key;

  const SideBarChoice(this.key);

  static fromString(String string) {
    for (var value in SideBarChoice.values) {
      if (value.key == string) {
        return value;
      }
    }
    return SideBarChoice.ClipBoardManage;
  }

  static fromInt(int index) {
    if (index < 0 || index >= SideBarChoice.values.length) {
      return SideBarChoice.ClipBoardManage;
    }
    return SideBarChoice.values[index];
  }
}
