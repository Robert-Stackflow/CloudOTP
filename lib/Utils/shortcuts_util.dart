import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../generated/l10n.dart';

typedef LocalizationsProvider = String Function(S);

class LockIntent extends Intent {
  const LockIntent();
}

class SettingIntent extends Intent {
  const SettingIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class KeyboardShortcutHelpIntent extends Intent {
  const KeyboardShortcutHelpIntent();
}

class AddTokenIntent extends Intent {
  const AddTokenIntent();
}

class ImportExportIntent extends Intent {
  const ImportExportIntent();
}

class CategoryIntent extends Intent {
  const CategoryIntent();
}

class ChangeLayoutTypeIntent extends Intent {
  const ChangeLayoutTypeIntent();
}

class ChangeDayNightModeIntent extends Intent {
  const ChangeDayNightModeIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class HomeIntent extends Intent {
  const HomeIntent();
}

final defaultCloudOTPShortcuts = [
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyA,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const AddTokenIntent(),
    labelProvider: (s) => s.addToken,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.arrowLeft,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const BackIntent(),
    labelProvider: (s) => s.back,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyH,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const HomeIntent(),
    labelProvider: (s) => s.home,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.escape,
    ).singleActivator,
    intent: const EscapeIntent(),
    labelProvider: (s) => s.escape,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyI,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ImportExportIntent(),
    labelProvider: (s) => s.exportImport,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const CategoryIntent(),
    labelProvider: (s) => s.category,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyT,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ChangeLayoutTypeIntent(),
    labelProvider: (s) => s.changeLayoutType,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyD,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ChangeDayNightModeIntent(),
    labelProvider: (s) => s.changeDayNightMode,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyP,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const SettingIntent(),
    labelProvider: (s) => s.setting,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const SearchIntent(),
    labelProvider: (s) => s.searchToken,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyL,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const LockIntent(),
    labelProvider: (s) => s.lock,
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.f1,
    ).singleActivator,
    intent: const KeyboardShortcutHelpIntent(),
    labelProvider: (s) => s.shortcutHelp,
  ),
];

class CloudOTPShortcut {
  const CloudOTPShortcut({
    required this.mac,
    required this.linux,
    required this.windows,
    required this.intent,
    required this.labelProvider,
  });

  CloudOTPShortcut.all({
    required SingleActivator key,
    required Intent intent,
    required LocalizationsProvider labelProvider,
  }) : this(
          mac: key,
          linux: key,
          windows: key,
          intent: intent,
          labelProvider: labelProvider,
        );

  final SingleActivator mac;
  final SingleActivator linux;
  final SingleActivator windows;
  final Intent intent;
  final LocalizationsProvider labelProvider;

  bool get isControlPressed => triggerForPlatform().control;

  bool get isMetaPressed => triggerForPlatform().meta;

  bool get isShiftPressed => triggerForPlatform().shift;

  bool get isAltPressed => triggerForPlatform().alt;

  String get triggerLabel {
    SingleActivator tr = triggerForPlatform();
    LogicalKeyboardKey key = tr.trigger;
    if (key == LogicalKeyboardKey.arrowLeft) {
      return "←";
    } else if (key == LogicalKeyboardKey.arrowRight) {
      return "→";
    } else if (key == LogicalKeyboardKey.arrowUp) {
      return "↑";
    } else if (key == LogicalKeyboardKey.arrowDown) {
      return "↓";
    } else if (key == LogicalKeyboardKey.delete) {
      return "\u232B";
    } else if (key == LogicalKeyboardKey.enter) {
      return '\u2B90';
    } else {
      return key.keyLabel;
    }
  }

  SingleActivator triggerForPlatform() {
    late TargetPlatform platform;
    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else if (Platform.isIOS) {
      platform = TargetPlatform.iOS;
    } else if (Platform.isLinux) {
      platform = TargetPlatform.linux;
    } else if (Platform.isMacOS) {
      platform = TargetPlatform.macOS;
    } else if (Platform.isWindows) {
      platform = TargetPlatform.windows;
    } else {
      platform = TargetPlatform.windows;
    }
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.iOS:
        return mac;
      case TargetPlatform.macOS:
        return mac;
      case TargetPlatform.windows:
        return windows;
    }
  }
}

class CharConstants {
  static const empty = '';
  static const underScore = '_';
  static const plus = '+';

  static const space = ' ';
  static const curlyOpen = '{';

  static const chevronRight = ' » ';

  static const slash = '/';
  static const newLine = '\n';

  static const colon = ':';
  static const comma = ',';

  static const semiColon = ';';

  static const equalSign = '=';

  static const star = '*';

  static const questionMark = '?';
}

extension HotKeyExt on HotKey {
  SingleActivator get singleActivator {
    final activator = SingleActivator(
      logicalKey,
      shift: (modifiers ?? []).contains(HotKeyModifier.shift),
      control: (modifiers ?? []).contains(HotKeyModifier.control),
      alt: (modifiers ?? []).contains(HotKeyModifier.alt),
      meta: (modifiers ?? []).contains(HotKeyModifier.meta),
    );
    return activator;
  }
}
