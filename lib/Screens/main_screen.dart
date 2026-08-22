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
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/Screens/layout_select_screen.dart';
import 'package:cloudotp/Screens/sort_select_screen.dart';
import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../Database/category_dao.dart';
import '../Database/token_category_binding_dao.dart';
import '../Database/token_dao.dart';
import '../Models/opt_token.dart';
import '../Models/token_category.dart';
import '../TokenUtils/code_generator.dart';
import '../TokenUtils/import_token_util.dart';
import '../TokenUtils/export_token_util.dart';
import '../Models/auto_backup_log.dart';
import '../Utils/app_provider.dart';
import '../Utils/constant.dart';
import '../Utils/hive_util.dart';
import '../Utils/lottie_util.dart';
import '../Utils/utils.dart';
import '../Widgets/BottomSheet/import_from_third_party_bottom_sheet.dart';
import '../l10n/l10n.dart';
import 'Backup/cloud_service_screen.dart';
import 'package:flutter/foundation.dart';

import 'Lock/database_decrypt_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/backup_log_screen.dart';
import 'Setting/setting_navigation_screen.dart';
import 'Token/category_screen.dart';
import 'feature_showcase_screen.dart';
import '../Widgets/CoachMark/desktop_coach_mark_manager.dart';

const borderColor = Color(0xFF805306);
const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = "/";

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends BaseWindowState<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TrayListener,
        ProtocolListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  TextEditingController searchController = TextEditingController();
  List<OtpToken> _menuTokens = [];
  List<TokenCategory> _menuCategories = [];

  final GlobalKey _sidebarLogoKey = GlobalKey();
  final GlobalKey _sidebarAddKey = GlobalKey();
  final GlobalKey _sidebarCategoryKey = GlobalKey();
  final GlobalKey _sidebarImportKey = GlobalKey();
  final GlobalKey _sidebarImportThirdKey = GlobalKey();
  final GlobalKey _sidebarCloudBackupKey = GlobalKey();
  final GlobalKey _sidebarBackupLogKey = GlobalKey();
  final GlobalKey _sidebarFeatureShowcaseKey = GlobalKey();
  final GlobalKey _sidebarSettingKey = GlobalKey();
  final GlobalKey _sidebarQrScanKey = GlobalKey();
  final GlobalKey _sidebarSortKey = GlobalKey();
  final GlobalKey _sidebarLayoutKey = GlobalKey();
  final GlobalKey _searchBarKey = GlobalKey();

  @override
  void onWindowMinimize() {
    setTimer();
    super.onWindowMinimize();
  }

  @override
  void onWindowRestore() {
    super.onWindowRestore();
    cancleTimer();
  }

  @override
  void onWindowFocus() {
    cancleTimer();
    super.onWindowFocus();
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == "hide") {
      setTimer();
    }
  }

  @override
  void onProtocolUrlReceived(String url) {
    ILogger.info(
        "Received protocol url: ${Uri.parse(url).replace(queryParameters: {}).toString()}");
  }

  Future<void> fetchReleases() async {
    ChewieUtils.getReleases(
      context: context,
      showLoading: false,
      showUpdateDialog:
          ChewieHiveUtil.getBool(ChewieHiveUtil.autoCheckUpdateKey),
      showFailedToast: false,
      showLatestToast: false,
    );
  }

  @override
  void initState() {
    super.initState();
    if (ResponsiveUtil.isDesktop() && !ResponsiveUtil.isLinux()) {
      protocolHandler.addListener(this);
    }
    if (ResponsiveUtil.isDesktop()) {
      Utils.initTray();
    }
    trayManager.addListener(this);
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    CloudOTPHiveUtil.showCloudEntry().then((value) {
      appProvider.canShowCloudBackupButton = value;
    });
    fetchReleases();
    if (ResponsiveUtil.isMacOS()) {
      _checkNotificationPermission();
      loadMenuTokenData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoFocusSearchBarKey,
          defaultValue: false)) {
        ShortcutsUtil.focusSearch();
      }
      EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
            backgroundColor: ChewieTheme.canvasColor,
            indicator: LottieFiles.load(LottieFiles.getLoadingPath(context),
                scale: 1.5,
                delegates:
                    LottieFiles.loadingDelegates(ChewieTheme.primaryColor)),
            hapticFeedback: true,
            triggerOffset: 40,
          );
      EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
            indicator: LottieFiles.load(LottieFiles.getLoadingPath(context),
                delegates:
                    LottieFiles.loadingDelegates(ChewieTheme.primaryColor)),
          );
      chewieProvider.loadingWidgetBuilder =
          (size, forceDark) => LottieFiles.load(
                LottieFiles.getLoadingPath(chewieProvider.rootContext),
                scale: 1.5,
                delegates:
                    LottieFiles.loadingDelegates(ChewieTheme.primaryColor),
              );
    });
    initGlobalConfig();
    searchController.addListener(() {
      homeScreenState?.performSearch(searchController.text);
    });
    _startAutoBackupOnLaunch();
    _scheduleDesktopCoachMark();
  }

  void _scheduleDesktopCoachMark() {
    if (!ResponsiveUtil.isDesktop() && !ResponsiveUtil.isLandscapeTablet()) {
      return;
    }
    if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.haveShownDesktopCoachMarkKey,
        defaultValue: false)) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      showDesktopCoachMark();
    });
  }

  void showDesktopCoachMark({bool force = false}) {
    final provider = context.read<AppProvider>();
    final searchKey = ResponsiveUtil.isMacOS()
        ? _searchBarKey
        : (homeScreenState?.desktopSearchBarKey ?? _searchBarKey);
    DesktopCoachMarkManager(
      context: context,
      searchBarKey: searchKey,
      addTokenKey: _sidebarAddKey,
      categoryKey: _sidebarCategoryKey,
      qrScanKey: ResponsiveUtil.isLandscapeTablet() ? null : _sidebarQrScanKey,
      importExportKey: _sidebarImportKey,
      importThirdPartyKey: _sidebarImportThirdKey,
      cloudBackupKey:
          provider.showCloudBackupButton ? _sidebarCloudBackupKey : null,
      backupLogKey:
          provider.showBackupLogButton ? _sidebarBackupLogKey : null,
      sortButtonKey: provider.showSortButton ? _sidebarSortKey : null,
      layoutButtonKey: provider.showLayoutButton ? _sidebarLayoutKey : null,
      featureShowcaseKey: _sidebarFeatureShowcaseKey,
      settingKey: _sidebarSettingKey,
      logoKey: _sidebarLogoKey,
      firstTokenKey: homeScreenState?.tokenKeyMap.values.firstOrNull,
      onDeleteSampleData: () => homeScreenState?.refresh(true),
    ).show(force: force);
  }

  static const _notifierChannel = MethodChannel('local_notifier');

  Future<void> _checkNotificationPermission() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final status =
          await _notifierChannel.invokeMethod<String>('checkPermission');
      if (status == 'denied' || status == 'notDetermined') {
        if (!mounted) return;
        DialogBuilder.showConfirmDialog(
          context,
          title: appLocalizations.setting,
          message: status == 'denied'
              ? appLocalizations.notificationPermissionDenied
              : appLocalizations.notificationPermissionRequest,
          confirmButtonText: appLocalizations.goToSettings,
          cancelButtonText: appLocalizations.cancel,
          onTapConfirm: () async {
            await _notifierChannel.invokeMethod('openNotificationSettings');
          },
        );
      }
    } catch (e) {
      ILogger.error("Failed to check notification permission", e);
    }
  }

  Future<void> loadMenuTokenData() async {
    if (!DatabaseManager.initialized) return;
    _menuTokens = await TokenDao.listTokens();
    _menuTokens.sort((a, b) => a.issuer.compareTo(b.issuer));
    List<TokenCategory> cats = await CategoryDao.listCategories();
    for (var cat in cats) {
      cat.tokens = await BindingDao.getTokens(cat.uid);
      cat.tokens.sort((a, b) => a.issuer.compareTo(b.issuer));
    }
    _menuCategories = cats.where((e) => e.tokens.isNotEmpty).toList();
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          WidgetsBinding.instance.platformMenuDelegate
              .setMenus(_buildMacMenuBar());
        }
      });
    }
  }

  Future<void> _copyTokenCode(OtpToken token) async {
    double currentProgress = token.period == 0
        ? 0
        : (token.period * 1000 -
                (DateTime.now().millisecondsSinceEpoch %
                    (token.period * 1000))) /
            (token.period * 1000);
    if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoCopyNextCodeKey) &&
        currentProgress < autoCopyNextCodeProgressThrehold) {
      ChewieUtils.copy(context, CodeGenerator.getNextCode(token),
          toastText: appLocalizations.alreadyCopiedNextCode, autoClear: true);
    } else {
      ChewieUtils.copy(context, CodeGenerator.getCurrentCode(token),
          autoClear: true);
    }
    TokenDao.incTokenCopyTimes(token);
  }

  initGlobalConfig() {
    if (ResponsiveUtil.isDesktop()) {
      windowManager
          .isAlwaysOnTop()
          .then((value) => setState(() => isStayOnTop = value));
      windowManager
          .isMaximized()
          .then((value) => setState(() => isMaximized = value));
    }
    ResponsiveUtil.checkSizeCondition();
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
  }

  Future<void> jumpToLock({
    bool autoAuth = false,
  }) async {
    _menuTokens = [];
    _menuCategories = [];
    if (ResponsiveUtil.isMacOS()) {
      setState(() {});
      WidgetsBinding.instance.platformMenuDelegate.setMenus([]);
    }
    Utils.initSimpleTray();
    if (CloudOTPHiveUtil.canDatabaseLock()) {
      ILogger.debug("Jump to database lock screen");
      await DatabaseManager.resetDatabase();
      RouteUtil.pushRootPage(const DatabaseDecryptScreen());
    } else {
      appProvider.preventLock = true;
      ILogger.debug("Jump to pin lock screen");
      RouteUtil.pushFadeRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            appProvider.preventLock = false;
            loadMenuTokenData();
            Utils.initTray();
          },
          showWindowTitle: true,
          isModal: true,
          autoAuth: autoAuth,
          jumpToMain: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    chewieProvider.setRootContext(context);
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    super.build(context);
    Widget result = OrientationBuilder(builder: (ctx, ori) {
      return _buildBodyByPlatform();
    });
    if (ResponsiveUtil.isMacOS()) {
      return PlatformMenuBar(
        menus: _buildMacMenuBar(),
        child: result,
      );
    }
    return result;
  }

  _buildBodyByPlatform() {
    Widget body = ResponsiveUtil.selectByResponsive(
      desktop: _buildDesktopBody(),
      landscape: SafeArea(child: _buildDesktopBody()),
      portrait: HomeScreen(key: chewieProvider.panelScreenKey),
    );
    return body;
  }

  String _checked(String label, bool isChecked) =>
      isChecked ? '✓  $label' : '    $label';

  List<PlatformMenuItem> _buildMacMenuBar() {
    return [
      // App menu
      PlatformMenu(
        label: ResponsiveUtil.appName,
        menus: [
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: appLocalizations.about,
              onSelected: () => ShortcutsUtil.jumpToAbout(context),
            ),
            PlatformMenuItem(
              label: appLocalizations.checkUpdates,
              onSelected: () => ChewieUtils.getReleases(
                context: context,
                showLoading: true,
                showUpdateDialog: true,
                showFailedToast: true,
                showLatestToast: true,
              ),
            ),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: appLocalizations.setting,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                meta: true,
              ),
              onSelected: () => ShortcutsUtil.jumpToSetting(context),
            ),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: '${appLocalizations.quit} ${ResponsiveUtil.appName}',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                meta: true,
              ),
              onSelected: () => windowManager.destroy(),
            ),
          ]),
        ],
      ),
      // File menu
      PlatformMenu(
        label: appLocalizations.menuFile,
        menus: [
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: appLocalizations.addToken,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyA,
                control: true,
                alt: true,
              ),
              onSelected: () => RouteUtil.pushDialogRoute(
                chewieProvider.rootContext,
                const AddTokenScreen(),
                onThen: (_) => ShortcutsUtil.restoreFocus(),
              ),
            ),
            PlatformMenuItem(
              label: appLocalizations.category,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyC,
                control: true,
                alt: true,
              ),
              onSelected: () => RouteUtil.pushDialogRoute(
                chewieProvider.rootContext,
                const CategoryScreen(),
                onThen: (_) => ShortcutsUtil.restoreFocus(),
              ),
            ),
            PlatformMenu(
              label: appLocalizations.scanToken,
              menus: [
                PlatformMenuItemGroup(members: [
                  PlatformMenuItem(
                    label: appLocalizations.scanFromImageFile,
                    onSelected: () async {
                      FilePickerResult? result = await FileUtil.pickFiles(
                        type: FileType.image,
                        lockParentWindow: true,
                      );
                      if (result == null) return;
                      if (!mounted) return;
                      await ImportTokenUtil.analyzeImageFile(
                        result.files.single.path!,
                        context: context,
                      );
                    },
                  ),
                  PlatformMenuItem(
                    label: appLocalizations.scanFromClipboard,
                    onSelected: () async {
                      final value = await ScreenCapturerPlatform.instance
                          .readImageFromClipboard();
                      if (value != null && mounted) {
                        await ImportTokenUtil.analyzeImage(
                          value,
                          context: context,
                        );
                      } else if (value == null) {
                        IToast.showTop(appLocalizations.clipboardNoImage);
                      }
                    },
                  ),
                ]),
                PlatformMenuItemGroup(members: [
                  PlatformMenuItem(
                    label: appLocalizations.scanFromRegionCapture,
                    onSelected: () => capture(CaptureMode.region),
                  ),
                  PlatformMenuItem(
                    label: appLocalizations.scanFromWindowCapture,
                    onSelected: () => capture(CaptureMode.window),
                  ),
                  PlatformMenuItem(
                    label: appLocalizations.scanFromScreenCapture,
                    onSelected: () => capture(CaptureMode.screen),
                  ),
                ]),
              ],
            ),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: appLocalizations.exportImport,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyI,
                control: true,
                alt: true,
              ),
              onSelected: () => RouteUtil.pushDialogRoute(
                chewieProvider.rootContext,
                const ImportExportTokenScreen(),
                onThen: (_) => ShortcutsUtil.restoreFocus(),
              ),
            ),
            PlatformMenuItem(
              label: appLocalizations.importFromThirdParty,
              onSelected: () => RouteUtil.pushDialogRoute(
                chewieProvider.rootContext,
                const ImportFromThirdPartyBottomSheet(),
                onThen: (_) => ShortcutsUtil.restoreFocus(),
              ),
            ),
          ]),
          PlatformMenuItemGroup(members: [
            PlatformMenuItem(
              label: appLocalizations.cloudBackupServiceSetting,
              onSelected: () => RouteUtil.pushDialogRoute(
                chewieProvider.rootContext,
                const CloudServiceScreen(showBack: false),
                onThen: (_) => ShortcutsUtil.restoreFocus(),
              ),
            ),
          ]),
        ],
      ),
      // View menu
      PlatformMenu(
        label: appLocalizations.menuView,
        menus: [
          PlatformMenu(
            label: appLocalizations.changeLayoutType,
            menus: [
              PlatformMenuItem(
                label: _checked(appLocalizations.simpleLayoutType,
                    homeScreenState?.layoutType == LayoutType.Simple),
                onSelected: () =>
                    homeScreenState?.changeLayoutType(LayoutType.Simple),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.compactLayoutType,
                    homeScreenState?.layoutType == LayoutType.Compact),
                onSelected: () =>
                    homeScreenState?.changeLayoutType(LayoutType.Compact),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.listLayoutType,
                    homeScreenState?.layoutType == LayoutType.List),
                onSelected: () =>
                    homeScreenState?.changeLayoutType(LayoutType.List),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.spotlightLayoutType,
                    homeScreenState?.layoutType == LayoutType.Spotlight),
                onSelected: () =>
                    homeScreenState?.changeLayoutType(LayoutType.Spotlight),
              ),
            ],
          ),
          PlatformMenu(
            label: appLocalizations.menuSortOrder,
            menus: [
              PlatformMenuItem(
                label: _checked(appLocalizations.defaultOrder,
                    homeScreenState?.orderType == OrderType.Default),
                onSelected: () =>
                    homeScreenState?.changeOrderType(type: OrderType.Default),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.alphabeticalASCOrder,
                    homeScreenState?.orderType == OrderType.AlphabeticalASC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.AlphabeticalASC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.alphabeticalDESCOrder,
                    homeScreenState?.orderType == OrderType.AlphabeticalDESC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.AlphabeticalDESC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.copyTimesDESCOrder,
                    homeScreenState?.orderType == OrderType.CopyTimesDESC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.CopyTimesDESC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.copyTimesASCOrder,
                    homeScreenState?.orderType == OrderType.CopyTimesASC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.CopyTimesASC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.lastCopyTimeDESCOrder,
                    homeScreenState?.orderType == OrderType.LastCopyTimeDESC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.LastCopyTimeDESC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.lastCopyTimeASCOrder,
                    homeScreenState?.orderType == OrderType.LastCopyTimeASC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.LastCopyTimeASC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.createTimeDESCOrder,
                    homeScreenState?.orderType == OrderType.CreateTimeDESC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.CreateTimeDESC),
              ),
              PlatformMenuItem(
                label: _checked(appLocalizations.createTimeASCOrder,
                    homeScreenState?.orderType == OrderType.CreateTimeASC),
                onSelected: () => homeScreenState?.changeOrderType(
                    type: OrderType.CreateTimeASC),
              ),
            ],
          ),
          PlatformMenuItemGroup(members: [
            PlatformMenu(
              label: appLocalizations.themeMode,
              menus: [
                PlatformMenuItem(
                  label: _checked(appLocalizations.followSystem,
                      appProvider.themeMode == ActiveThemeMode.system),
                  onSelected: () {
                    appProvider.themeMode = ActiveThemeMode.system;
                    setState(() {});
                  },
                ),
                PlatformMenuItem(
                  label: _checked(appLocalizations.lightTheme,
                      appProvider.themeMode == ActiveThemeMode.light),
                  onSelected: () {
                    appProvider.themeMode = ActiveThemeMode.light;
                    setState(() {});
                  },
                ),
                PlatformMenuItem(
                  label: _checked(appLocalizations.darkTheme,
                      appProvider.themeMode == ActiveThemeMode.dark),
                  onSelected: () {
                    appProvider.themeMode = ActiveThemeMode.dark;
                    setState(() {});
                  },
                ),
              ],
            ),
            PlatformMenu(
              label: appLocalizations.language,
              menus: LocaleUtil.localeLabels
                  .map((tuple) => PlatformMenuItem(
                        label: _checked(
                            tuple.item1,
                            appProvider.locale?.toString() ==
                                tuple.item2?.toString()),
                        onSelected: () {
                          appProvider.locale = tuple.item2;
                          setState(() {});
                        },
                      ))
                  .toList(),
            ),
            PlatformMenu(
              label: appLocalizations.fontFamily,
              menus: CustomFont.getAllFonts()
                  .map((font) => PlatformMenuItem(
                        label: _checked(
                            font.intlFontName, appProvider.currentFont == font),
                        onSelected: () {
                          CustomFont.loadFont(context, font,
                              autoRestartApp: true);
                        },
                      ))
                  .toList(),
            ),
          ]),
        ],
      ),
      // Tokens menu
      PlatformMenu(
        label: appLocalizations.menuTokens,
        menus: [
          if (_menuTokens.isNotEmpty)
            PlatformMenu(
              label: appLocalizations.allTokens,
              menus: _menuTokens
                  .map((token) => PlatformMenuItem(
                        label: token.issuer,
                        onSelected: () => _copyTokenCode(token),
                      ))
                  .toList(),
            ),
          ..._menuCategories.map(
            (category) => PlatformMenu(
              label: category.title,
              menus: category.tokens
                  .map((token) => PlatformMenuItem(
                        label: token.issuer,
                        onSelected: () => _copyTokenCode(token),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      // Window menu
      // PlatformMenu(
      //   label: appLocalizations.menuWindow,
      //   menus: [
      //     PlatformMenuItemGroup(members: [
      //       PlatformMenuItem(
      //         label: appLocalizations.minimize,
      //         shortcut: const SingleActivator(
      //           LogicalKeyboardKey.keyM,
      //           meta: true,
      //         ),
      //         onSelected: () => windowManager.minimize(),
      //       ),
      //       PlatformMenuItem(
      //         label: appLocalizations.zoom,
      //         onSelected: () => ResponsiveUtil.maximizeOrRestore(),
      //       ),
      //     ]),
      //     PlatformMenuItemGroup(members: [
      //       PlatformMenuItem(
      //         label: appLocalizations.lock,
      //         shortcut: const SingleActivator(
      //           LogicalKeyboardKey.keyL,
      //           control: true,
      //           alt: true,
      //         ),
      //         onSelected: () => ShortcutsUtil.lock(context),
      //       ),
      //     ]),
      //   ],
      // ),
      // Help menu
      PlatformMenu(
        label: appLocalizations.menuHelp,
        menus: [
          PlatformMenuItem(
            label: appLocalizations.shortcutHelp,
            shortcut: const SingleActivator(LogicalKeyboardKey.f1),
            onSelected: () => ShortcutsUtil.showShortcutHelp(context),
          ),
          PlatformMenuItem(
            label: 'GitHub',
            onSelected: () => UriUtil.launchUrlUri(context, repoUrl),
          ),
          PlatformMenuItem(
            label: appLocalizations.officialWebsite,
            onSelected: () =>
                UriUtil.launchUrlUri(context, cloudotpOfficialWebsite),
          ),
        ],
      ),
    ];
  }

  _buildDesktopBody() {
    if (ResponsiveUtil.isMacOS()) {
      return _buildMacOSDesktopBody();
    }
    return MyScaffold(
      backgroundColor: ChewieTheme.appBarBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          _buildSideBar(),
          Expanded(
            child: Stack(
              children: [
                HomeScreen(key: chewieProvider.panelScreenKey),
                Positioned(
                  right: 0,
                  child: _buildTitleBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildMacOSDesktopBody() {
    return MyScaffold(
      backgroundColor: ChewieTheme.appBarBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildMacOSTitleBar(),
          Expanded(
            child: Row(
              children: [
                _buildSideBar(),
                Expanded(
                  child: HomeScreen(key: chewieProvider.panelScreenKey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
    }
    setState(() {});
  }

  refresh() {
    if (ResponsiveUtil.isMacOS()) {
      loadMenuTokenData();
    }
    setState(() {});
  }

  static buildSortContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem.checkbox(
          appLocalizations.defaultOrder,
          checked: homeScreenState?.orderType == OrderType.Default,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.Default);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.alphabeticalASCOrder,
          checked: homeScreenState?.orderType == OrderType.AlphabeticalASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.AlphabeticalASC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.alphabeticalDESCOrder,
          checked: homeScreenState?.orderType == OrderType.AlphabeticalDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.AlphabeticalDESC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.copyTimesDESCOrder,
          checked: homeScreenState?.orderType == OrderType.CopyTimesDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CopyTimesDESC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.copyTimesASCOrder,
          checked: homeScreenState?.orderType == OrderType.CopyTimesASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CopyTimesASC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.lastCopyTimeDESCOrder,
          checked: homeScreenState?.orderType == OrderType.LastCopyTimeDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.LastCopyTimeDESC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.lastCopyTimeASCOrder,
          checked: homeScreenState?.orderType == OrderType.LastCopyTimeASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.LastCopyTimeASC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.createTimeDESCOrder,
          checked: homeScreenState?.orderType == OrderType.CreateTimeDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CreateTimeDESC);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.createTimeASCOrder,
          checked: homeScreenState?.orderType == OrderType.CreateTimeASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CreateTimeASC);
          },
        ),
      ],
    );
  }

  static buildLayoutContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem.checkbox(
          appLocalizations.simpleLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Simple,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Simple);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.compactLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Compact,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Compact);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.listLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.List,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.List);
          },
        ),
        FlutterContextMenuItem.checkbox(
          appLocalizations.spotlightLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Spotlight,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Spotlight);
          },
        ),
      ],
    );
  }

  FlutterContextMenu buildQrCodeContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.scanFromImageFile,
          iconData: LucideIcons.fileImage,
          onPressed: () async {
            FilePickerResult? result = await FileUtil.pickFiles(
              type: FileType.image,
              lockParentWindow: true,
            );
            if (result == null) return;
            await ImportTokenUtil.analyzeImageFile(
              result.files.single.path!,
              context: context,
            );
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.scanFromClipboard,
          iconData: LucideIcons.clipboardList,
          onPressed: () async {
            final value =
                await ScreenCapturerPlatform.instance.readImageFromClipboard();
            if (value != null && mounted) {
              await ImportTokenUtil.analyzeImage(value, context: context);
            } else if (value == null) {
              IToast.showTop(appLocalizations.clipboardNoImage);
            }
          },
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          appLocalizations.scanFromRegionCapture,
          iconData: LucideIcons.scanQrCode,
          onPressed: () async {
            await capture(CaptureMode.region);
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.scanFromWindowCapture,
          iconData: LucideIcons.scanSearch,
          onPressed: () async {
            await capture(CaptureMode.window);
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.scanFromScreenCapture,
          iconData: LucideIcons.fullscreen,
          onPressed: () async {
            await capture(CaptureMode.screen);
          },
        ),
      ],
    );
  }

  capture(
    CaptureMode mode, {
    bool reCaptureWhenFailed = true,
  }) async {
    try {
      appProvider.preventLock = true;
      windowManager.minimize();
      Directory directory = Directory(await FileUtil.getScreenshotDir());
      String imageName =
          'Screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
      String imagePath = path.join(directory.path, imageName);
      CapturedData? capturedData = await screenCapturer.capture(
        mode: mode,
        copyToClipboard: true,
        imagePath: imagePath,
        silent: true,
      );
      windowManager.restore();
      CustomLoadingDialog.showLoading(title: appLocalizations.analyzing);
      Uint8List? imageBytes = capturedData?.imageBytes;
      File file = File(imagePath);
      if (imageBytes == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (file.existsSync()) {
          imageBytes = file.readAsBytesSync();
          file.delete();
        } else {
          imageBytes =
              await ScreenCapturerPlatform.instance.readImageFromClipboard();
          if (imageBytes == null) {
            await Future.delayed(const Duration(milliseconds: 300));
            imageBytes =
                await ScreenCapturerPlatform.instance.readImageFromClipboard();
          }
        }
      } else {
        if (file.existsSync()) {
          file.delete();
        }
      }
      if (imageBytes == null) {
        IToast.showTop(appLocalizations.captureFailed);
        CustomLoadingDialog.dismissLoading();
        return;
      }
      await ImportTokenUtil.analyzeImage(
        context: context,
        imageBytes,
        showLoading: false,
        doDismissLoading: true,
      );
    } catch (e, t) {
      ILogger.error("Failed to capture and analyze image", e, t);
      if (e is PlatformException) {
        if (reCaptureWhenFailed) capture(mode, reCaptureWhenFailed: false);
      } else if (e is ProcessException) {
        windowManager.restore();
        if (ResponsiveUtil.isLinux()) {
          LinuxOSType osType = ResponsiveUtil.getLinuxOSType();
          IToast.showTop(appLocalizations
              .captureFailedNoProcess(osType.captureProcessName));
        }
      }
    } finally {
      appProvider.preventLock = false;
    }
  }

  Widget _buildSideBar({
    double width = 56,
    bool rightBorder = true,
  }) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) => Container(
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ChewieTheme.appBarBackgroundColor,
          border: rightBorder ? ChewieTheme.rightDivider : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                    height: ResponsiveUtil.isDesktop()
                        ? 8
                        : ResponsiveUtil.isLandscapeLayout()
                            ? 12
                            : 8),
                _buildLogo(),
                const SizedBox(height: 8),
                ToolButton(
                  key: _sidebarAddKey,
                  context: context,
                  tooltip: appLocalizations.addToken,
                  tooltipPosition: TooltipPosition.right,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  icon: LucideIcons.plus,
                  onPressed: () async {
                    DialogBuilder.showPageDialog(context,
                        child: const AddTokenScreen());
                  },
                ),
                const SizedBox(height: 4),
                ToolButton(
                  key: _sidebarCategoryKey,
                  context: context,
                  tooltip: appLocalizations.category,
                  tooltipPosition: TooltipPosition.right,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  icon: LucideIcons.shapes,
                  onPressed: () async {
                    DialogBuilder.showPageDialog(context,
                        child: const CategoryScreen());
                  },
                ),
                if (!ResponsiveUtil.isLandscapeTablet())
                  const SizedBox(height: 4),
                if (!ResponsiveUtil.isLandscapeTablet())
                  ToolButton(
                    key: _sidebarQrScanKey,
                    context: context,
                    tooltip: appLocalizations.scanToken,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    icon: LucideIcons.qrCode,
                    onPressed: () async {
                      BottomSheetBuilder.showContextMenu(
                          context, buildQrCodeContextMenuButtons());
                    },
                  ),
                const SizedBox(height: 4),
                ToolButton(
                  key: _sidebarImportKey,
                  context: context,
                  tooltip: appLocalizations.exportImport,
                  tooltipPosition: TooltipPosition.right,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  icon: LucideIcons.import,
                  onPressed: () async {
                    DialogBuilder.showPageDialog(
                      context,
                      child: const ImportExportTokenScreen(),
                    );
                  },
                ),
                const SizedBox(height: 4),
                ToolButton(
                  key: _sidebarImportThirdKey,
                  context: context,
                  tooltip: appLocalizations.importFromThirdParty,
                  icon: LucideIcons.waypoints,
                  tooltipPosition: TooltipPosition.right,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  onPressed: () async {
                    RouteUtil.pushDialogRoute(
                      context,
                      const ImportFromThirdPartyBottomSheet(),
                    );
                  },
                ),
                const SizedBox(height: 4),
                if (provider.showCloudBackupButton)
                  ToolButton(
                    key: _sidebarCloudBackupKey,
                    context: context,
                    tooltip: appLocalizations.cloudBackupServiceSetting,
                    icon: LucideIcons.cloudUpload,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () async {
                      DialogBuilder.showPageDialog(context,
                          child: const CloudServiceScreen(showBack: false));
                    },
                  ),
                if (ResponsiveUtil.isLandscapeTablet())
                  const SizedBox(height: 4),
                if (ResponsiveUtil.isLandscapeTablet())
                  ToolButton(
                    context: context,
                    tooltip: appLocalizations.select,
                    tooltipPosition: TooltipPosition.right,
                    icon: LucideIcons.listChecks,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      final tokens = homeScreenState?.tokens;
                      if (tokens != null && tokens.isNotEmpty) {
                        homeScreenState?.enterMultiSelectMode(tokens.first.uid);
                      }
                    },
                  ),
                const Spacer(),
                if (provider.showBackupLogButton) ...[
                  ToolButton(
                    key: _sidebarBackupLogKey,
                    context: context,
                    tooltip: appLocalizations.backupLogs,
                    tooltipPosition: TooltipPosition.right,
                    iconBuilder: (buttonContext) =>
                        Selector<AppProvider, LoadingStatus>(
                      selector: (context, appProvider) =>
                          appProvider.autoBackupLoadingStatus,
                      builder: (context, autoBackupLoadingStatus, child) =>
                          LoadingIcon(
                        status: autoBackupLoadingStatus,
                        normalIcon: const Icon(LucideIcons.history, size: 22),
                      ),
                    ),
                    onPressed: () {
                      BackupLogScreen.show(context);
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                if (provider.showSortButton) ...[
                  ToolButton(
                    key: _sidebarSortKey,
                    context: context,
                    icon: homeScreenState?.orderType.icon ??
                        LucideIcons.arrowUpNarrowWide,
                    tooltip: homeScreenState?.orderType.title,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      SortSelectScreen.show(context);
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                if (provider.showLayoutButton) ...[
                  ToolButton(
                    key: _sidebarLayoutKey,
                    context: context,
                    icon: homeScreenState?.layoutType.icon ??
                        LucideIcons.layoutDashboard,
                    tooltip: homeScreenState?.layoutType.title,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      LayoutSelectScreen.show(context);
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                ToolButton(
                  key: _sidebarFeatureShowcaseKey,
                  context: context,
                  tooltip: appLocalizations.featureShowcase,
                  tooltipPosition: TooltipPosition.right,
                  icon: LucideIcons.telescope,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  onPressed: () {
                    FeatureShowcaseScreen.showAsDialog(context);
                  },
                ),
                const SizedBox(height: 4),
                ToolButton.dynamicButton(
                  tooltip: appLocalizations.themeMode,
                  iconBuilder: (context, isDark) =>
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                  onTap: changeMode,
                  tooltipPosition: TooltipPosition.right,
                  onChangemode: (context, themeMode, child) {},
                  iconSize: 22,
                ),
                if (kDebugMode)
                  const SizedBox(height: 4),
                if (kDebugMode)
                  ToolButton(
                    context: context,
                    tooltip: "Reset Welcome",
                    tooltipPosition: TooltipPosition.right,
                    icon: LucideIcons.rotateCcw,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      ChewieHiveUtil.put(
                          CloudOTPHiveUtil.haveShownWelcome4Key, false);
                      ChewieHiveUtil.put(
                          CloudOTPHiveUtil.haveShownCoachMarkKey, false);
                      ChewieHiveUtil.put(
                          CloudOTPHiveUtil.haveShownDesktopCoachMarkKey, false);
                      IToast.showTop("Welcome screen reset");
                    },
                  ),
                const SizedBox(height: 4),
                ToolButton(
                  key: _sidebarSettingKey,
                  context: context,
                  tooltip: appLocalizations.setting,
                  tooltipPosition: TooltipPosition.right,
                  icon: LucideIcons.bolt,
                  padding: const EdgeInsets.all(8),
                  iconSize: 22,
                  onPressed: () {
                    RouteUtil.pushDialogRoute(
                        context, const SettingNavigationScreen());
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({
    double size = 32,
  }) {
    return ToolButton(
      key: _sidebarLogoKey,
      context: context,
      tooltip: appLocalizations.shortcut,
      tooltipPosition: TooltipPosition.right,
      padding: const EdgeInsets.all(4),
      iconSize: size,
      iconBuilder: (_) => ClipRRect(
        borderRadius: ChewieDimens.borderRadius8,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/logo-transparent.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      onPressed: () => ShortcutsUtil.showShortcutHelp(context),
    );
  }

  Widget _buildTitleBar() {
    return ResponsiveUtil.selectByPlatform(
      desktop: WindowTitleWrapper(
        height: 48,
        isStayOnTop: isStayOnTop,
        isMaximized: isMaximized,
        backgroundColor: Colors.transparent,
        onStayOnTopTap: () {
          setState(() {
            isStayOnTop = !isStayOnTop;
            windowManager.setAlwaysOnTop(isStayOnTop);
          });
        },
      ),
    );
  }

  Widget _buildMacOSTitleBar() {
    return Container(
      decoration: BoxDecoration(
        color: ChewieTheme.appBarBackgroundColor,
        border: ChewieTheme.bottomDivider,
      ),
      child: WindowTitleWrapper(
        height: 48,
        backgroundColor: Colors.transparent,
        isStayOnTop: isStayOnTop,
        isMaximized: isMaximized,
        onStayOnTopTap: () {
          setState(() {
            isStayOnTop = !isStayOnTop;
            windowManager.setAlwaysOnTop(isStayOnTop);
          });
        },
        leftWidgets: [
          const SizedBox(width: macosTitleBarLeftMargin),
          Container(
            key: _searchBarKey,
            constraints: const BoxConstraints(
                maxWidth: 300, minWidth: 200, maxHeight: 36),
            child: MySearchBar(
              borderRadius: 8,
              bottomMargin: 18,
              focusNode: appProvider.searchFocusNode,
              controller: searchController,
              background: ChewieTheme.scaffoldBackgroundColor,
              hintText: appLocalizations.searchToken,
              onSubmitted: (text) {
                homeScreenState?.performSearch(text.toString());
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    _timer = Timer(
      Duration(seconds: appProvider.autoLockTime.seconds),
      () {
        if (!appProvider.preventLock && CloudOTPHiveUtil.shouldAutoLock()) {
          jumpToLock();
        }
      },
    );
  }

  void _startAutoBackupOnLaunch() {
    if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.enableBackupOnLaunchKey)) {
      ExportTokenUtil.autoBackup(
          triggerType: AutoBackupTriggerType.appStartup);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        cancleTimer();
        break;
      case AppLifecycleState.paused:
        setTimer();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    appProvider.refreshSystemLocale();
  }

  @override
  void dispose() {
    protocolHandler.removeListener(this);
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    ChewieUtils.displayApp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    await Utils.processTrayMenuItemClick(context, menuItem, false);
  }

  @override
  bool get wantKeepAlive => true;
}
