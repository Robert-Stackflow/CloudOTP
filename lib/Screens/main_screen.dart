import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:cloudotp/Resources/colors.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
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
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zxing2/qrcode.dart';

import '../Resources/fonts.dart';
import '../TokenUtils/import_token_util.dart';
import '../Utils/app_provider.dart';
import '../Utils/enums.dart';
import '../Utils/hive_util.dart';
import '../Utils/iprint.dart';
import '../Utils/itoast.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../Widgets/General/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import '../Widgets/Scaffold/my_scaffold.dart';
import '../Widgets/Window/window_button.dart';
import '../generated/l10n.dart';
import 'Lock/pin_verify_screen.dart';
import 'Setting/setting_screen.dart';
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
        WindowListener,
        AutomaticKeepAliveClientMixin {
  Timer? _timer;
  late AnimationController darkModeController;
  Widget? darkModeWidget;
  bool _isMaximized = false;
  bool _isStayOnTop = false;
  bool _hasJumpedToPinVerify = false;
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

  Future<void> initDeepLinks() async {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        UriUtil.processUrl(context, uri.toString(), pass: false);
      }
    }, onError: (Object err) {
      IPrint.debug('Failed to get URI: $err');
    });
  }

  Future<void> fetchReleases() async {
    if (HiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) {
      Utils.getReleases(
        context: context,
        showLoading: false,
        showUpdateDialog: true,
        showNoUpdateToast: false,
      );
    }
  }

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initDeepLinks();
    FontEnum.downloadFont(showToast: false);
    if (ResponsiveUtil.isDesktop()) initHotKey();
    if (HiveUtil.getBool(HiveUtil.autoCheckUpdateKey)) fetchReleases();
    darkModeController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
      jumpToPinVerify(autoAuth: true);
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

  void checkLogin() {
    if (HiveUtil.isFirstLogin()) {
      HiveUtil.initConfig();
      HiveUtil.setFirstLogin();
    }
  }

  void jumpToPinVerify({bool autoAuth = false}) {
    if (HiveUtil.shouldAutoLock()) {
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
  }

  initHotKey() async {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.inapp,
    );
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        RouteUtil.pushDesktopFadeRoute(const SettingScreen());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: !appProvider.canPopByProvider,
      onPopInvoked: (_) {
        if (canPopByKey) {
          desktopNavigatorState?.pop();
        }
        appProvider.canPopByProvider = canPopByKey;
      },
      child: _buildBodyByPlatform(),
    );
  }

  _buildBodyByPlatform() {
    if (!ResponsiveUtil.isLandscape()) {
      return _buildMobileBody();
    } else if (ResponsiveUtil.isMobile()) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(child: _buildDesktopBody()),
      );
    } else {
      return _buildDesktopBody();
    }
  }

  _buildMobileBody() {
    return HomeScreen(key: homeScreenKey);
  }

  _buildDesktopBody() {
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [_sideBar(), _desktopMainContent()],
      ),
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
      ],
    );
  }

  _buildQrCodeContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.scanFromImageFile,
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              lockParentWindow: true,
            );
            if (result == null) return;
            File file = File(result.files.single.path!);
            Uint8List? imageBytes = file.readAsBytesSync();
            analyzeImage(imageBytes);
          },
        ),
        ContextMenuButtonConfig(
          S.current.scanFromClipboard,
          onPressed: () {
            ScreenCapturerPlatform.instance
                .readImageFromClipboard()
                .then((value) {
              if (value != null) {
                analyzeImage(value);
              } else {
                IToast.showTop(S.current.clipboardNoImage);
              }
            });
          },
        ),
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

  capture(CaptureMode mode) async {
    try {
      Directory directory = Directory(await FileUtil.getApplicationDir());
      String imageName =
          'Screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
      String imagePath = '${directory.path}\\Screenshots\\$imageName';
      CapturedData? capturedData = await screenCapturer.capture(
        mode: mode,
        copyToClipboard: false,
        imagePath: imagePath,
        silent: true,
      );
      await analyzeImage(capturedData?.imageBytes);
      File file = File(imagePath);
      if (file.existsSync()) file.delete();
    } finally {}
  }

  analyzeImage(Uint8List? imageBytes) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      IToast.showTop(S.current.noQrCode);
      return;
    }
    try {
      img.Image image = img.decodeImage(imageBytes)!;
      LuminanceSource source = RGBLuminanceSource(
          image.width,
          image.height,
          image
              .convert(numChannels: 4)
              .getBytes(order: img.ChannelOrder.abgr)
              .buffer
              .asInt32List());
      var bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
      var reader = QRCodeReader();
      var result = reader.decode(bitmap);
      if (Utils.isNotEmpty(result.text)) {
        await ImportTokenUtil.parseData([result.text]);
      } else {
        IToast.showTop(S.current.noQrCode);
      }
    } catch (e) {
      if (e.runtimeType == NotFoundException) {
        IToast.showTop(S.current.noQrCode);
      } else {
        IToast.showTop(S.current.parseQrCodeWrong);
      }
    }
  }

  _sideBar() {
    return SizedBox(
      width: 56,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
            Column(
              children: [
                const SizedBox(height: 80),
                ItemBuilder.buildIconTextButton(
                  context,
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
                ItemBuilder.buildIconTextButton(
                  context,
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
                const Spacer(),
                const SizedBox(height: 8),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: const Icon(Icons.sort_rounded, size: 22),
                  onTap: () {
                    context.contextMenuOverlay
                        .show(buildSortContextMenuButtons());
                  },
                ),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: const Icon(Icons.dashboard_outlined, size: 22),
                  onTap: () {
                    context.contextMenuOverlay
                        .show(buildLayoutContextMenuButtons());
                  },
                ),
                ItemBuilder.buildDynamicIconButton(
                    context: context,
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
                    }),
                const SizedBox(width: 6),
                ItemBuilder.buildDynamicIconButton(
                  context: context,
                  icon: AssetUtil.loadDouble(
                    context,
                    AssetUtil.settingLightIcon,
                    AssetUtil.settingDarkIcon,
                  ),
                  onTap: () async {
                    RouteUtil.pushDesktopFadeRoute(const SettingScreen());
                  },
                ),
                const SizedBox(width: 6),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: const Icon(Icons.info_outline_rounded, size: 22),
                  onTap: () async {
                    RouteUtil.pushDesktopFadeRoute(const AboutSettingScreen());
                  },
                ),
                const SizedBox(height: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _desktopMainContent() {
    return Expanded(
      child: Column(
        children: [
          WindowTitleBar(
            useMoveHandle: ResponsiveUtil.isDesktop(),
            titleBarHeightDelta: 34,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Selector<AppProvider, bool>(
                  selector: (context, globalProvider) =>
                      globalProvider.canPopByProvider,
                  builder: (context, desktopCanpop, child) => MouseRegion(
                    cursor: desktopCanpop
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: ItemBuilder.buildRoundIconButton(
                      context: context,
                      disabled: !desktopCanpop,
                      normalBackground: Colors.grey.withAlpha(40),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: desktopCanpop
                            ? Theme.of(context).iconTheme.color
                            : Colors.grey,
                      ),
                      onTap: () {
                        if (canPopByKey) {
                          desktopNavigatorState?.pop();
                        }
                        appProvider.canPopByProvider = canPopByKey;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ItemBuilder.buildRoundIconButton(
                  context: context,
                  normalBackground: Colors.grey.withAlpha(40),
                  icon: Icon(
                    Icons.home_filled,
                    size: 20,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onTap: () {
                    while (desktopNavigatorState!.canPop()) {
                      desktopNavigatorState?.pop();
                    }
                    appProvider.canPopByProvider = false;
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: min(300, MediaQuery.sizeOf(context).width - 240),
                  child: ItemBuilder.buildDesktopSearchBar(
                    context: context,
                    borderRadius: 8,
                    bottomMargin: 18,
                    hintFontSizeDelta: 1,
                    controller: searchController,
                    background: Colors.grey.withAlpha(40),
                    hintText: S.current.searchToken,
                    onSubmitted: (text) {
                      homeScreenState?.performSearch(text);
                    },
                  ),
                ),
                const Spacer(),
                if (ResponsiveUtil.isDesktop())
                  Row(
                    children: [
                      StayOnTopWindowButton(
                        rotateAngle: _isStayOnTop ? pi / 4 : 0,
                        colors: _isStayOnTop
                            ? MyColors.getStayOnTopButtonColors(context)
                            : MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(10),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(width: 3),
                      _isMaximized
                          ? RestoreWindowButton(
                              colors: MyColors.getNormalButtonColors(context),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: ResponsiveUtil.maximizeOrRestore,
                            )
                          : MaximizeWindowButton(
                              colors: MyColors.getNormalButtonColors(context),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: ResponsiveUtil.maximizeOrRestore,
                            ),
                      const SizedBox(width: 3),
                      CloseWindowButton(
                        colors: MyColors.getNormalButtonColors(context),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          if (HiveUtil.getBool(HiveUtil.enableCloseToTrayKey)) {
                            windowManager.hide();
                          } else {
                            windowManager.close();
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Navigator(
                  key: desktopNavigatorKey,
                  onGenerateRoute: (settings) {
                    return RouteUtil.getFadeRoute(
                        HomeScreen(key: homeScreenKey));
                  },
                ),
              ),
            ),
          ),
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
    if (!_hasJumpedToPinVerify) {
      _timer = Timer(
        Duration(minutes: appProvider.autoLockTime),
        () {
          jumpToPinVerify();
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
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
      windowManager.restore();
    } else if (menuItem.key == 'lock_window') {
      if (HiveUtil.canLock()) {
        _hasJumpedToPinVerify = true;
        RouteUtil.pushCupertinoRoute(
            context,
            PinVerifyScreen(
              onSuccess: () {},
              isModal: true,
              autoAuth: false,
            ), onThen: (_) {
          _hasJumpedToPinVerify = false;
        });
      } else {
        windowManager.show();
        windowManager.focus();
        windowManager.restore();
        IToast.showTop(S.current.noGestureLock);
      }
    } else if (menuItem.key == 'show_official_website') {
      UriUtil.launchUrlUri(context, officialWebsite);
    } else if (menuItem.key == 'show_github_repo') {
      UriUtil.launchUrlUri(context, repoUrl);
    } else if (menuItem.key == 'exit_app') {
      windowManager.close();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
