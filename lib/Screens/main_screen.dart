import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_navigation_screen.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/TokenUtils/code_generator.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Utils/constant.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/uri_util.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Window/window_caption.dart';
import 'package:context_menus/context_menus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../Resources/colors.dart';
import '../Resources/fonts.dart';
import '../TokenUtils/import_token_util.dart';
import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/hive_util.dart';
import '../Utils/ilogger.dart';
import '../Utils/itoast.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/Custom/loading_icon.dart';
import '../Widgets/Dialog/custom_dialog.dart';
import '../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../Widgets/General/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import '../Widgets/Window/window_button.dart';
import '../generated/l10n.dart';
import 'Backup/cloud_service_screen.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/backup_log_screen.dart';
import 'Setting/setting_safe_screen.dart';
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

class MainScreenState extends State<MainScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TrayListener,
        ProtocolListener,
        WindowListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _hasJumpedToPinVerify = false;
  Orientation _oldOrientation = Orientation.portrait;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

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
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
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
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onProtocolUrlReceived(String url) {
    ILogger.info("Protocol url received", log);
  }

  Future<void> fetchReleases() async {
    Utils.getReleases(
      context: context,
      showLoading: false,
      showUpdateDialog: HiveUtil.getBool(HiveUtil.autoCheckUpdateKey),
      showNoUpdateToast: false,
    );
  }

  focusSearch() {
    searchFocusNode.requestFocus();
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        keyboardHandlerState?.focus();
      }
    });
  }

  @override
  void initState() {
    _oldOrientation = MediaQuery.of(rootContext).orientation;
    trayManager.addListener(this);
    windowManager.addListener(this);
    if (ResponsiveUtil.isDesktop()) protocolHandler.addListener(this);
    super.initState();
    if (ResponsiveUtil.isDesktop()) {
      Utils.initTray();
    }
    WidgetsBinding.instance.addObserver(this);
    FontEnum.downloadFont(showToast: false);
    HiveUtil.showCloudEntry().then((value) {
      appProvider.canShowCloudBackupButton = value;
    });
    fetchReleases();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      darkModeWidget = LottieUtil.load(
        LottieUtil.sunLight,
        size: 25,
        autoForward: !Utils.isDark(context),
        controller: darkModeController,
      );
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
          backgroundColor: Theme.of(context).canvasColor,
          indicator:
              LottieUtil.load(LottieUtil.getLoadingPath(context), scale: 1.5),
          hapticFeedback: true,
          triggerOffset: 40,
        );
    EasyRefresh.defaultFooterBuilder = () => LottieCupertinoFooter(
          indicator: LottieUtil.load(LottieUtil.getLoadingPath(context)),
        );
    if (ResponsiveUtil.isMobile()) {
      if (HiveUtil.getBool(HiveUtil.enableSafeModeKey)) {
        FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  void jumpToPinVerify({
    bool autoAuth = false,
  }) {
    _hasJumpedToPinVerify = true;
    RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {},
          isModal: true,
          autoAuth: autoAuth,
        ), onThen: (_) {
      _hasJumpedToPinVerify = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OrientationBuilder(builder: (ctx, ori) {
      if (ori != _oldOrientation) {
        // globalNavigatorState?.popUntil((route) => route.isFirst);
      }
      _oldOrientation = ori;
      return _buildBodyByPlatform();
    });
  }

  goHome() {
    while (Navigator.of(rootContext).canPop()) {
      Navigator.of(rootContext).pop();
    }
    while (desktopNavigatorState!.canPop()) {
      desktopNavigatorState?.pop();
    }
    appProvider.canPopByProvider = false;
  }

  _buildBodyByPlatform() {
    if (!ResponsiveUtil.isLandscape()) {
      return _buildMobileBody();
    } else if (ResponsiveUtil.isMobile()) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          MoveToBackground.moveTaskToBack();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(child: _buildDesktopBody()),
        ),
      );
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return HomeScreen(key: homeScreenKey);
  }

  _buildDesktopBody() {
    var leftPosWidget = Column(
      children: [
        _titleBar(),
        Expanded(
          child: Row(
            children: [
              _sideBar(leftPadding: 4, rightPadding: 4, topPadding: 8),
              Expanded(
                child: _desktopMainContent(rightMargin: 5),
              ),
            ],
          ),
        ),
      ],
    );
    var rightPosWidget = Column(
      children: [
        _titleBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _desktopMainContent(leftMargin: 5),
              ),
              _sideBar(leftPadding: 8, rightPadding: 8, topPadding: 8),
            ],
          ),
        ),
      ],
    );
    var bottomPosWidget = Column(
      children: [
        _titleBar(),
        Expanded(
          child: _desktopMainContent(leftMargin: 5, rightMargin: 5),
        ),
        RotatedBox(
          quarterTurns: 3,
          child: _sideBar(
              quarterTurns: 1, leftPadding: 8, rightPadding: 8, topPadding: 5),
        ),
      ],
    );
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: leftPosWidget,
    );
  }

  changeMode() {
    if (Utils.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  static buildSortContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig.checkbox(
          S.current.defaultOrder,
          checked: homeScreenState?.orderType == OrderType.Default,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.Default);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.alphabeticalASCOrder,
          checked: homeScreenState?.orderType == OrderType.AlphabeticalASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.AlphabeticalASC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.alphabeticalDESCOrder,
          checked: homeScreenState?.orderType == OrderType.AlphabeticalDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.AlphabeticalDESC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.copyTimesDESCOrder,
          checked: homeScreenState?.orderType == OrderType.CopyTimesDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CopyTimesDESC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.copyTimesASCOrder,
          checked: homeScreenState?.orderType == OrderType.CopyTimesASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CopyTimesASC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.lastCopyTimeDESCOrder,
          checked: homeScreenState?.orderType == OrderType.LastCopyTimeDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.LastCopyTimeDESC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.lastCopyTimeASCOrder,
          checked: homeScreenState?.orderType == OrderType.LastCopyTimeASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.LastCopyTimeASC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.createTimeDESCOrder,
          checked: homeScreenState?.orderType == OrderType.CreateTimeDESC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CreateTimeDESC);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.createTimeASCOrder,
          checked: homeScreenState?.orderType == OrderType.CreateTimeASC,
          onPressed: () {
            homeScreenState?.changeOrderType(type: OrderType.CreateTimeASC);
          },
        ),
      ],
    );
  }

  static buildLayoutContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig.checkbox(
          S.current.simpleLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Simple,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Simple);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.compactLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Compact,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Compact);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.tileLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Tile,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Tile);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.listLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.List,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.List);
          },
        ),
        ContextMenuButtonConfig.checkbox(
          S.current.spotlightLayoutType,
          checked: homeScreenState?.layoutType == LayoutType.Spotlight,
          onPressed: () {
            homeScreenState?.changeLayoutType(LayoutType.Spotlight);
          },
        ),
      ],
    );
  }

  _buildQrCodeContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.scanFromImageFile,
          onPressed: () async {
            FilePickerResult? result = await FileUtil.pickFiles(
              type: FileType.image,
              lockParentWindow: true,
            );
            if (result == null) return;
            await ImportTokenUtil.analyzeImageFile(result.files.single.path!,
                context: context);
          },
        ),
        ContextMenuButtonConfig(
          S.current.scanFromClipboard,
          onPressed: () {
            ScreenCapturerPlatform.instance
                .readImageFromClipboard()
                .then((value) {
              if (value != null) {
                ImportTokenUtil.analyzeImage(value, context: context);
              } else {
                IToast.showTop(S.current.clipboardNoImage);
              }
            });
          },
        ),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig(
          S.current.scanFromRegionCapture,
          onPressed: () async {
            await capture(CaptureMode.region);
          },
        ),
        ContextMenuButtonConfig(
          S.current.scanFromWindowCapture,
          onPressed: () async {
            await capture(CaptureMode.window);
          },
        ),
        ContextMenuButtonConfig(
          S.current.scanFromScreenCapture,
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
      String imagePath = '${directory.path}\\$imageName';
      CapturedData? capturedData = await screenCapturer.capture(
        mode: mode,
        copyToClipboard: true,
        imagePath: imagePath,
        silent: true,
      );
      windowManager.restore();
      CustomLoadingDialog.showLoading(title: S.current.analyzing);
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
        IToast.showTop(S.current.captureFailed);
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
      }
    }
  }

  _sideBar({
    int quarterTurns = 0,
    double topPadding = 5,
    double leftPadding = 0,
    double rightPadding = 0,
  }) {
    return Container(
      width: 40 + leftPadding + rightPadding,
      alignment: Alignment.center,
      color: Colors.transparent,
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      child: Stack(
        children: [
          if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
          Consumer<AppProvider>(
            builder: (context, provider, child) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: topPadding),
                // if (ResponsiveUtil.isTablet()) _buildLogo(size: 36),
                ItemBuilder.buildIconTextButton(
                  context,
                  quarterTurns: quarterTurns,
                  text: S.current.addToken,
                  direction: Axis.vertical,
                  showText: false,
                  fontSizeDelta: -2,
                  icon: const Icon(Icons.add_rounded),
                  onTap: () async {
                    DialogBuilder.showPageDialog(context,
                        child: const AddTokenScreen(), showClose: false);
                  },
                ),
                const SizedBox(height: 4),
                ItemBuilder.buildIconTextButton(
                  context,
                  quarterTurns: quarterTurns,
                  text: S.current.category,
                  fontSizeDelta: -2,
                  showText: false,
                  direction: Axis.vertical,
                  icon: const Icon(Icons.category_outlined),
                  onTap: () async {
                    DialogBuilder.showPageDialog(context,
                        child: const CategoryScreen(), showClose: false);
                  },
                ),
                if (!ResponsiveUtil.isLandscapeTablet())
                  const SizedBox(height: 4),
                if (!ResponsiveUtil.isLandscapeTablet())
                  ItemBuilder.buildIconTextButton(
                    context,
                    quarterTurns: quarterTurns,
                    text: S.current.scanToken,
                    fontSizeDelta: -2,
                    showText: false,
                    direction: Axis.vertical,
                    icon: const Icon(Icons.qr_code_rounded),
                    onTap: () async {
                      context.contextMenuOverlay
                          .show(_buildQrCodeContextMenuButtons());
                    },
                  ),
                const SizedBox(height: 4),
                ItemBuilder.buildIconTextButton(
                  context,
                  quarterTurns: quarterTurns,
                  text: S.current.exportImport,
                  fontSizeDelta: -2,
                  showText: false,
                  direction: Axis.vertical,
                  icon: const Icon(Icons.import_export_rounded),
                  onTap: () async {
                    DialogBuilder.showPageDialog(
                      context,
                      child: const ImportExportTokenScreen(),
                    );
                  },
                ),
                const SizedBox(height: 4),
                if (provider.canShowCloudBackupButton &&
                    provider.showCloudBackupButton)
                  ItemBuilder.buildIconTextButton(
                    context,
                    quarterTurns: quarterTurns,
                    text: S.current.cloudBackupServiceSetting,
                    fontSizeDelta: -2,
                    showText: false,
                    direction: Axis.vertical,
                    icon: const Icon(Icons.cloud_queue_rounded),
                    onTap: () async {
                      DialogBuilder.showPageDialog(context,
                          child: const CloudServiceScreen(), showClose: true);
                    },
                  ),
                const Spacer(),
                const SizedBox(height: 8),
                if (provider.showSortButton)
                  ItemBuilder.buildIconButton(
                    context: context,
                    quarterTurns: quarterTurns,
                    icon: const Icon(Icons.sort_rounded, size: 22),
                    onTap: () {
                      context.contextMenuOverlay
                          .show(buildSortContextMenuButtons());
                    },
                  ),
                if (provider.showLayoutButton)
                  ItemBuilder.buildIconButton(
                    context: context,
                    quarterTurns: quarterTurns,
                    icon: const Icon(Icons.dashboard_outlined, size: 22),
                    onTap: () {
                      context.contextMenuOverlay
                          .show(buildLayoutContextMenuButtons());
                    },
                  ),
                ItemBuilder.buildDynamicIconButton(
                  context: context,
                  quarterTurns: quarterTurns,
                  icon: darkModeWidget,
                  onTap: changeMode,
                  onChangemode: (context, themeMode, child) {
                    if (darkModeController.duration != null) {
                      if (themeMode == ActiveThemeMode.light) {
                        darkModeController.forward();
                      } else if (themeMode == ActiveThemeMode.dark) {
                        darkModeController.reverse();
                      } else {
                        if (Utils.isDark(context)) {
                          darkModeController.reverse();
                        } else {
                          darkModeController.forward();
                        }
                      }
                    }
                  },
                ),
                const SizedBox(width: 6),
                ItemBuilder.buildDynamicIconButton(
                  context: context,
                  quarterTurns: quarterTurns,
                  icon: AssetUtil.loadDouble(
                    context,
                    AssetUtil.settingLightIcon,
                    AssetUtil.settingDarkIcon,
                  ),
                  onTap: () async {
                    RouteUtil.pushDialogRoute(
                        context, const SettingNavigationScreen());
                  },
                ),
                const SizedBox(width: 6),
                ItemBuilder.buildIconButton(
                  context: context,
                  quarterTurns: quarterTurns,
                  icon: const Icon(Icons.info_outline_rounded, size: 22),
                  onTap: () async {
                    RouteUtil.pushDialogRoute(
                        context, const AboutSettingScreen());
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildLogo({
    double size = 50,
  }) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
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
    return (ResponsiveUtil.isDesktop())
        ? Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: WindowTitleBar(
              useMoveHandle: ResponsiveUtil.isDesktop(),
              titleBarHeightDelta: 34,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 2.5),
                  _buildLogo(),
                  const SizedBox(width: 8),
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 300, minWidth: 200),
                    child: ItemBuilder.buildDesktopSearchBar(
                      context: context,
                      borderRadius: 8,
                      bottomMargin: 18,
                      hintFontSizeDelta: 1,
                      focusNode: searchFocusNode,
                      controller: searchController,
                      background: Colors.grey.withAlpha(40),
                      hintText: S.current.searchToken,
                      onSubmitted: (text) {
                        homeScreenState?.performSearch(text);
                      },
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Selector<AppProvider, bool>(
                        selector: (context, appProvider) =>
                            appProvider.showBackupLogButton,
                        builder: (context, showBackupLogButton, child) =>
                            showBackupLogButton
                                ? WindowButton(
                                    colors:
                                        MyColors.getNormalButtonColors(context),
                                    borderRadius: BorderRadius.circular(8),
                                    padding: EdgeInsets.zero,
                                    iconBuilder: (buttonContext) =>
                                        Selector<AppProvider, LoadingStatus>(
                                      selector: (context, appProvider) =>
                                          appProvider.autoBackupLoadingStatus,
                                      builder: (context,
                                              autoBackupLoadingStatus, child) =>
                                          LoadingIcon(
                                        status: autoBackupLoadingStatus,
                                        normalIcon: const Icon(
                                            Icons.history_rounded,
                                            size: 25),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.contextMenuOverlay
                                          .show(const BackupLogScreen());
                                    },
                                  )
                                : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 3),
                      StayOnTopWindowButton(
                        context: context,
                        rotateAngle: _isStayOnTop ? 0 : -pi / 4,
                        colors: _isStayOnTop
                            ? MyColors.getStayOnTopButtonColors(context)
                            : MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          setState(() {
                            _isStayOnTop = !_isStayOnTop;
                            windowManager.setAlwaysOnTop(_isStayOnTop);
                          });
                        },
                      ),
                      const SizedBox(width: 3),
                      MinimizeWindowButton(
                        colors: MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 3),
                      _isMaximized
                          ? RestoreWindowButton(
                              colors: MyColors.getNormalButtonColors(context),
                              borderRadius: BorderRadius.circular(8),
                              onPressed: ResponsiveUtil.maximizeOrRestore,
                            )
                          : MaximizeWindowButton(
                              colors: MyColors.getNormalButtonColors(context),
                              borderRadius: BorderRadius.circular(8),
                              onPressed: ResponsiveUtil.maximizeOrRestore,
                            ),
                      const SizedBox(width: 3),
                      CloseWindowButton(
                        colors: MyColors.getCloseButtonColors(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          if (HiveUtil.getBool(HiveUtil.showTrayKey) &&
                              HiveUtil.getBool(HiveUtil.enableCloseToTrayKey)) {
                            windowManager.hide();
                          } else {
                            windowManager.close();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          )
        : emptyWidget;
  }

  _desktopMainContent({
    double leftMargin = 0,
    double rightMargin = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(left: leftMargin, right: rightMargin),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Navigator(
          key: desktopNavigatorKey,
          onGenerateRoute: (settings) {
            return RouteUtil.getFadeRoute(HomeScreen(key: homeScreenKey));
          },
        ),
      ),
    );
  }

  void cancleTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void setTimer() {
    if (!_hasJumpedToPinVerify) {
      _timer = Timer(
        Duration(minutes: appProvider.autoLockTime),
        () {
          if (HiveUtil.shouldAutoLock()) {
            jumpToPinVerify();
          }
        },
      );
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
  void dispose() {
    protocolHandler.removeListener(this);
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    darkModeController.dispose();
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
    windowManager.restore();
  }

  @override
  void onTrayIconRightMouseDown() {
    if (!_hasJumpedToPinVerify) trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == TrayKey.displayApp.key) {
      Utils.displayApp();
    } else if (menuItem.key == TrayKey.lockApp.key) {
      if (HiveUtil.canLock()) {
        jumpToPinVerify();
      } else {
        IToast.showDesktopNotification(
          S.current.noGestureLock,
          body: S.current.noGestureLockTip,
          actions: [S.current.cancel, S.current.goToSetGestureLock],
          onClick: () {
            Utils.displayApp();
            RouteUtil.pushDialogRoute(context, const SafeSettingScreen());
          },
          onClickAction: (index) {
            if (index == 1) {
              Utils.displayApp();
              RouteUtil.pushDialogRoute(context, const SafeSettingScreen());
            }
          },
        );
      }
    } else if (menuItem.key == TrayKey.setting.key) {
      Utils.displayApp();
      RouteUtil.pushDialogRoute(context, const SettingNavigationScreen());
    } else if (menuItem.key == TrayKey.about.key) {
      Utils.displayApp();
      RouteUtil.pushDialogRoute(context, const AboutSettingScreen());
    } else if (menuItem.key == TrayKey.officialWebsite.key) {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (Utils.isNotEmpty(menuItem.key) &&
        menuItem.key!.startsWith(TrayKey.copyTokenCode.key)) {
      int id = int.parse(menuItem.key!.split('-').last);
      OtpToken? token = await TokenDao.getTokenById(id);
      if (token != null) {
        double currentProgress = token.period == 0
            ? 0
            : (token.period * 1000 -
                    (DateTime.now().millisecondsSinceEpoch %
                        (token.period * 1000))) /
                (token.period * 1000);
        if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
            currentProgress < autoCopyNextCodeProgressThrehold) {
          Utils.copy(context, CodeGenerator.getNextCode(token),
              toastText: S.current.alreadyCopiedNextCode);
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            S.current.alreadyCopiedNextCode,
            body: CodeGenerator.getNextCode(token),
          );
        } else {
          Utils.copy(context, CodeGenerator.getCurrentCode(token));
          TokenDao.incTokenCopyTimes(token);
          IToast.showDesktopNotification(
            S.current.copySuccess,
            body: CodeGenerator.getCurrentCode(token),
          );
        }
      }
    } else if (menuItem.key == TrayKey.githubRepository.key) {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == TrayKey.checkUpdates.key) {
      Utils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showNoUpdateToast: false,
        showDesktopNotification: true,
      );
    } else if (menuItem.key == TrayKey.launchAtStartup.key) {
      menuItem.checked = !(menuItem.checked == true);
      HiveUtil.put(HiveUtil.launchAtStartupKey, menuItem.checked);
      generalSettingScreenState?.refreshLauchAtStartup();
      if (menuItem.checked == true) {
        await LaunchAtStartup.instance.enable();
      } else {
        await LaunchAtStartup.instance.disable();
      }
      Utils.initTray();
    } else if (menuItem.key == TrayKey.exitApp.key) {
      windowManager.close();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
