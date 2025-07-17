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
import 'package:cloudotp/Screens/Lock/database_decrypt_screen.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/Utils/shortcuts_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../TokenUtils/import_token_util.dart';
import '../Utils/app_provider.dart';
import '../Utils/hive_util.dart';
import '../Utils/lottie_util.dart';
import '../Utils/utils.dart';
import '../Widgets/BottomSheet/import_from_third_party_bottom_sheet.dart';
import '../l10n/l10n.dart';
import 'Backup/cloud_service_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/backup_log_screen.dart';
import 'Setting/setting_navigation_screen.dart';
import 'Token/category_screen.dart';

const borderColor = Color(0xFF805306);
const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = "/";

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends BaseDynamicState<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TrayListener,
        ProtocolListener,
        WindowListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  Orientation _oldOrientation = Orientation.portrait;
  TextEditingController searchController = TextEditingController();

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
  Future<void> onWindowResize() async {
    super.onWindowResize();
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    ChewieHiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMove() async {
    super.onWindowMove();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    ChewieHiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == "hide") {
      setTimer();
    }
  }

  @override
  void onWindowMaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.setMinimumSize(ChewieProvider.minimumWindowSize);
    setState(() {
      _isMaximized = false;
    });
  }

  void pushRootPage(Widget page) {
    Navigator.pushAndRemoveUntil(
        context, RouteUtil.getFadeRoute(page), (route) => false);
  }

  @override
  void onProtocolUrlReceived(String url) {
    ILogger.info("Protocol url received", url);
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
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    CloudOTPHiveUtil.showCloudEntry().then((value) {
      appProvider.canShowCloudBackupButton = value;
    });
    fetchReleases();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _oldOrientation = MediaQuery.of(context).orientation;
      chewieProvider.rootContext = context;
      if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoFocusSearchBarKey,
          defaultValue: false)) {
        ShortcutsUtil.focusSearch();
      }
      if (ResponsiveUtil.isDesktop()) {
        await Utils.initTray();
        trayManager.addListener(this);
        // keyboardHandlerState?.focus();
      }
    });
    initGlobalConfig();
    searchController.addListener(() {
      homeScreenState?.performSearch(searchController.text);
    });
  }

  initGlobalConfig() {
    if (ResponsiveUtil.isDesktop()) {
      windowManager
          .isAlwaysOnTop()
          .then((value) => setState(() => _isStayOnTop = value));
      windowManager
          .isMaximized()
          .then((value) => setState(() => _isMaximized = value));
    }
    ResponsiveUtil.checkSizeCondition();
    EasyRefresh.defaultHeaderBuilder = () => LottieCupertinoHeader(
          backgroundColor: ChewieTheme.canvasColor,
          indicator:
              LottieFiles.load(LottieFiles.getLoadingPath(context), scale: 1.5),
          hapticFeedback: true,
          triggerOffset: 40,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          indicator: LottieFiles.load(LottieFiles.getLoadingPath(context)),
        );
    chewieProvider.loadingWidgetBuilder = (size, forceDark) =>
        LottieFiles.load(LottieFiles.getLoadingPath(context), scale: 1.5);
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
  }

  Future<void> jumpToLock({
    bool autoAuth = false,
  }) async {
    if (DatabaseManager.isDatabaseEncrypted &&
        CloudOTPHiveUtil.getEncryptDatabaseStatus() ==
            EncryptDatabaseStatus.customPassword) {
      await DatabaseManager.resetDatabase();
      pushRootPage(const DatabaseDecryptScreen());
    } else {
      pushRootPage(
        PinVerifyScreen(
          onSuccess: () {},
          showWindowTitle: true,
          isModal: true,
          autoAuth: autoAuth,
          jumpToMain: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(
        CloudOTPHiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    super.build(context);
    return OrientationBuilder(builder: (ctx, ori) {
      if (ori != _oldOrientation) {
        // globalNavigatorState?.popUntil((route) => route.isFirst);
      }
      _oldOrientation = ori;
      return _buildBodyByPlatform();
    });
  }

  _buildBodyByPlatform() {
    if (!ResponsiveUtil.isLandscape()) {
      return _buildMobileBody();
    } else if (ResponsiveUtil.isMobile()) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: ChewieTheme.appBarBackgroundColor,
          resizeToAvoidBottomInset: false,
          body: SafeArea(child: _buildDesktopBody()),
        ),
      );
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return HomeScreen(key: chewieProvider.panelScreenKey);
  }

  _buildDesktopBody() {
    var leftPosWidget = Row(
      children: [
        _sideBar(),
        Expanded(
          child: Stack(
            children: [
              HomeScreen(key: chewieProvider.panelScreenKey),
              Positioned(
                right: 0,
                child: _titleBar(),
              ),
            ],
          ),
        ),
      ],
    );
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: leftPosWidget,
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
        // ContextMenuButtonConfig.checkbox(
        //   appLocalizations.tileLayoutType,
        //   checked: homeScreenState?.layoutType == LayoutType.Tile,
        //   onPressed: () {
        //     homeScreenState?.changeLayoutType(LayoutType.Tile);
        //   },
        // ),
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

  _buildQrCodeContextMenuButtons() {
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
          onPressed: () {
            ScreenCapturerPlatform.instance
                .readImageFromClipboard()
                .then((value) {
              if (value != null) {
                ImportTokenUtil.analyzeImage(value, context: context);
              } else {
                IToast.showTop(appLocalizations.clipboardNoImage);
              }
            });
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
          IToast.showTop(
              appLocalizations.captureFailedNoProcess(osType.captureProcessName));
        }
      }
    }
  }

  _sideBar({
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
                ResponsiveUtil.buildGeneralWidget(
                  desktop: const SizedBox(height: 8),
                  landscape: const SizedBox(height: 12),
                  portrait: const SizedBox(height: 8),
                ),
                _buildLogo(),
                const SizedBox(height: 8),
                ToolButton(
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
                    context: context,
                    tooltip: appLocalizations.scanToken,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    icon: LucideIcons.qrCode,
                    onPressed: () async {
                      BottomSheetBuilder.showContextMenu(
                          context, _buildQrCodeContextMenuButtons());
                    },
                  ),
                const SizedBox(height: 4),
                ToolButton(
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
                if (provider.canShowCloudBackupButton &&
                    provider.showCloudBackupButton)
                  ToolButton(
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
                const Spacer(),
                if (provider.showBackupLogButton) ...[
                  ToolButton(
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
                      BottomSheetBuilder.showGenericContextMenu(
                          context, const BackupLogScreen(isOverlay: true));
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                if (provider.showSortButton) ...[
                  ToolButton(
                    context: context,
                    icon: homeScreenState?.orderType.icon ??
                        LucideIcons.arrowUpNarrowWide,
                    tooltip: homeScreenState?.orderType.title,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      BottomSheetBuilder.showContextMenu(
                          context, buildSortContextMenuButtons());
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                if (provider.showLayoutButton) ...[
                  ToolButton(
                    context: context,
                    icon: homeScreenState?.layoutType.icon ??
                        LucideIcons.layoutDashboard,
                    tooltip: homeScreenState?.layoutType.title,
                    tooltipPosition: TooltipPosition.right,
                    padding: const EdgeInsets.all(8),
                    iconSize: 22,
                    onPressed: () {
                      BottomSheetBuilder.showContextMenu(
                          context, buildLayoutContextMenuButtons());
                    },
                  ),
                  const SizedBox(height: 4),
                ],
                ToolButton.dynamicButton(
                  tooltip: appLocalizations.themeMode,
                  iconBuilder: (context, isDark) =>
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                  onTap: changeMode,
                  tooltipPosition: TooltipPosition.right,
                  onChangemode: (context, themeMode, child) {},
                  iconSize: 22,
                ),
                const SizedBox(height: 4),
                ToolButton(
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

  _buildLogo({
    double size = 32,
  }) {
    return IgnorePointer(
      child: ClipRRect(
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
    );
  }

  _titleBar() {
    return ResponsiveUtil.buildDesktopWidget(
      desktop: WindowTitleWrapper(
        height: 48,
        isStayOnTop: _isStayOnTop,
        isMaximized: _isMaximized,
        backgroundColor: Colors.transparent,
        onStayOnTopTap: () {
          setState(() {
            _isStayOnTop = !_isStayOnTop;
            windowManager.setAlwaysOnTop(_isStayOnTop);
          });
        },
      ),
    );
  }

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    // _timer = Timer(
    //   Duration(seconds: appProvider.autoLockTime.seconds),
    //   () {
    //     if (!appProvider.preventLock && ChewieHiveUtil.shouldAutoLock()) {
    //       jumpToLock();
    //     }
    //   },
    // );
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
    Utils.processTrayMenuItemClick(context, menuItem, false);
  }

  @override
  bool get wantKeepAlive => true;
}
