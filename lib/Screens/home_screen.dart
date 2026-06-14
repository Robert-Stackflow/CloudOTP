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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/layout_select_screen.dart';
import 'package:cloudotp/Screens/sort_select_screen.dart';
import 'package:cloudotp/Screens/Setting/backup_log_screen.dart';
import 'package:cloudotp/Screens/Token/category_screen.dart';
import 'package:cloudotp/Screens/main_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/search_query_parser.dart';
import 'package:cloudotp/Widgets/BottomSheet/add_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/more_bottom_sheet.dart';
import 'package:cloudotp/Widgets/cloudotp/cloudotp_item_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';

import '../Database/config_dao.dart';
import '../Database/token_dao.dart';
import '../Models/token_category.dart';
import '../TokenUtils/export_token_util.dart';
import '../TokenUtils/otp_token_parser.dart';
import '../Utils/app_provider.dart';
import '../Widgets/BottomSheet/select_category_for_tokens_bottom_sheet.dart';
import '../Widgets/BottomSheet/select_token_bottom_sheet.dart';
import '../Widgets/CoachMark/coach_mark_manager.dart';
import 'Token/add_token_screen.dart';
import '../l10n/l10n.dart';
import 'Token/token_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  static const String routeName = "/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BasePanelScreenState<HomeScreen>
    with TickerProviderStateMixin {
  LayoutType layoutType = CloudOTPHiveUtil.getLayoutType();
  OrderType orderType = CloudOTPHiveUtil.getOrderType();
  List<OtpToken> tokens = [];
  int _allTokenCount = 0;
  List<TokenCategory> categories = [];

  List<Tab> tabList = [];
  int _currentTabIndex = 0;
  String _searchKey = "";
  Map<String, GlobalKey<TokenLayoutState>> tokenKeyMap = {};
  late TabController _tabController;
  ScrollController _scrollController = ScrollController();
  final ScrollController _nestScrollController = ScrollController();
  final ScrollToHideController _fabScrollToHideController =
      ScrollToHideController();
  final ScrollToHideController _bottombarScrollToHideController =
      ScrollToHideController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _marqueeController = PageController();
  late AnimationController _animationController;
  GridItemsNotifier gridItemsNotifier = GridItemsNotifier();
  final ValueNotifier<bool> _shownSearchbarNotifier = ValueNotifier(false);

  bool _multiSelectMode = false;
  final Set<String> _selectedTokenUids = {};
  final GlobalKey _cardStackKey = GlobalKey();
  late AnimationController _pulseController;
  final List<OverlayEntry> _flyOverlays = [];

  final GlobalKey _appBarTitleKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _firstCategoryTabKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _layoutButtonKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _cloudBackupKey = GlobalKey();
  final GlobalKey _backupLogKey = GlobalKey();
  final GlobalKey desktopSearchBarKey = GlobalKey();

  bool get hasSearchFocus => appProvider.searchFocusNode.hasFocus;

  String get currentCategoryUid {
    if (_currentTabIndex == 0) {
      return "";
    } else {
      if (_currentTabIndex - 1 < 0 ||
          _currentTabIndex - 1 >= categories.length) {
        return "";
      }
      return categories[_currentTabIndex - 1].uid;
    }
  }

  bool get shouldCloseSearchBar => _shownSearchbarNotifier.value;

  List<OtpToken> get selectedTokens =>
      tokens.where((t) => _selectedTokenUids.contains(t.uid)).toList();

  bool get _allSelectedPinned =>
      selectedTokens.isNotEmpty && selectedTokens.every((t) => t.pinned);

  void enterMultiSelectMode(String tokenUid) {
    Offset? sourcePos;
    Size? sourceSize;
    CapturedThemes? capturedThemes;
    OtpToken? token;

    final key = tokenKeyMap[tokenUid];
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox;
      sourcePos = box.localToGlobal(Offset.zero);
      sourceSize = box.size;
      final overlayState = Overlay.of(context);
      capturedThemes = InheritedTheme.capture(
        from: key.currentContext!,
        to: overlayState.context,
      );
      token = tokens.firstWhere((t) => t.uid == tokenUid);
    }

    for (final key in tokenKeyMap.values) {
      key.currentState?.closeSlidable();
    }
    setState(() {
      _multiSelectMode = true;
      _selectedTokenUids.clear();
      _selectedTokenUids.add(tokenUid);
    });

    if (sourcePos != null && sourceSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateFlyToCardStack(
          sourcePos: sourcePos!,
          sourceSize: sourceSize!,
          capturedThemes: capturedThemes,
          token: token,
        );
      });
    }
  }

  void exitMultiSelectMode() {
    for (final entry in _flyOverlays) {
      entry.remove();
    }
    _flyOverlays.clear();
    setState(() {
      _multiSelectMode = false;
      _selectedTokenUids.clear();
    });
  }

  void toggleTokenSelection(String tokenUid) {
    final isAdding = !_selectedTokenUids.contains(tokenUid);

    Offset? sourcePos;
    Size? sourceSize;
    CapturedThemes? capturedThemes;
    OtpToken? token;

    if (isAdding) {
      final key = tokenKeyMap[tokenUid];
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        sourcePos = box.localToGlobal(Offset.zero);
        sourceSize = box.size;
        final overlayState = Overlay.of(context);
        capturedThemes = InheritedTheme.capture(
          from: key.currentContext!,
          to: overlayState.context,
        );
        token = tokens.firstWhere((t) => t.uid == tokenUid);
      }
    }

    setState(() {
      if (isAdding) {
        _selectedTokenUids.add(tokenUid);
      } else {
        _selectedTokenUids.remove(tokenUid);
        if (_selectedTokenUids.isEmpty) {
          _multiSelectMode = false;
        }
      }
    });

    if (isAdding && sourcePos != null && sourceSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateFlyToCardStack(
          sourcePos: sourcePos!,
          sourceSize: sourceSize!,
          capturedThemes: capturedThemes,
          token: token,
        );
      });
    }
  }

  void selectAllTokens() {
    setState(() {
      if (_selectedTokenUids.length == tokens.length) {
        _selectedTokenUids.clear();
      } else {
        _selectedTokenUids.addAll(tokens.map((t) => t.uid));
      }
    });
  }

  void _processMultiDelete() {
    List<OtpToken> selected = selectedTokens;
    if (selected.isEmpty) return;
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.batchDeleteTitle,
      message: appLocalizations.batchDeleteMessage(selected.length),
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () async {
        await TokenDao.deleteTokens(selected);
        IToast.showTop(appLocalizations.batchDeleteSuccess(selected.length));
        exitMultiSelectMode();
        getTokens();
      },
      onTapCancel: () {},
    );
  }

  void _processMultiMoveCategory() {
    List<OtpToken> selected = selectedTokens;
    if (selected.isEmpty) return;
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => SelectCategoryForTokensBottomSheet(
        tokens: selected,
        onCompleted: () {
          exitMultiSelectMode();
          getTokens();
        },
      ),
    );
  }

  void _processMultiExport() {
    List<OtpToken> selected = selectedTokens;
    if (selected.isEmpty) return;
    BottomSheetBuilder.showContextMenu(
      context,
      FlutterContextMenu(
        entries: [
          FlutterContextMenuItem(
            appLocalizations.exportUriFile,
            iconData: LucideIcons.fileOutput,
            onPressed: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.exportUriClearWarningTitle,
                message: appLocalizations.exportUriClearWarningTip,
                onTapConfirm: () async {
                  if (ResponsiveUtil.isDesktop()) {
                    String? result = await FileUtil.saveFile(
                      dialogTitle: appLocalizations.exportUriFileTitle,
                      fileName: ExportTokenUtil.getExportFileName("txt"),
                      type: FileType.custom,
                      allowedExtensions: ['txt'],
                      lockParentWindow: true,
                    );
                    if (result != null) {
                      _exportSelectedTokensUriToFile(selected, result);
                    }
                  } else {
                    _exportSelectedTokensUriToMobile(selected);
                  }
                },
                onTapCancel: () {},
              );
            },
          ),
          FlutterContextMenuItem(
            appLocalizations.exportEncryptFile,
            iconData: LucideIcons.fileLock2,
            onPressed: () => _exportSelectedEncrypted(selected),
          ),
          FlutterContextMenuItem(
            appLocalizations.exportQrcode,
            iconData: LucideIcons.qrCode,
            onPressed: () async {
              List<String>? qrcodes = await ExportTokenUtil.exportToQrcodes(
                selectedTokens: selected,
              );
              if (qrcodes != null && qrcodes.isNotEmpty && mounted) {
                CloudOTPItemBuilder.showQrcodesDialog(
                  context,
                  title: appLocalizations.multiSelectCount(selected.length),
                  qrcodes: qrcodes,
                );
              }
            },
          ),
          FlutterContextMenuItem(
            appLocalizations.exportGoogleAuthenticatorQrcode,
            iconData: LucideIcons.qrCode,
            onPressed: () async {
              List<dynamic>? result =
                  await ExportTokenUtil.exportToGoogleAuthentcatorQrcodes(
                selectedTokens: selected,
              );
              if (result != null && mounted) {
                List<String> qrcodes = result[0] as List<String>;
                int passCount = result[1] as int;
                if (qrcodes.isNotEmpty) {
                  CloudOTPItemBuilder.showQrcodesDialog(
                    context,
                    title: appLocalizations.multiSelectCount(selected.length),
                    qrcodes: qrcodes,
                  );
                }
                if (passCount > 0) {
                  IToast.showTop(appLocalizations
                      .exportGoogleAuthenticatorNoCompatibleCount(passCount));
                }
              }
            },
          ),
          FlutterContextMenuItem(
            appLocalizations.shareTokenUri,
            iconData: LucideIcons.share2,
            onPressed: () {
              ExportTokenUtil.shareSelectedTokensUri(selected);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportSelectedEncrypted(List<OtpToken> selected) async {
    if (await CloudOTPHiveUtil.canImportOrExportUseBackupPassword()) {
      _doExportSelectedEncrypted(selected, await ConfigDao.getBackupPassword());
    } else {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => InputBottomSheet(
          title: appLocalizations.setExportPasswordTitle,
          message: appLocalizations.setExportPasswordTip,
          hint: appLocalizations.setExportPasswordHint,
          tailingConfig: InputItemLeadingTailingConfig(
            type: InputItemLeadingTailingType.password,
          ),
          inputFormatters: [
            RegexInputFormatter.onlyNumberAndLetterAndSymbol,
          ],
          validator: (value) {
            if (value.isEmpty) {
              return appLocalizations.encryptDatabasePasswordCannotBeEmpty;
            }
            return null;
          },
          onValidConfirm: (password) async {
            _doExportSelectedEncrypted(selected, password);
            return null;
          },
        ),
      );
    }
  }

  Future<void> _doExportSelectedEncrypted(
      List<OtpToken> selected, String password) async {
    if (ResponsiveUtil.isDesktop()) {
      String? result = await FileUtil.saveFile(
        dialogTitle: appLocalizations.exportEncryptFileTitle,
        fileName: ExportTokenUtil.getExportFileName("bin"),
        type: FileType.custom,
        allowedExtensions: ['bin'],
        lockParentWindow: true,
      );
      if (result != null) {
        final data = await ExportTokenUtil.getUint8ListForTokens(
            tokens: selected, password: password);
        if (data != null) {
          ExportTokenUtil.exportEncryptFile(result, password,
              encryptedData: data);
        }
      }
    } else {
      final data = await ExportTokenUtil.getUint8ListForTokens(
          tokens: selected, password: password);
      if (data != null) {
        ExportTokenUtil.exportEncryptToMobileDirectory(
            encryptedData: data, password: password);
      }
    }
  }

  Future<void> _exportSelectedTokensUriToFile(
      List<OtpToken> tokens, String filePath) async {
    CustomLoadingDialog.showLoading(title: appLocalizations.exporting);
    await compute((_) async {
      List<String> uris =
          tokens.map((e) => OtpTokenParser.toUri(e).toString()).toList();
      String content = uris.join("\n");
      File(filePath).writeAsStringSync(content);
    }, null);
    CustomLoadingDialog.dismissLoading();
    IToast.showTop(appLocalizations.exportSuccess);
  }

  Future<void> _exportSelectedTokensUriToMobile(List<OtpToken> tokens) async {
    CustomLoadingDialog.showLoading(title: appLocalizations.exporting);
    Uint8List res = await compute((_) async {
      List<String> uris =
          tokens.map((e) => OtpTokenParser.toUri(e).toString()).toList();
      String content = uris.join("\n");
      return utf8.encode(content);
    }, null);
    String? filePath = await FileUtil.saveFile(
      dialogTitle: appLocalizations.exportUriFileTitle,
      fileName: ExportTokenUtil.getExportFileName("txt"),
      type: FileType.custom,
      allowedExtensions: ['txt'],
      bytes: res,
    );
    CustomLoadingDialog.dismissLoading();
    if (filePath != null) {
      IToast.showTop(appLocalizations.exportSuccess);
    }
  }

  Future<void> _processMultiPin() async {
    List<OtpToken> selected = selectedTokens;
    if (selected.isEmpty) return;
    bool pinAll = !_allSelectedPinned;
    for (OtpToken token in selected) {
      await TokenDao.updateTokenPinned(token, pinAll);
    }
    IToast.showTop(pinAll
        ? appLocalizations.alreadyPinnedSelectedTokens(selected.length)
        : appLocalizations.alreadyUnPinnedSelectedTokens(selected.length));
    exitMultiSelectMode();
    getTokens();
  }

  Widget _buildMultiSelectDockContent() {
    return Center(
      key: const ValueKey('dock'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: ChewieTheme.appBarBackgroundColor.withAlpha(230),
          borderRadius: BorderRadius.circular(12),
          border: ChewieTheme.border,
          boxShadow: ChewieTheme.defaultBoxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardStack(),
            _buildDockDivider(),
            _buildDockItem(
              icon: LucideIcons.x,
              label: appLocalizations.cancel,
              onTap: exitMultiSelectMode,
            ),
            _buildDockDivider(),
            _buildDockItem(
              icon: _selectedTokenUids.length == tokens.length
                  ? Icons.deselect
                  : LucideIcons.checkCheck,
              label: _selectedTokenUids.length == tokens.length
                  ? appLocalizations.deselectAll
                  : appLocalizations.selectAll,
              onTap: selectAllTokens,
            ),
            _buildDockDivider(),
            _buildDockItem(
              icon: LucideIcons.shapes,
              label: appLocalizations.category,
              onTap:
                  _selectedTokenUids.isEmpty ? null : _processMultiMoveCategory,
            ),
            _buildDockItem(
              icon: _allSelectedPinned ? LucideIcons.pinOff : LucideIcons.pin,
              label: _allSelectedPinned
                  ? appLocalizations.unPinTokenShort
                  : appLocalizations.pinTokenShort,
              onTap: _selectedTokenUids.isEmpty ? null : _processMultiPin,
            ),
            _buildDockItem(
              icon: LucideIcons.fileOutput,
              label: appLocalizations.export,
              onTap: _selectedTokenUids.isEmpty ? null : _processMultiExport,
            ),
            _buildDockItem(
              icon: LucideIcons.trash2,
              label: appLocalizations.delete,
              onTap: _selectedTokenUids.isEmpty ? null : _processMultiDelete,
              color: _selectedTokenUids.isEmpty ? Colors.grey : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDock() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _multiSelectMode
            ? _buildMultiSelectDockContent()
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    int? badge,
  }) {
    final enabled = onTap != null;
    Widget iconWidget = Icon(
      icon,
      color: enabled
          ? (color ?? ChewieTheme.iconColor)
          : Colors.grey.withAlpha(100),
      size: 20,
    );
    if (badge != null && badge > 0) {
      iconWidget = Badge(
        label: Text(
          '$badge',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: ChewieTheme.primaryColor,
        child: iconWidget,
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ToolTipWrapper(
        message: label,
        position: TooltipPosition.top,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: iconWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.withAlpha(60),
    );
  }

  Widget _buildStackCard({
    required double rotation,
    required Offset offset,
    required int alpha,
    bool isFront = false,
  }) {
    final primary = ChewieTheme.primaryColor;
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 26,
          height: 18,
          decoration: BoxDecoration(
            color: ChewieTheme.cardColor.withAlpha(alpha),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isFront
                  ? primary.withAlpha(120)
                  : Colors.grey.withAlpha(60 + alpha ~/ 4),
              width: isFront ? 1.0 : 0.5,
            ),
            boxShadow: isFront
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: isFront
              ? Column(
                  children: [
                    Container(
                      height: 4,
                      margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(180),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.fromLTRB(3, 2, 8, 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(60),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Badge(
          label: Text(
            '${_selectedTokenUids.length}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: ChewieTheme.primaryColor,
          child: SizedBox(
            key: _cardStackKey,
            width: 38,
            height: 30,
            child: Center(
              child: SizedBox(
                width: 34,
                height: 26,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: _buildStackCard(
                        rotation: -0.15,
                        offset: const Offset(-2, 0),
                        alpha: 120,
                      ),
                    ),
                    Positioned.fill(
                      child: _buildStackCard(
                        rotation: 0.08,
                        offset: const Offset(2, -1),
                        alpha: 180,
                      ),
                    ),
                    Positioned.fill(
                      child: _buildStackCard(
                        rotation: 0,
                        offset: const Offset(0, 0),
                        alpha: 255,
                        isFront: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _animateFlyToCardStack({
    required Offset sourcePos,
    required Size sourceSize,
    CapturedThemes? capturedThemes,
    OtpToken? token,
  }) {
    final stackContext = _cardStackKey.currentContext;
    if (stackContext == null) return;

    final targetBox = stackContext.findRenderObject() as RenderBox;
    final targetPos = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    Widget flyChild;
    if (token != null && capturedThemes != null) {
      flyChild = capturedThemes.wrap(
        TokenLayout(
          token: token,
          layoutType: layoutType,
        ),
      );
    } else {
      flyChild = Container(
        decoration: BoxDecoration(
          color: ChewieTheme.canvasColor,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final t = curved.value;
          final left = ui.lerpDouble(sourcePos.dx, targetPos.dx, t)!;
          final top = ui.lerpDouble(sourcePos.dy, targetPos.dy, t)!;
          final width = ui.lerpDouble(sourceSize.width, targetSize.width, t)!;
          final height =
              ui.lerpDouble(sourceSize.height, targetSize.height, t)!;
          final opacity = ui.lerpDouble(1.0, 0.3, t)!;

          return Positioned(
            left: left,
            top: top,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: sourceSize.width,
                      height: sourceSize.height,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: flyChild,
      ),
    );

    Overlay.of(context).insert(entry);
    _flyOverlays.add(entry);

    controller.forward().then((_) {
      entry.remove();
      _flyOverlays.remove(entry);
      controller.dispose();
      if (mounted) {
        _pulseController.forward(from: 0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (DatabaseManager.isNewDatabase) {
      DatabaseManager.updateSampleCategoryTitle(
          appLocalizations.sampleCategoryName);
    }
    initTab(true);
    refresh(true).then((_) {
      if (ResponsiveUtil.isMobile() &&
          !ResponsiveUtil.isLandscapeTablet() &&
          !ChewieHiveUtil.getBool(CloudOTPHiveUtil.haveShownCoachMarkKey,
              defaultValue: false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCoachMarkInternal(force: true);
        });
      }
    });
    _searchController.addListener(() {
      performSearch(_searchController.text);
    });
    _animationController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!ResponsiveUtil.isLandscapeLayout() &&
          ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoFocusSearchBarKey,
              defaultValue: false)) {
        changeSearchBar(true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    for (final entry in _flyOverlays) {
      entry.remove();
    }
    _flyOverlays.clear();
    super.dispose();
  }

  insertToken(
    OtpToken token, {
    bool forceAll = false,
  }) async {
    if (tokens.any((element) => element.uid == token.uid)) return;
    if (currentCategoryUid.isEmpty) {
      if (!forceAll) {
        return;
      }
    } else {
      if (!(await BindingDao.getCategoryUids(token.uid))
          .contains(currentCategoryUid)) {
        return;
      }
    }
    int calculateInsertIndex = 0;
    switch (orderType) {
      case OrderType.Default:
        calculateInsertIndex = 0;
        break;
      case OrderType.AlphabeticalASC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.issuer.compareTo(token.issuer) > 0);
        break;
      case OrderType.AlphabeticalDESC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.issuer.compareTo(token.issuer) < 0);
        break;
      case OrderType.CopyTimesDESC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.copyTimes.compareTo(token.copyTimes) < 0);
        break;
      case OrderType.CopyTimesASC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.copyTimes.compareTo(token.copyTimes) > 0);
        break;
      case OrderType.LastCopyTimeDESC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.lastCopyTimeStamp.compareTo(token.lastCopyTimeStamp) < 0);
        break;
      case OrderType.LastCopyTimeASC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.lastCopyTimeStamp.compareTo(token.lastCopyTimeStamp) > 0);
        break;
      case OrderType.CreateTimeDESC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.createTimeStamp.compareTo(token.createTimeStamp) < 0);
        break;
      case OrderType.CreateTimeASC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.createTimeStamp.compareTo(token.createTimeStamp) > 0);
        break;
    }
    int pinnedCount = tokens.where((e) => e.pinned).toList().length;
    calculateInsertIndex += pinnedCount;
    calculateInsertIndex = calculateInsertIndex.clamp(0, tokens.length);
    tokens.insert(calculateInsertIndex, token);
    gridItemsNotifier.notifyItemInserted?.call(calculateInsertIndex, () {
      setState(() {});
    });
  }

  updateToken(
    OtpToken token, {
    bool pinnedStateChanged = false,
    bool counterChanged = false,
  }) {
    int updateIndex = tokens.indexWhere((element) => element.uid == token.uid);
    tokens[updateIndex] = token;
    tokenKeyMap
        .putIfAbsent(token.uid, () => GlobalKey())
        .currentState
        ?.updateInfo(counterChanged: counterChanged);
    if (pinnedStateChanged) performSort();
  }

  removeToken(OtpToken token) {
    int removeIndex = tokens.indexWhere((element) => element.uid == token.uid);
    if (removeIndex != -1) tokens.removeAt(removeIndex);
    gridItemsNotifier.notifyItemRemoved?.call(removeIndex, () {
      setState(() {});
    });
  }

  changeCategoriesForToken(OtpToken token, List<String> unselectedCategoryUids,
      List<String> selectedCategorUids) {
    if (unselectedCategoryUids.contains(currentCategoryUid)) {
      removeToken(token);
    }
    if (selectedCategorUids.contains(currentCategoryUid)) {
      insertToken(token);
    }
  }

  changeTokensForCategory(TokenCategory category) {
    if (category.uid == currentCategoryUid && currentCategoryUid.isNotEmpty) {
      getTokens();
    }
  }

  refreshCategories() async {
    await getCategories();
  }

  refresh([bool isInit = false]) async {
    if (!mounted) return;
    await getCategories(isInit);
    await getTokens();
  }

  getTokens() async {
    final query = SearchQueryParser.parse(_searchKey);

    Set<String>? categoryTokenUids;
    if (query.categoryName != null) {
      final catUids =
          await CategoryDao.getCategoryUidsByName(query.categoryName!);
      categoryTokenUids = await BindingDao.getTokenUidsByCategoryUids(catUids);
    }

    await CategoryDao.getTokensByCategoryUid(
      currentCategoryUid,
      searchKey: query.text,
      tags: query.tags,
      tokenType: query.tokenType,
    ).then((value) {
      final seen = <String>{};
      tokens = value.where((t) {
        if (!seen.add(t.uid)) return false;
        if (categoryTokenUids != null && !categoryTokenUids.contains(t.uid))
          return false;
        return true;
      }).toList();
      final currentUids = seen;
      tokenKeyMap.removeWhere((uid, _) => !currentUids.contains(uid));
      performSort();
    });

    if (currentCategoryUid.isEmpty && _searchKey.isEmpty) {
      _allTokenCount = tokens.length;
    } else {
      final allTokens = await TokenDao.listTokens();
      _allTokenCount = allTokens.length;
    }
  }

  void showCoachMark() {
    _showCoachMarkInternal(force: true);
  }

  void _showCoachMarkInternal({required bool force}) {
    final provider = context.read<AppProvider>();
    CoachMarkManager(
      context: context,
      appBarTitleKey: _appBarTitleKey,
      firstTokenKey: tokenKeyMap.isNotEmpty ? tokenKeyMap.values.first : null,
      categoryTabKey: categories.isNotEmpty ? _firstCategoryTabKey : null,
      moreButtonKey: _moreButtonKey,
      sortButtonKey: provider.showSortButton ? _sortButtonKey : null,
      layoutButtonKey: provider.showLayoutButton ? _layoutButtonKey : null,
      fabKey: _fabKey,
      cloudBackupKey: provider.showCloudBackupButton ? _cloudBackupKey : null,
      backupLogKey: provider.showBackupLogButton ? _backupLogKey : null,
      layoutType: layoutType,
      tokenCount: tokens.length,
      categoryCount: categories.length,
      onDeleteSampleData: () => refresh(true),
    ).show(force: force);
  }

  getCategories([bool isInit = false]) async {
    String oldUid = currentCategoryUid;
    await CategoryDao.listCategories().then((value) async {
      categories = value;
      List<String> uids = categories.map((e) => e.uid).toList();
      if (!uids.contains(oldUid)) {
        _currentTabIndex = 0;
        await getTokens();
      } else {
        _currentTabIndex = uids.indexOf(oldUid) + 1;
      }
      initTab(isInit);
      setState(() {});
    });
  }

  initTab([bool isInit = false]) {
    tabList.clear();
    tabList.add(_buildTab(null));
    String categoryUid = CloudOTPHiveUtil.getSelectedCategoryId();
    for (var category in categories) {
      tabList.add(_buildTab(category));
      if (category.uid == categoryUid && isInit) {
        _currentTabIndex = categories.indexOf(category) + 1;
      }
    }
    setState(() {});
    _tabController = TabController(length: tabList.length, vsync: this);
    _tabController.index = _currentTabIndex;
  }

  @override
  void onLocaleChanged(Locale newLocale) {
    super.onLocaleChanged(newLocale);
    initTab();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      appBar: ResponsiveUtil.selectByOrientationNullable(
        landscape: ResponsiveUtil.isMacOS()
            ? null
            : ResponsiveAppBar(
                titleLeftMargin: 10,
                titleWidget: Container(
                  key: desktopSearchBarKey,
                  constraints: const BoxConstraints(
                      maxWidth: 300, minWidth: 200, maxHeight: 36),
                  child: MySearchBar(
                    borderRadius: 8,
                    bottomMargin: 18,
                    focusNode: appProvider.searchFocusNode,
                    controller: _searchController,
                    background: ChewieTheme.scaffoldBackgroundColor,
                    hintText: appLocalizations.searchToken,
                    onSubmitted: (text) {
                      performSearch(text);
                    },
                  ),
                ),
              ),
        portrait: null,
      ) as PreferredSizeWidget?,
      body: ResponsiveUtil.selectByOrientation(
        landscape: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
            _buildAnimatedDock(),
          ],
        ),
        portrait: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) {
            if (_multiSelectMode) {
              exitMultiSelectMode();
            } else if (mounted && _shownSearchbarNotifier.value) {
              changeSearchBar(false);
            } else {
              MoveToBackground.moveTaskToBack();
            }
          },
          child: Stack(
            children: [
              _buildMobileBody(),
              _buildAnimatedDock(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ResponsiveUtil.selectByPlatform(
        mobile: _buildMobileBottombar(),
      ),
      floatingActionButton: _multiSelectMode
          ? null
          : ResponsiveUtil.selectByPlatform(
              mobile: _buildFloatingActionButton(),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      extendBody: true,
    );
  }

  _buildMobileBody() {
    return NestedScrollView(
      controller: _nestScrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [_buildMobileAppbar()];
      },
      body: Builder(
        builder: (context) {
          _scrollController = PrimaryScrollController.of(context);
          return _buildMainContent();
        },
      ),
    );
  }

  changeSearchBar(bool shown) {
    Future.delayed(const Duration(milliseconds: 200), () {
      _shownSearchbarNotifier.value = shown;
    });
    _marqueeController.animateToPage(shown ? 1 : 0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    if (shown) {
      appProvider.searchFocusNode.requestFocus();
      _animationController.reverse();
    } else {
      _searchController.clear();
      appProvider.searchFocusNode.unfocus();
      _animationController.forward();
    }
  }

  _buildFloatingActionButton() {
    var button = MyFloatingActionButton(
      key: _fabKey,
      heroTag: "Hero-${categories.length}",
      onPressed: () {
        BottomSheetBuilder.showBottomSheet(
          context,
          enableDrag: true,
          responsive: true,
          (context) => AddBottomSheet(
            onlyShowScanner: ResponsiveUtil.isLandscapeTablet(),
          ),
        );
      },
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: ChewieTheme.primaryColor,
      child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 28),
    );
    return Selector<AppProvider, bool>(
      selector: (context, provider) => provider.hideBottombarWhenScrolling,
      builder: (context, hideBottombarWhenScrolling, child) => ScrollToHide(
        enabled: hideBottombarWhenScrolling || categories.isEmpty,
        scrollController: _scrollController,
        controller: _fabScrollToHideController,
        height: kToolbarHeight,
        duration: const Duration(milliseconds: 300),
        hideDirection: Axis.vertical,
        child: button,
      ),
    );
  }

  getActions(AppProvider provider) {
    return [
      if (provider.showCloudBackupButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: ToolButton(
            key: _cloudBackupKey,
            context: context,
            tooltip: appLocalizations.cloudBackupServiceSetting,
            tooltipPosition: TooltipPosition.bottom,
            icon: LucideIcons.cloud,
            onPressed: () {
              RouteUtil.pushCupertinoRoute(context, const CloudServiceScreen());
            },
          ),
        ),
      if (provider.showBackupLogButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: Selector<AppProvider, LoadingStatus>(
            selector: (context, appProvider) =>
                appProvider.autoBackupLoadingStatus,
            builder: (context, autoBackupLoadingStatus, child) => ToolButton(
              key: _backupLogKey,
              context: context,
              tooltip: appLocalizations.backupLogs,
              tooltipPosition: TooltipPosition.bottom,
              iconBuilder: (buttonContext) => LoadingIcon(
                status: autoBackupLoadingStatus,
                normalIcon:
                    Icon(Icons.history_rounded, color: buttonContext.iconColor),
              ),
              onPressed: () {
                BackupLogScreen.show(context);
              },
            ),
          ),
        ),
      if (provider.showLayoutButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: ToolButton(
            key: _layoutButtonKey,
            context: context,
            tooltip: appLocalizations.layoutType,
            tooltipPosition: TooltipPosition.bottom,
            icon: layoutType.icon,
            onPressed: () {
              LayoutSelectScreen.show(context);
            },
          ),
        ),
      if (provider.showSortButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: ToolButton(
            key: _sortButtonKey,
            context: context,
            tooltip: appLocalizations.sortType,
            tooltipPosition: TooltipPosition.bottom,
            icon: orderType.icon,
            onPressed: () {
              SortSelectScreen.show(context);
            },
          ),
        ),
      ToolButton(
        key: _moreButtonKey,
        context: context,
        tooltip: appLocalizations.more,
        tooltipPosition: TooltipPosition.bottom,
        icon: LucideIcons.ellipsisVertical,
        onPressed: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            responsive: true,
            (ctx) => MoreBottomSheet(
              showSelect: tokens.length > 1,
              onSelect: () => enterMultiSelectMode(tokens.first.uid),
            ),
          );
        },
      ),
      const SizedBox(width: 5),
    ];
  }

  _buildMobileAppbar() {
    if (_multiSelectMode) {
      return SliverAppBar(
        floating: true,
        pinned: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        backgroundColor: ChewieTheme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: ChewieTheme.iconColor),
          onPressed: exitMultiSelectMode,
        ),
        title: Text(
          appLocalizations.multiSelectCount(_selectedTokenUids.length),
          style: ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
        ),
      );
    }
    return Consumer<AppProvider>(
      builder: (context, provider, child) => ValueListenableBuilder(
        valueListenable: _shownSearchbarNotifier,
        builder: (context, shownSearchbar, child) =>
            CloudOTPItemBuilder.buildSliverAppBar(
          context: context,
          useBackdropFilter: provider.enableFrostedGlassEffect,
          floating: provider.hideAppbarWhenScrolling,
          pinned: !provider.hideAppbarWhenScrolling,
          backgroundColor: ChewieTheme.scaffoldBackgroundColor
              .withOpacity(provider.enableFrostedGlassEffect ? 0.2 : 1),
          title: SizedBox(
            height: kToolbarHeight,
            child: MarqueeWidget(
              count: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      key: _appBarTitleKey,
                      onTap: () {
                        if (!_shownSearchbarNotifier.value) {
                          changeSearchBar(true);
                        }
                      },
                      child: Text(
                        ResponsiveUtil.appName,
                        style:
                            ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
                      ),
                    ),
                  );
                } else {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleIconButton(
                            tooltip: appLocalizations.cancel,
                            icon: Icon(
                              LucideIcons.arrowLeft,
                              color: ChewieTheme.iconColor,
                            ),
                            onTap: () {
                              changeSearchBar(false);
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InputItem(
                              hint: appLocalizations.searchToken,
                              onSubmit: (text) {
                                performSearch(text);
                              },
                              style: InputItemStyle(
                                backgroundColor: Colors.transparent,
                                bottomMargin: 0,
                                topMargin: 0,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              focusNode: appProvider.searchFocusNode,
                              controller: _searchController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              autoPlay: false,
              controller: _marqueeController,
            ),
          ),
          expandedHeight: kToolbarHeight,
          collapsedHeight: kToolbarHeight,
          actions: _shownSearchbarNotifier.value ? [] : getActions(provider),
        ),
      ),
    );
  }

  _buildMobileBottombar({double verticalPadding = 10}) {
    if (_multiSelectMode) {
      return const SizedBox.shrink();
    }
    double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    double height = kToolbarHeight +
        verticalPadding * 2 +
        bottomInset +
        (ResponsiveUtil.isLandscapeTablet() ? 24 : 0);
    return Selector<AppProvider, bool>(
      selector: (context, provider) => provider.hideBottombarWhenScrolling,
      builder: (context, hideBottombarWhenScrolling, child) =>
          Selector<AppProvider, bool>(
        selector: (context, provider) => provider.enableFrostedGlassEffect,
        builder: (context, enableFrostedGlassEffect, child) {
          var container = Container(
            alignment: Alignment.centerLeft,
            height: height,
            decoration: BoxDecoration(
              color: ChewieTheme.scaffoldBackgroundColor
                  .withOpacity(enableFrostedGlassEffect ? 0.2 : 1),
              boxShadow: [
                BoxShadow(
                  color: ChewieTheme.shadowColor,
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
              // border: ChewieTheme.topDivider,
            ),
            padding: EdgeInsets.symmetric(vertical: 5 + verticalPadding)
                .copyWith(right: 70, bottom: 5 + verticalPadding + bottomInset),
            child: _buildTabBar(const EdgeInsets.only(left: 10, right: 10)),
          );
          return ScrollToHide(
            enabled: hideBottombarWhenScrolling,
            scrollController: _scrollController,
            controller: _bottombarScrollToHideController,
            height: height,
            duration: const Duration(milliseconds: 300),
            hideDirection: Axis.vertical,
            child: ResponsiveUtil.isLandscapeTablet() || categories.isEmpty
                ? IgnorePointer(
                    child: Container(
                      height: height,
                      decoration: const BoxDecoration(color: Color(0x00ffffff)),
                    ),
                  )
                : enableFrostedGlassEffect
                    ? ClipRRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: container,
                        ),
                      )
                    : container,
          );
        },
      ),
    );
  }

  _buildMainContent() {
    Widget gridView = Selector<AppProvider,
        ({bool dragToReorder, bool hideBottombar, bool hideProgress})>(
      selector: (context, provider) => (
        dragToReorder: provider.dragToReorder,
        hideBottombar: provider.hideBottombarWhenScrolling,
        hideProgress: provider.hideProgressBar,
      ),
      builder: (context, settings, child) {
        double bottomPadding = MediaQuery.of(context).padding.bottom;
        return ReorderableGridView.builder(
          cacheExtent: 999,
          // controller: _scrollController,
          gridItemsNotifier: gridItemsNotifier,
          autoScroll: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 10,
              bottom: _multiSelectMode
                  ? 88 + bottomPadding
                  : settings.hideBottombar || categories.isEmpty
                      ? 10 + bottomPadding
                      : 85 + bottomPadding),
          gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: layoutType.maxCrossAxisExtent,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            preferredHeight: layoutType.getHeight(settings.hideProgress),
          ),
          dragToReorder: _multiSelectMode ? false : settings.dragToReorder,
          onReorderStart: (_) {
            _fabScrollToHideController.hide();
            _bottombarScrollToHideController.hide();
          },
          onReorderEnd: (_, __) {
            _fabScrollToHideController.show();
            _bottombarScrollToHideController.show();
          },
          onReorder: (int oldIndex, int newIndex) async {
            final selectedToken = tokens[oldIndex];
            int pinnedCount = tokens.where((e) => e.pinned).length;
            if (selectedToken.pinned) {
              if (newIndex >= pinnedCount) newIndex = pinnedCount - 1;
            } else {
              if (newIndex < pinnedCount) newIndex = pinnedCount;
            }
            final item = tokens.removeAt(oldIndex);
            tokens.insert(newIndex, item);
            // `tokens` may be a filtered subset (a category tab or active
            // search), but `seq` is a single global field. Rebuild the full
            // global order so it stays consistent with this reorder: move the
            // dragged token next to its new visible neighbour in the complete
            // list, then renumber every token's seq. Non-visible tokens keep
            // their relative order, and the global "all" view matches what the
            // user sees here. Renumbering also heals any legacy seq collisions.
            final all = await TokenDao.listTokens();
            all.removeWhere((t) => t.uid == item.uid);
            int anchorPos;
            if (newIndex > 0) {
              // place right below the visible token now above the dragged one
              final prevUid = tokens[newIndex - 1].uid;
              anchorPos = all.indexWhere((t) => t.uid == prevUid) + 1;
            } else if (tokens.length > 1) {
              // dropped at the very top: place right above the token now below
              final nextUid = tokens[newIndex + 1].uid;
              anchorPos = all.indexWhere((t) => t.uid == nextUid);
            } else {
              anchorPos = 0;
            }
            if (anchorPos < 0) anchorPos = 0;
            all.insert(anchorPos, item);
            for (int i = 0; i < all.length; i++) {
              all[i].seq = all.length - i;
            }
            // Keep the in-memory visible tokens' seq in sync with the DB so a
            // later performSort (e.g. on pin toggle) stays correct.
            final seqByUid = {for (final t in all) t.uid: t.seq};
            for (final t in tokens) {
              t.seq = seqByUid[t.uid] ?? t.seq;
            }
            await TokenDao.updateTokens(all, autoBackup: false);
            changeOrderType(type: OrderType.Default, doPerformSort: false);
          },
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ChewieTheme.shadowColor,
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ).scale(2)
                ],
              ),
              child: child,
            );
          },
          itemCount: tokens.length,
          itemBuilder: (context, index) {
            return TokenLayout(
              key:
                  tokenKeyMap.putIfAbsent(tokens[index].uid, () => GlobalKey()),
              token: tokens[index],
              layoutType: layoutType,
              multiSelectMode: _multiSelectMode,
              isSelected: _selectedTokenUids.contains(tokens[index].uid),
              onToggleSelect: () => toggleTokenSelection(tokens[index].uid),
              onEnterMultiSelect: () => enterMultiSelectMode(tokens[index].uid),
            );
          },
        );
      },
    );
    Widget body = tokens.isEmpty ? _buildEmptyPlaceholder() : gridView;
    return SlidableAutoCloseBehavior(child: body);
  }

  Widget _buildEmptyPlaceholder() {
    if (_searchKey.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 50),
        children: [
          EmptyPlaceholder(
            text: appLocalizations.noTokenContainingSearchKey(_searchKey),
          ),
        ],
      );
    }

    final inCategory = currentCategoryUid.isNotEmpty;
    final hasGlobalTokens = _allTokenCount > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ChewieTheme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.inbox,
                size: 26,
                color: ChewieTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              inCategory
                  ? appLocalizations.noTokenInCategory
                  : appLocalizations.noToken,
              style: ChewieTheme.bodyMedium.copyWith(
                color: ChewieTheme.bodyMedium.color?.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inCategory && hasGlobalTokens) ...[
                  RoundIconButton(
                    icon: Icon(
                      LucideIcons.listPlus,
                      size: 18,
                      color: ChewieTheme.primaryColor,
                    ),
                    background: ChewieTheme.primaryColor.withAlpha(20),
                    padding: const EdgeInsets.all(10),
                    onPressed: () {
                      final category = categories[_currentTabIndex - 1];
                      BottomSheetBuilder.showBottomSheet(
                        context,
                        responsive: true,
                        (context) => SelectTokenBottomSheet(category: category),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                RoundIconTextButton(
                  height: 38,
                  text: appLocalizations.addToken,
                  background: ChewieTheme.primaryColor,
                  onPressed: () {
                    if (ResponsiveUtil.isMobile()) {
                      BottomSheetBuilder.showBottomSheet(
                        context,
                        enableDrag: true,
                        responsive: true,
                        (context) => AddBottomSheet(
                          onlyShowScanner: ResponsiveUtil.isLandscapeTablet(),
                        ),
                      );
                    } else {
                      DialogBuilder.showPageDialog(context,
                          child: const AddTokenScreen());
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  _buildTabBar([EdgeInsetsGeometry? padding]) {
    return TabBar(
      controller: _tabController,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: tabList,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      isScrollable: true,
      dividerHeight: 0,
      padding: padding,
      tabAlignment: TabAlignment.start,
      physics: const ClampingScrollPhysics(),
      labelStyle: ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
      unselectedLabelStyle: ChewieTheme.titleMedium.apply(color: Colors.grey),
      indicator: UnderlinedTabIndicator(borderColor: ChewieTheme.primaryColor),
      onTap: (index) {
        if (_multiSelectMode) exitMultiSelectMode();
        if (_nestScrollController.hasClients) {
          _nestScrollController.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
        _currentTabIndex = index;
        getTokens();
        CloudOTPHiveUtil.setSelectedCategoryUid(currentCategoryUid);
      },
    );
  }

  _buildTab(TokenCategory? category) {
    return Tab(
      child: ContextMenuRegion(
        contextMenu: _buildTabContextMenuButtons(category),
        child: GestureDetector(
          key: (category != null && categories.indexOf(category) == 0)
              ? _firstCategoryTabKey
              : null,
          onLongPress: () {
            HapticFeedback.lightImpact();
            if (category != null) {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => SelectTokenBottomSheet(category: category),
              );
            } else {
              RouteUtil.pushDialogRoute(context, const CategoryScreen());
            }
          },
          child: Text(category?.title ?? (() => appLocalizations.allTokens)()),
        ),
      ),
    );
  }

  processEditCategory(TokenCategory category) {
    InputValidateAsyncController validateAsyncController =
        InputValidateAsyncController(
      validator: (text) async {
        if (text.isEmpty) {
          return appLocalizations.categoryNameCannotBeEmpty;
        }
        if (text != category.title && await CategoryDao.isCategoryExist(text)) {
          return appLocalizations.categoryNameDuplicate;
        }
        return null;
      },
      controller: TextEditingController(),
    );
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => InputBottomSheet(
        title: appLocalizations.editCategoryName,
        hint: appLocalizations.inputCategory,
        style: InputItemStyle(
          maxLength: 32,
        ),
        text: category.title,
        validator: (text) {
          if (text.isEmpty) {
            return appLocalizations.categoryNameCannotBeEmpty;
          }
          return null;
        },
        validateAsyncController: validateAsyncController,
        onValidConfirm: (text) async {
          category.title = text;
          await CategoryDao.updateCategory(category);
          refreshCategories();
        },
      ),
    );
  }

  static addCategory(
    BuildContext context, {
    Function(TokenCategory)? onAdded,
  }) async {
    InputValidateAsyncController validateAsyncController =
        InputValidateAsyncController(
      validator: (text) async {
        if (text.isEmpty) {
          return appLocalizations.categoryNameCannotBeEmpty;
        }
        if (await CategoryDao.isCategoryExist(text)) {
          return appLocalizations.categoryNameDuplicate;
        }
        return null;
      },
      controller: TextEditingController(),
    );
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => InputBottomSheet(
        title: appLocalizations.addCategory,
        hint: appLocalizations.inputCategory,
        validator: (text) {
          if (text.isEmpty) {
            return appLocalizations.categoryNameCannotBeEmpty;
          }
          return null;
        },
        checkSyncValidator: false,
        validateAsyncController: validateAsyncController,
        style: InputItemStyle(
          maxLength: 32,
        ),
        onValidConfirm: (text) async {
          TokenCategory category = TokenCategory.title(title: text);
          await CategoryDao.insertCategory(category);
          homeScreenState?.refreshCategories();
          onAdded?.call(category);
          return true;
        },
      ),
    );
  }

  _buildTabContextMenuButtons(TokenCategory? category) {
    if (category == null) {
      return FlutterContextMenu(
        entries: [
          FlutterContextMenuItem(
            appLocalizations.addCategory,
            iconData: LucideIcons.plus,
            onPressed: () {
              addCategory(context);
            },
          ),
        ],
      );
    }
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.editCategoryName,
          iconData: LucideIcons.pencilLine,
          onPressed: () {
            processEditCategory(category);
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.editCategoryTokens,
          iconData: LucideIcons.coins,
          onPressed: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              (context) => SelectTokenBottomSheet(category: category),
            );
          },
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          appLocalizations.addCategory,
          iconData: LucideIcons.plus,
          onPressed: () {
            addCategory(context);
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.deleteCategory,
          iconData: LucideIcons.trash2,
          status: MenuItemStatus.error,
          onPressed: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.deleteCategory,
              message: appLocalizations.deleteCategoryHint(category.title),
              confirmButtonText: appLocalizations.confirm,
              cancelButtonText: appLocalizations.cancel,
              onTapConfirm: () async {
                await CategoryDao.deleteCategory(category);
                IToast.showTop(
                    appLocalizations.deleteCategorySuccess(category.title));
                refreshCategories();
              },
              onTapCancel: () {},
            );
          },
        ),
      ],
    );
  }

  unfocusSearch() {
    appProvider.searchFocusNode.unfocus();
    appProvider.shortcutFocusNode.unfocus();
  }

  performSearch(String searchKey) {
    if (_multiSelectMode) exitMultiSelectMode();
    _searchKey = searchKey;
    getTokens();
  }

  changeLayoutType([LayoutType? type]) {
    setState(() {
      if (type != null) {
        layoutType = type;
      } else {
        layoutType = layoutType == LayoutType.values.last
            ? LayoutType.Simple
            : LayoutType.values[layoutType.index + 1];
      }
      CloudOTPHiveUtil.setLayoutType(layoutType);
    });
    mainScreenState?.refresh();
  }

  changeOrderType({
    bool doPerformSort = true,
    OrderType? type,
  }) {
    setState(() {
      if (type != null) {
        orderType = type;
      } else {
        orderType = orderType == OrderType.CreateTimeASC
            ? OrderType.Default
            : OrderType.values[orderType.index + 1];
      }
      CloudOTPHiveUtil.setOrderType(orderType);
    });
    if (doPerformSort) performSort();
    mainScreenState?.refresh();
  }

  resetCopyTimesSingle(OtpToken token) {
    int updateIndex = tokens.indexWhere((element) => element.uid == token.uid);
    tokens[updateIndex].copyTimes = 0;
    tokens[updateIndex].lastCopyTimeStamp = 0;
    if (orderType == OrderType.CopyTimesDESC ||
        orderType == OrderType.CopyTimesASC) {
      performSort();
    }
  }

  resetCopyTimes() {
    for (var element in tokens) {
      element.copyTimes = 0;
    }
    if (orderType == OrderType.CopyTimesDESC ||
        orderType == OrderType.CopyTimesASC) {
      performSort();
    }
  }

  performSort() {
    switch (orderType) {
      case OrderType.Default:
        tokens.sort((a, b) => -a.seq.compareTo(b.seq));
        break;
      case OrderType.AlphabeticalASC:
        tokens.sort((a, b) => a.issuer.compareTo(b.issuer));
        break;
      case OrderType.AlphabeticalDESC:
        tokens.sort((a, b) => -a.issuer.compareTo(b.issuer));
        break;
      case OrderType.CopyTimesDESC:
        tokens.sort((a, b) => -a.copyTimes.compareTo(b.copyTimes));
        break;
      case OrderType.CopyTimesASC:
        tokens.sort((a, b) => a.copyTimes.compareTo(b.copyTimes));
        break;
      case OrderType.LastCopyTimeDESC:
        tokens.sort(
            (a, b) => -a.lastCopyTimeStamp.compareTo(b.lastCopyTimeStamp));
        break;
      case OrderType.LastCopyTimeASC:
        tokens
            .sort((a, b) => a.lastCopyTimeStamp.compareTo(b.lastCopyTimeStamp));
        break;
      case OrderType.CreateTimeDESC:
        tokens.sort((a, b) => -a.createTimeStamp.compareTo(b.createTimeStamp));
        break;
      case OrderType.CreateTimeASC:
        tokens.sort((a, b) => a.createTimeStamp.compareTo(b.createTimeStamp));
        break;
    }
    tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
    setState(() {});
  }

  @override
  void jumpToPage(int index) {}

  @override
  FutureOr popAll([bool initPage = true]) {
    Navigator.pop(context);
  }

  @override
  FutureOr popPage() {
    Navigator.pop(context);
  }

  @override
  FutureOr pushPage(Widget page) {
    RouteUtil.pushCupertinoRoute(context, page);
  }

  @override
  void refreshScrollControllers() {}

  @override
  void showBottomNavigationBar() {}

  @override
  void updateStatusBar() {}
}

enum LayoutType {
  Simple,
  Compact,
  Spotlight,
  List;

  double get maxCrossAxisExtent {
    switch (this) {
      case LayoutType.Simple:
        return 250;
      case LayoutType.Compact:
        return 250;
      // case LayoutType.Tile:
      //   return 420;
      case LayoutType.List:
        return 480;
      case LayoutType.Spotlight:
        return 480;
    }
  }

  double getHeight([bool hideProgressBar = false]) {
    switch (this) {
      case LayoutType.Simple:
        return 108;
      case LayoutType.Compact:
        return 108;
      // case LayoutType.Tile:
      //   return 114;
      case LayoutType.List:
        return 60;
      case LayoutType.Spotlight:
        return 108;
    }
  }

  IconData get icon {
    switch (this) {
      case LayoutType.Simple:
        return LucideIcons.layoutGrid;
      case LayoutType.Compact:
        return LucideIcons.layoutDashboard;
      // case LayoutType.Tile:
      //   return LucideIcons.grid;
      case LayoutType.List:
        return LucideIcons.layoutList;
      case LayoutType.Spotlight:
        return LucideIcons.layoutTemplate;
    }
  }

  String get title {
    switch (this) {
      case LayoutType.Simple:
        return appLocalizations.simpleLayoutType;
      case LayoutType.Compact:
        return appLocalizations.compactLayoutType;
      // case LayoutType.Tile:
      //   return appLocalizations.tileLayout;
      case LayoutType.List:
        return appLocalizations.listLayoutType;
      case LayoutType.Spotlight:
        return appLocalizations.spotlightLayoutType;
    }
  }
}

enum OrderType {
  Default,
  AlphabeticalASC,
  AlphabeticalDESC,
  CopyTimesDESC,
  CopyTimesASC,
  LastCopyTimeDESC,
  LastCopyTimeASC,
  CreateTimeDESC,
  CreateTimeASC;

  String get title {
    switch (this) {
      case OrderType.Default:
        return appLocalizations.defaultOrder;
      case OrderType.AlphabeticalASC:
        return appLocalizations.alphabeticalASCOrder;
      case OrderType.AlphabeticalDESC:
        return appLocalizations.alphabeticalDESCOrder;
      case OrderType.CopyTimesDESC:
        return appLocalizations.copyTimesDESCOrder;
      case OrderType.CopyTimesASC:
        return appLocalizations.copyTimesASCOrder;
      case OrderType.LastCopyTimeDESC:
        return appLocalizations.lastCopyTimeDESCOrder;
      case OrderType.LastCopyTimeASC:
        return appLocalizations.lastCopyTimeASCOrder;
      case OrderType.CreateTimeDESC:
        return appLocalizations.createTimeDESCOrder;
      case OrderType.CreateTimeASC:
        return appLocalizations.createTimeASCOrder;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.Default:
        return LucideIcons.arrowUpNarrowWide;
      case OrderType.AlphabeticalASC:
        return LucideIcons.arrowDownAZ;
      case OrderType.AlphabeticalDESC:
        return LucideIcons.arrowDownZA;
      case OrderType.CopyTimesDESC:
        return LucideIcons.arrowDown10;
      case OrderType.CopyTimesASC:
        return LucideIcons.arrowDown01;
      case OrderType.LastCopyTimeDESC:
        return LucideIcons.clockArrowDown;
      case OrderType.LastCopyTimeASC:
        return LucideIcons.clockArrowUp;
      case OrderType.CreateTimeDESC:
        return LucideIcons.clockArrowDown;
      case OrderType.CreateTimeASC:
        return LucideIcons.clockArrowUp;
    }
  }
}

extension LayoutTypeExtension on int {
  LayoutType get layoutType {
    return LayoutType
        .values[ChewieUtils.patchEnum(0, LayoutType.values.length)];
  }
}

extension OrderTypeExtension on int {
  OrderType get orderType {
    return OrderType.values[ChewieUtils.patchEnum(0, OrderType.values.length)];
  }
}
