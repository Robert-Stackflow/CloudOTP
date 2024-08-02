import 'dart:math';

import 'package:cloudotp/Screens/Setting/setting_screen.dart';
import 'package:cloudotp/Screens/Token/category_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Screens/Token/add_token_screen.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/shortcuts_util.dart';
import '../../generated/l10n.dart';
import 'keymap_widget.dart';

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

  focus() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = defaultCloudOTPShortcuts;
    final shortcuts = Map.fromEntries(
        s.map((e) => MapEntry(e.triggerForPlatform(), e.intent)));
    final showHelpShortcut = <Type, Action<Intent>>{
      KeyboardShortcutHelpIntent: CallbackAction(
        onInvoke: (_) {
          while (Navigator.of(rootContext).canPop()) {
            return null;
          }
          double width = MediaQuery.sizeOf(context).width - 200;
          double height = MediaQuery.sizeOf(context).height - 200;
          double preferWidth = min(width, 600);
          double preferHeight = min(height, 400);

          DialogBuilder.showPageDialog(
            rootContext,
            preferMinWidth: preferWidth,
            preferMinHeight: preferHeight,
            showClose: false,
            child: KeyboardWidget(
              bindings: defaultCloudOTPShortcuts,
              title: Text(
                S.current.shortcut,
                style: Theme.of(rootContext).textTheme.titleLarge,
              ),
            ),
          );
          return null;
        },
      ),
      LockIntent: CallbackAction(
        onInvoke: (_) {
          if (HiveUtil.canLock()) {
            mainScreenState?.jumpToPinVerify();
          } else {
            IToast.showTop(S.current.noGestureLock);
          }
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
          mainScreenState?.focusSearch();
          return null;
        },
      ),
      AddTokenIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDialogRoute(rootContext, const AddTokenScreen(),
              showClose: false);
          return null;
        },
      ),
      ImportExportIntent: CallbackAction(
        onInvoke: (_) {
          RouteUtil.pushDialogRoute(
              rootContext, const ImportExportTokenScreen());
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
          RouteUtil.pushDialogRoute(rootContext, const CategoryScreen(),
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
      BackIntent: CallbackAction(
        onInvoke: (_) {
          mainScreenState?.goBack();
          return null;
        },
      ),
      HomeIntent: CallbackAction(
        onInvoke: (_) {
          while (Navigator.of(rootContext).canPop()) {
            Navigator.of(rootContext).pop();
          }
          mainScreenState?.goHome();
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
          canRequestFocus: true,
          descendantsAreFocusable: true,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (Navigator.of(rootContext).canPop()) {
                Navigator.of(rootContext).pop();
              }
            }
            return KeyEventResult.ignored;
          },
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
    // IPrint.debug('handleKeyPress($event, $keysPressed) result: $result');
    return result;
  }
}
