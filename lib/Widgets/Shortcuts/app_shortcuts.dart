import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Screens/Setting/setting_navigation_screen.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/category_screen.dart';
import '../../Screens/Token/import_export_token_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/shortcuts_util.dart';

class AppShortcuts extends StatelessWidget {
  final Widget child;

  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: Map.fromEntries(ShortcutsUtil.shortcuts
          .map((e) => MapEntry(e.triggerForPlatform(), e.intent))),
      child: Actions(
        actions: <Type, Action<Intent>>{
          EscapeIntent: CallbackAction<EscapeIntent>(
            onInvoke: (intent) {
              if (Navigator.of(chewieProvider.rootContext).canPop()) {
                Navigator.of(chewieProvider.rootContext).pop();
              }
              return null;
            },
          ),
          LockIntent: CallbackAction(
            onInvoke: (_) {
              ShortcutsUtil.lock(context);
              return null;
            },
          ),
          KeyboardShortcutHelpIntent: CallbackAction(
            onInvoke: (_) {
              ShortcutsUtil.showShortcutHelp(context);
              return null;
            },
          ),
          SettingIntent: CallbackAction(
            onInvoke: (_) {
              ShortcutsUtil.jumpToSetting(context);
              return null;
            },
          ),
          SearchIntent: CallbackAction(
            onInvoke: (_) {
              ShortcutsUtil.focusSearch();
              return null;
            },
          ),
          AddTokenIntent: CallbackAction(
            onInvoke: (_) {
              RouteUtil.pushDialogRoute(
                  chewieProvider.rootContext, const AddTokenScreen());
              return null;
            },
          ),
          ImportExportIntent: CallbackAction(
            onInvoke: (_) {
              RouteUtil.pushDialogRoute(
                  chewieProvider.rootContext, const ImportExportTokenScreen());
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
              RouteUtil.pushDialogRoute(
                  chewieProvider.rootContext, const CategoryScreen());
              return null;
            },
          ),
          ChangeLayoutTypeIntent: CallbackAction(
            onInvoke: (_) {
              homeScreenState?.changeLayoutType();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: appProvider.shortcutFocusNode,
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
