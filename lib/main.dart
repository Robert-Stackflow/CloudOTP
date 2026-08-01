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
import 'dart:ui' as ui;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_cloud/awesome_cloud.dart' show CloudLogger;
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Screens/Lock/database_decrypt_screen.dart';
import 'package:cloudotp/Screens/Lock/pin_verify_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/biometric_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/generated/app_localizations.dart';
import 'Utils/EnteCrypto/ente_crypto_dart.dart';
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
import 'Screens/welcome_screen.dart';
import 'TokenUtils/token_image_util.dart';
import 'Utils/utils.dart';
import 'Widgets/Shortcuts/app_shortcuts.dart';

const List<String> kWindowsSchemes = ["cloudotp", "com.cloudchewie.cloudotp"];

const String kWindowSingleInstanceName = "cloudotp_singleinstance";

Future<void> main(List<String> args) async {
  final appFuture = runZonedGuarded<Future<void>>(
    () async {
      FlutterError.onError = onFlutterError;
      ui.PlatformDispatcher.instance.onError = onPlatformError;
      await runMyApp(args);
    },
    (error, stackTrace) {
      unawaited(writeErrorLog(error, stackTrace));
    },
  );
  if (appFuture != null) await appFuture;
}

Future<void> runMyApp(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await initApp(widgetsBinding);
  runApp(MyApp(home: getRootPage()));
  FlutterNativeSplash.remove();
}

Widget getRootPage([bool isMain = false]) {
  return CustomMouseRegion(
    child: Builder(
      builder: (context) {
        Widget home;
        if (isMain) {
          home = AppShortcuts(child: MainScreen(key: mainScreenKey));
        } else {
          if (!DatabaseManager.initialized) {
            home = const DatabaseDecryptScreen();
          } else if (!CloudOTPHiveUtil.canDatabaseLock() &&
              CloudOTPHiveUtil.canGuestureLock()) {
            home = const PinVerifyScreen(
              isModal: true,
              autoAuth: true,
              jumpToMain: true,
              showWindowTitle: true,
            );
          } else if (!ChewieHiveUtil.getBool(
              CloudOTPHiveUtil.haveShownWelcome4Key,
              defaultValue: false)) {
            home = const WelcomeScreen();
          } else {
            home = AppShortcuts(child: MainScreen(key: mainScreenKey));
          }
        }
        return home;
      },
    ),
  );
}

Future<void> initApp(WidgetsBinding widgetsBinding) async {
  initCloudLogger();
  await ResponsiveUtil.init();
  await FileUtil.migrationDataToSupportDirectory();
  final cacheSize =
      ResponsiveUtil.isMobile() ? 128 * 1024 * 1024 : 256 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSizeBytes = cacheSize;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initHive();
  await initCryptoUtil();
  await BiometricUtil.initStorage();
  await TokenImageUtil.loadBrandLogos();
  CustomFont.downloadFont(showToast: false);
  if (ResponsiveUtil.isAndroid()) await initAndroid();
  if (ResponsiveUtil.isDesktop()) await initDesktop();
  ILogger.debug(
      "Running on ${ResponsiveUtil.platformName} with version ${ResponsiveUtil.version}");
  ILogger.debug(ResponsiveUtil.deviceDescription);
}

Future<void> initHive() async {
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
        await CloudOTPHiveUtil.getDatabasePassword());
  } catch (e, t) {
    ILogger.error("Failed to init database", e, t);
    await DatabaseManager.resetDatabase();
  }
}

Future<void> initAndroid() async {
  await initDisplayMode();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
}

Future<void> initDesktop() async {
  await initWindow();
  try {
    LaunchAtStartup.instance.setup(
      appName: ResponsiveUtil.appName,
      appPath: Platform.resolvedExecutable,
    );
  } catch (e, t) {
    ILogger.error("Failed to setup LaunchAtStartup", e, t);
  }
  try {
    await LocalNotifier.instance.setup(
      appName: ResponsiveUtil.appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  } catch (e, t) {
    ILogger.error("Failed to setup LocalNotifier", e, t);
  }
  try {
    bool isEnabled = await LaunchAtStartup.instance.isEnabled();
    ILogger.debug("LaunchAtStartup: $isEnabled");
    ChewieHiveUtil.put(ChewieHiveUtil.launchAtStartupKey, isEnabled);
  } catch (e, t) {
    ILogger.error("Failed to check LaunchAtStartup status", e, t);
  }
  try {
    for (String scheme in kWindowsSchemes) {
      await protocolHandler.register(scheme);
    }
  } catch (e, t) {
    ILogger.error("Failed to register protocol handler", e, t);
  }
  try {
    await HotKeyManager.instance.unregisterAll();
  } catch (e, t) {
    ILogger.error("Failed to unregister hotkeys", e, t);
  }
  ILogger.debug(
      "http proxy: ${Platform.environment['http_proxy']}, https proxy: ${Platform.environment['https_proxy']}");
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  Offset position = ChewieHiveUtil.getWindowPosition();
  bool shouldCenter = position == Offset.zero;
  WindowOptions windowOptions = WindowOptions(
    size: ChewieHiveUtil.getWindowSize(),
    minimumSize: ChewieProvider.minimumWindowSize,
    center: shouldCenter,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    if (!shouldCenter) {
      await windowManager.setPosition(position);
    }
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> initDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  await FlutterDisplayMode.setPreferredMode(await FlutterDisplayMode.preferred);
}

void onFlutterError(FlutterErrorDetails details) {
  FlutterError.presentError(details);
  unawaited(writeErrorLog(
    details.exception,
    details.stack ?? StackTrace.current,
    library: details.library,
    context: details.context?.toDescription(),
  ));
}

bool onPlatformError(Object error, StackTrace stackTrace) {
  unawaited(writeErrorLog(error, stackTrace));
  return true;
}

Future<void> writeErrorLog(
  Object error,
  StackTrace stackTrace, {
  String? library,
  String? context,
}) async {
  try {
    final errorFile = File(join(await FileUtil.getLogDir(), 'error.log'));
    await errorFile.parent.create(recursive: true);
    final errorDetails = [
      'Time: ${DateTime.now().toIso8601String()}',
      'Exception: ${CloudLogger.redactForLogging(error.toString())}',
      'Stack trace:\n${CloudLogger.redactForLogging(stackTrace.toString())}',
      'Library: ${library ?? 'Unknown library'}',
      'Context: ${context ?? 'No context available'}',
    ].join('\n');
    await errorFile.writeAsString(
      '$errorDetails\n\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (loggingError, loggingStack) {
    debugPrint('Failed to persist application error: $loggingError');
    debugPrintStack(stackTrace: loggingStack);
  }
}

void initCloudLogger() {
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

  static Locale _resolveSystemLocale(Iterable<Locale> supportedLocales) {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    for (final supported in supportedLocales) {
      if (supported.languageCode == systemLocale.languageCode &&
          supported.countryCode == systemLocale.countryCode) {
        return supported;
      }
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == systemLocale.languageCode) {
        return supported;
      }
    }
    return supportedLocales.first;
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
            AppLocalizations.delegate,
            ChewieLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: context.watch<AppProvider>().locale ??
              _resolveSystemLocale(AppLocalizations.supportedLocales),
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            ILogger.debug(
                "Locale: $locale, Supported: $supportedLocales, appProvider.locale: ${appProvider.locale}");
            if (appProvider.locale != null) {
              return appProvider.locale;
            }
            return _resolveSystemLocale(supportedLocales);
          },
          home: home,
          builder: (context, widget) {
            chewieProvider.initRootContext(context);
            if (ResponsiveUtil.isAndroid()) {
              final brightness = Theme.of(context).brightness;
              final overlayStyle = SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
              );
              SystemChrome.setSystemUIOverlayStyle(overlayStyle);
            }
            return Overlay(
              initialEntries: [
                if (widget != null) ...[
                  OverlayEntry(
                    builder: (context) => MediaQuery(
                      data: ChewieHiveUtil.getBool(
                              CloudOTPHiveUtil.followSystemTextScaleKey,
                              defaultValue: false)
                          ? MediaQuery.of(context)
                          : MediaQuery.of(context)
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
