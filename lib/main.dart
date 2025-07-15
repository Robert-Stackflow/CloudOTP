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
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Screens/Lock/database_decrypt_screen.dart';
import 'package:cloudotp/Screens/Lock/pin_verify_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/biometric_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'Screens/main_screen.dart';
import 'TokenUtils/token_image_util.dart';
import 'Utils/utils.dart';
import 'Widgets/Shortcuts/app_shortcuts.dart';
import 'generated/l10n.dart';

const List<String> kWindowsSchemes = ["cloudotp", "com.cloudchewie.cloudotp"];

const String kWindowSingleInstanceName = "cloudotp_singleinstance";

Future<void> main(List<String> args) async {
  runMyApp(args);
}

Future<void> runMyApp(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await initApp(widgetsBinding);
  ILogger.debug(
      "http proxy: ${Platform.environment['http_proxy']}, https proxy: ${Platform.environment['https_proxy']}");
  late Widget home;
  if (!DatabaseManager.initialized) {
    home = const DatabaseDecryptScreen();
  } else if (CloudOTPHiveUtil.canLock()) {
    home = const PinVerifyScreen(
      isModal: true,
      autoAuth: true,
      jumpToMain: true,
      showWindowTitle: true,
    );
  } else {
    home = AppShortcuts(child: MainScreen(key: mainScreenKey));
  }
  runApp(MyApp(home: home));
  FlutterNativeSplash.remove();
}

Future<void> initApp(WidgetsBinding widgetsBinding) async {
  await ResponsiveUtil.init();
  await FileUtil.migrationDataToSupportDirectory();
  FlutterError.onError = onError;
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  Hive.defaultDirectory = await FileUtil.getHiveDir();
  if (ChewieHiveUtil.isFirstLogin()) {
    await CloudOTPHiveUtil.initConfig();
    ChewieHiveUtil.setFirstLogin();
  }
  if (haveMigratedToSupportDirectory) {
    ChewieHiveUtil.put(ChewieHiveUtil.haveMigratedToSupportDirectoryKey, true);
  }
  ChewieHiveUtil.put(CloudOTPHiveUtil.oldVersionKey, ResponsiveUtil.version);
  try {
    await DatabaseManager.initDataBase(
        ChewieHiveUtil.getString(CloudOTPHiveUtil.defaultDatabasePasswordKey) ??
            "");
  } catch (e) {
    if (DatabaseManager.lib != null) {
      CloudOTPHiveUtil.setEncryptDatabaseStatus(
          EncryptDatabaseStatus.customPassword);
    } else {
      CloudOTPHiveUtil.setEncryptDatabaseStatus(
          EncryptDatabaseStatus.defaultPassword);
    }
  }
  await initCryptoUtil();
  NotificationUtil.init();
  await BiometricUtil.initStorage();
  await TokenImageUtil.loadBrandLogos();
  initCloudLogger();
  if (ResponsiveUtil.isAndroid()) {
    await initDisplayMode();
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
  if (ResponsiveUtil.isDesktop()) {
    await initWindow();
    LaunchAtStartup.instance.setup(
      appName: ResponsiveUtil.appName,
      appPath: Platform.resolvedExecutable,
    );
    await LocalNotifier.instance.setup(
      appName: ResponsiveUtil.appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    ChewieHiveUtil.put(ChewieHiveUtil.launchAtStartupKey,
        await LaunchAtStartup.instance.isEnabled());
    for (String scheme in kWindowsSchemes) {
      await protocolHandler.register(scheme);
    }
    await HotKeyManager.instance.unregisterAll();
  }
  CustomFont.downloadFont(showToast: false);
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  Offset position = ChewieHiveUtil.getWindowPosition();
  WindowOptions windowOptions = WindowOptions(
    size: ChewieHiveUtil.getWindowSize(),
    minimumSize: ChewieProvider.minimumWindowSize,
    center: position == Offset.zero,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPosition(position);
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> initDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  await FlutterDisplayMode.setPreferredMode(await FlutterDisplayMode.preferred);
}

Future<void> onError(FlutterErrorDetails details) async {
  File errorFile = File(join(await FileUtil.getLogDir(), "error.log"));
  if (!errorFile.existsSync()) errorFile.createSync();
  final currentTime = DateTime.now().toIso8601String();
  final errorDetails = [
    'Time: $currentTime',
    'Exception: ${details.exception}',
    'Stack trace:\n${details.stack ?? 'No stack trace available'}',
    'Library: ${details.library ?? 'Unknown library'}',
    'Context: ${details.context?.toDescription() ?? 'No context available'}',
  ].join('\n');
  errorFile.writeAsStringSync('$errorDetails\n\n', mode: FileMode.append);
  if (details.stack != null) {
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  }
}

initCloudLogger() {
  CloudLogger.logTrace = (tag, message, [e, t]) {
    ILogger.trace(message, e, t);
  };
  CloudLogger.logDebug = (tag, message, [e, t]) {
    ILogger.debug(message, e, t);
  };
  CloudLogger.logInfo = (tag, message, [e, t]) {
    ILogger.info(message, e, t);
  };
  CloudLogger.logWarning = (tag, message, [e, t]) {
    ILogger.debug(message, e, t);
  };
  CloudLogger.logError = (tag, message, [e, t]) {
    ILogger.error(message, e, t);
  };
  CloudLogger.logFatal = (tag, message, [e, t]) {
    ILogger.fatal(message, e, t);
  };
}

class MyApp extends StatelessWidget {
  final Widget home;
  final String title;

  const MyApp({
    super.key,
    required this.home,
    this.title = 'CloudOTP',
  });

  moveToCenter(BuildContext context) async {
    if (!ResponsiveUtil.isDesktop()) return;
    Offset position = ChewieHiveUtil.getWindowPosition();
    Rect rect = await Utils.getWindowRect(context);
    if (!rect.contains(position)) {
      windowManager.setAlignment(Alignment.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    moveToCenter(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: chewieProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) => MaterialApp(
          navigatorKey: chewieProvider.globalNavigatorKey,
          navigatorObservers: [chewieProvider.routeObserver],
          title: title,
          themeMode: appProvider.themeMode.themeMode,
          theme: appProvider.lightTheme.toThemeData(),
          darkTheme: appProvider.darkTheme.toThemeData(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            S.delegate,
            ChewieS.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: appProvider.locale,
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            ILogger.debug("CloudOTP",
                "Locale: $locale, Supported: $supportedLocales, appProvider.locale: ${appProvider.locale}");
            if (appProvider.locale != null) {
              return appProvider.locale;
            } else if (locale != null && supportedLocales.contains(locale)) {
              return locale;
            } else {
              try {
                return Localizations.localeOf(context);
              } catch (e, t) {
                ILogger.error(
                    "Failed to get locale by Localizations.localeOf(context)",
                    e,
                    t);
                return const Locale("en", "US");
              }
            }
          },
          home: CustomMouseRegion(child: home),
          builder: (context, widget) {
            return Overlay(
              initialEntries: [
                if (widget != null) ...[
                  OverlayEntry(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.noScaling),
                      child: Listener(
                        onPointerDown: (_) {
                          if (!ResponsiveUtil.isDesktop() &&
                              homeScreenState?.hasSearchFocus == true) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            appProvider.shortcutFocusNode.requestFocus();
                          }
                        },
                        child: widget,
                      ),
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
