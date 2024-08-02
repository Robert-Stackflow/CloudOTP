import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../generated/l10n.dart';

typedef LabelProvider = String Function(S loc);

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

final defaultCloudOTPShortcuts = [
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyA,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const AddTokenIntent(),
    label: (loc) => "Add Token",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyI,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ImportExportIntent(),
    label: (loc) => "Import/Export",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const CategoryIntent(),
    label: (loc) => "Category",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyT,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ChangeLayoutTypeIntent(),
    label: (loc) => "Change Layout Type",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyD,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const ChangeDayNightModeIntent(),
    label: (loc) => "Change Day/Night Mode",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyP,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const SettingIntent(),
    label: (loc) => "Setting",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const SearchIntent(),
    label: (loc) => "Search",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.keyL,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    ).singleActivator,
    intent: const LockIntent(),
    label: (loc) => "Lock",
  ),
  CloudOTPShortcut.all(
    key: HotKey(
      key: LogicalKeyboardKey.f1,
    ).singleActivator,
    intent: const KeyboardShortcutHelpIntent(),
    label: (loc) => "Keyboard Shortcut Help",
  ),
];

class CloudOTPShortcut {
  const CloudOTPShortcut({
    required this.mac,
    required this.linux,
    required this.windows,
    required this.intent,
    required this.label,
  });

  CloudOTPShortcut.all({
    required ShortcutActivator key,
    required Intent intent,
    required LabelProvider label,
  }) : this(
          mac: key,
          linux: key,
          windows: key,
          intent: intent,
          label: label,
        );

  final ShortcutActivator mac;
  final ShortcutActivator linux;
  final ShortcutActivator windows;
  final Intent intent;
  final LabelProvider label;

  ShortcutActivator triggerForPlatform(TargetPlatform platform) {
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
