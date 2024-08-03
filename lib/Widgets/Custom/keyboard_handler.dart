import 'package:cloudotp/Utils/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Screens/Setting/setting_screen.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/category_screen.dart';
import '../../Screens/Token/import_export_token_screen.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
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

  Map<Type, Action<Intent>> generalActions(BuildContext context) {
    return {
      KeyboardShortcutHelpIntent: CallbackAction(
        onInvoke: (_) {
          late OverlayEntry entry;
          entry = OverlayEntry(
            builder: (context) {
              return KeyboardWidget(
                bindings: defaultCloudOTPShortcuts,
                callbackOnHide: () {
                  entry.remove();
                },
                title: Text(
                  S.current.shortcut,
                  style: Theme.of(rootContext).textTheme.titleLarge,
                ),
              );
            },
          );
          Overlay.of(context).insert(entry);
          return null;
        },
      ),
      LockIntent: CallbackAction(
        onInvoke: (_) {
          mainScreenState?.goHome();
          if (HiveUtil.canLock()) {
            mainScreenState?.jumpToPinVerify();
          } else {
            IToast.showTop(S.current.noGestureLock);
          }
          return null;
        },
      ),
      HomeIntent: CallbackAction(
        onInvoke: (_) {
          mainScreenState?.goHome();
          return null;
        },
      ),
      EscapeIntent: CallbackAction(
        onInvoke: (_) {
          if (Navigator.of(rootContext).canPop()) {
            Navigator.of(rootContext).pop();
          }
          return null;
        },
      ),
    };
  }

  static Map<Type, Action<Intent>> mainScreenShortcuts = {
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
        RouteUtil.pushDialogRoute(rootContext, const ImportExportTokenScreen());
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
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts.manager(
      manager: LoggingShortcutManager(
          shortcuts: Map.fromEntries(defaultCloudOTPShortcuts
              .map((e) => MapEntry(e.triggerForPlatform(), e.intent)))),
      child: Selector<AppProvider, Map<Type, Action<Intent>>>(
        selector: (context, appProvider) => appProvider.dynamicShortcuts,
        builder: (context, dynamicShortcuts, child) => Actions(
          actions: {
            ...dynamicShortcuts,
            ...generalActions(context),
          },
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
