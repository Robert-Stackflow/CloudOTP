import 'dart:async';
import 'dart:io';

import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/fontsize_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/request_header_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'Screens/main_screen.dart';
import 'TokenUtils/token_image_util.dart';
import 'Utils/constant.dart';
import 'Utils/notification_util.dart';
import 'Utils/responsive_util.dart';
import 'generated/l10n.dart';

Future<void> main(List<String> args) async {
  runMyApp(args);
}

Future<void> runMyApp(List<String> args) async {
  await initApp();
  if (ResponsiveUtil.isMobile()) {
    await initDisplayMode();
    if (ResponsiveUtil.isAndroid()) {
      await RequestHeaderUtil.initAndroidInfo();
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
  if (ResponsiveUtil.isDesktop()) {
    await initWindow();
    initTray();
    await HotKeyManager.instance.unregisterAll();
  }
  runApp(const MyApp());
  FlutterNativeSplash.remove();
}

Future<void> initApp() async {
  FlutterError.onError = onError;
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DatabaseManager.getDataBase();
  Hive.defaultDirectory = await FileUtil.getApplicationDir();
  NotificationUtil.init();
  await TokenImageUtil.loadBrandLogos();
  // VideoPlayerMediaKit.ensureInitialized(
  //   android: false,
  //   iOS: false,
  //   macOS: false,
  //   windows: true,
  //   linux: false,
  // );
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  Offset position = HiveUtil.getWindowPosition();
  WindowOptions windowOptions = WindowOptions(
    size: HiveUtil.getWindowSize(),
    minimumSize: minimumSize,
    center: position == Offset.zero,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (position != Offset.zero) await windowManager.setPosition(position);
  });
}

Future<void> initTray() async {
  await trayManager.setIcon(
    ResponsiveUtil.isWindows()
        ? 'assets/logo-transparent.ico'
        : 'assets/logo-transparent.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: '显示 CloudOTP',
      ),
      MenuItem(
        key: 'lock_window',
        label: '锁定 CloudOTP',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'show_official_website',
        label: '官网',
      ),
      MenuItem(
        key: 'show_github_repo',
        label: 'GitHub',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '退出 CloudOTP',
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

Future<void> initDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  await FlutterDisplayMode.setPreferredMode(await FlutterDisplayMode.preferred);
}

Future<void> onError(FlutterErrorDetails details) async {
  File errorFile = File("${await FileUtil.getApplicationDir()}/error.log");
  if (!errorFile.existsSync()) errorFile.createSync();
  errorFile
      .writeAsStringSync(errorFile.readAsStringSync() + details.toString());
  if (details.stack != null) {
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  }
}

class MyApp extends StatelessWidget {
  final Widget home;
  final String title;

  const MyApp({
    super.key,
    this.home = const MainScreen(),
    this.title = 'CloudOTP',
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, globalProvider, child) => MaterialApp(
          navigatorKey: globalNavigatorKey,
          navigatorObservers: [routeObserver],
          title: title,
          theme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.light
              ? globalProvider.lightTheme
              : globalProvider.darkTheme,
          darkTheme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.dark
              ? globalProvider.darkTheme
              : globalProvider.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: globalProvider.locale,
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (globalProvider.locale != null) {
              return globalProvider.locale;
            } else if (locale != null && supportedLocales.contains(locale)) {
              return locale;
            } else {
              try {
                return Localizations.localeOf(context);
              } catch (_) {
                return const Locale("en", "US");
              }
            }
          },
          home: ItemBuilder.buildContextMenuOverlay(home),
          builder: (context, widget) {
            return Overlay(
              initialEntries: [
                if (widget != null) ...[
                  OverlayEntry(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          FontSizeUtil.getTextFactor(globalProvider.fontSize),
                        ),
                      ),
                      child: widget,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
