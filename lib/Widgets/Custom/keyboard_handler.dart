import 'package:cloudotp/Screens/Setting/setting_screen.dart';
import 'package:cloudotp/Screens/Token/category_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:flutter/material.dart';

import '../../Screens/Token/add_token_screen.dart';
import '../../Utils/iprint.dart';
import '../../Utils/route_util.dart';
import '../../Utils/shortcuts_util.dart';
import '../../generated/l10n.dart';

class KeyboardHandler extends StatefulWidget {
  const KeyboardHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  KeyboardHandlerState createState() => KeyboardHandlerState();
}

class KeyboardHandlerState extends State<KeyboardHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final s = defaultCloudOTPShortcuts;
    final theme = Theme.of(context);
    final shortcuts = Map.fromEntries(
        s.map((e) => MapEntry(e.triggerForPlatform(theme.platform), e.intent)));
    final loc = S.current;
    final showHelpShortcut = <Type, Action<Intent>>{
      KeyboardShortcutHelpIntent: CallbackAction(
        onInvoke: (_) {
          final descr = s
              .map((e) => [
                    e.triggerForPlatform(theme.platform).debugDescribeKeys(),
                    e.label(loc)
                  ].join(CharConstants.colon + CharConstants.space))
              .join(CharConstants.newLine);
          IToast.show("Keyboard Shortcuts:\n$descr");
          return null;
        },
      ),
      LockIntent: CallbackAction(
        onInvoke: (_) {
          IToast.show("Lock");
          return null;
        },
      ),
      SettingIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDesktopFadeRoute(const SettingScreen());
          return null;
        },
      ),
      SearchIntent: CallbackAction(
        onInvoke: (_) {
          IToast.show("Search");
          return null;
        },
      ),
      AddTokenIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDialogRoute(context, const AddTokenScreen(),
              showClose: false);
          return null;
        },
      ),
      ImportExportIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDialogRoute(context, const ImportExportTokenScreen());
          return null;
        },
      ),
      ChangeDayNightModeIntent: CallbackAction(
        onInvoke: (_) {
          mainScreenState?.changeMode();
          return null;
        },
      ),
      CategoryIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDialogRoute(context, const CategoryScreen(),
              showClose: false);
          return null;
        },
      ),
      ChangeLayoutTypeIntent: CallbackAction(
        onInvoke: (_) {
          homeScreenState?.changeLayoutType();
          return null;
        },
      ),
    };
    return Shortcuts.manager(
      manager: LoggingShortcutManager(shortcuts: shortcuts),
      child: Actions(
        actions: showHelpShortcut,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }
}

class LoggingShortcutManager extends ShortcutManager {
  LoggingShortcutManager({required super.shortcuts});

  @override
  KeyEventResult handleKeypress(
    BuildContext context,
    KeyEvent event, {
    LogicalKeySet? keysPressed,
  }) {
    final KeyEventResult result = super.handleKeypress(context, event);
    IPrint.debug('handleKeyPress($event, $keysPressed) result: $result');
    return result;
  }
}
