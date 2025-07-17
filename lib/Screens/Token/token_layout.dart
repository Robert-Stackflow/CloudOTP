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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/TokenUtils/code_generator.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/token_option_bottom_sheet.dart';
import 'package:cloudotp/Widgets/cloudotp/cloudotp_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class TokenLayout extends StatefulWidget {
  const TokenLayout({
    super.key,
    required this.token,
    required this.layoutType,
  });

  final OtpToken token;

  final LayoutType layoutType;

  @override
  State<TokenLayout> createState() => TokenLayoutState();
}

class TokenLayoutNotifier extends ChangeNotifier {
  String _code = "";

  String get code => _code;

  set code(String value) {
    _code = value;
    notifyListeners();
  }

  bool _codeVisiable =
      !ChewieHiveUtil.getBool(CloudOTPHiveUtil.defaultHideCodeKey);

  bool get codeVisiable => _codeVisiable;

  set codeVisiable(bool value) {
    _codeVisiable = value;
    notifyListeners();
  }

  bool _haveToResetHOTP = false;

  bool get haveToResetHOTP => _haveToResetHOTP;

  set haveToResetHOTP(bool value) {
    _haveToResetHOTP = value;
    notifyListeners();
  }
}

class TokenLayoutState extends BaseDynamicState<TokenLayout>
    with TickerProviderStateMixin {
  Timer? _timer;

  TokenLayoutNotifier tokenLayoutNotifier = TokenLayoutNotifier();

  final ValueNotifier<double> progressNotifier = ValueNotifier(0);

  int get remainingMilliseconds => widget.token.period == 0
      ? 0
      : widget.token.period * 1000 -
          (DateTime.now().millisecondsSinceEpoch %
              (widget.token.period * 1000));

  double get currentProgress => widget.token.period == 0
      ? 0
      : remainingMilliseconds / (widget.token.period * 1000);

  bool get isYandex => widget.token.tokenType == OtpTokenType.Yandex;

  bool get isHOTP => widget.token.tokenType == OtpTokenType.HOTP;

  @override
  void dispose() {
    _timer?.cancel();
    tokenLayoutNotifier.dispose();
    super.dispose();
  }

  updateInfo({
    bool counterChanged = false,
  }) {
    setState(() {});
    if (isHOTP && counterChanged) {
      tokenLayoutNotifier.codeVisiable = true;
      resetTimer();
    }
  }

  @override
  void initState() {
    super.initState();
    updateCode();
    progressNotifier.value = currentProgress;
    resetTimer();
  }

  resetTimer() {
    tokenLayoutNotifier.haveToResetHOTP = false;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        progressNotifier.value = currentProgress;
        if (remainingMilliseconds <= 180 && appProvider.autoHideCode) {
          tokenLayoutNotifier.codeVisiable = false;
        }
        updateCode();
        if (remainingMilliseconds <= 100) {
          tokenLayoutNotifier.haveToResetHOTP = true;
          tokenLayoutNotifier.code = getNextCode();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContextMenuRegion();
  }

  String getCurrentCode() {
    return CodeGenerator.getCurrentCode(widget.token);
  }

  getNextCode() {
    return CodeGenerator.getNextCode(widget.token);
  }

  FlutterContextMenu _buildContextMenuButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          iconData: LucideIcons.copy,
          appLocalizations.copyTokenCode,
          onPressed: _processCopyCode,
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          widget.token.pinned ? appLocalizations.unPinToken : appLocalizations.pinToken,
          iconData: widget.token.pinned ? LucideIcons.pinOff : LucideIcons.pin,
          style: MenuItemStyle(
            normalColor: widget.token.pinned ? ChewieTheme.primaryColor : null,
          ),
          onPressed: _processPin,
        ),
        FlutterContextMenuItem(
          iconData: LucideIcons.pencilLine,
          appLocalizations.editToken,
          onPressed: _processEdit,
        ),
        FlutterContextMenuItem(
          iconData: LucideIcons.qrCode,
          appLocalizations.viewTokenQrCode,
          onPressed: _processViewQrCode,
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(
          iconData: LucideIcons.blend,
          appLocalizations.editTokenIcon,
          onPressed: _processEditIcon,
        ),
        FlutterContextMenuItem(
          iconData: LucideIcons.shapes,
          appLocalizations.editTokenCategory,
          onPressed: _processEditCategory,
        ),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem.submenu(
          appLocalizations.moreOptionShort,
          iconData: LucideIcons.ellipsis,
          items: [
            FlutterContextMenuItem(
              iconData: LucideIcons.text,
              appLocalizations.copyTokenUri,
              onPressed: _processCopyUri,
            ),
            FlutterContextMenuItem(
              iconData: LucideIcons.copySlash,
              appLocalizations.copyNextTokenCode,
              onPressed: _processCopyNextCode,
            ),
            FlutterContextMenuItem.divider(),
            FlutterContextMenuItem(
              iconData: LucideIcons.rotateCcw,
              appLocalizations.resetCopyTimes,
              status: MenuItemStatus.error,
              onPressed: _processResetCopyTimes,
            ),
            FlutterContextMenuItem(
              iconData: LucideIcons.trash2,
              appLocalizations.deleteToken,
              status: MenuItemStatus.error,
              onPressed: _processDelete,
            ),
          ],
        ),
      ],
    );
  }

  _buildContextMenuRegion() {
    return ContextMenuRegion(
      key: ValueKey("contextMenuRegion${widget.token.keyString}"),
      enable: ResponsiveUtil.isDesktop(),
      enableOnLongPress: false,
      contextMenu: _buildContextMenuButtons(),
      child: Selector<AppProvider, bool>(
        selector: (context, provider) => provider.dragToReorder,
        builder: (context, dragToReorder, child) => GestureDetector(
          onLongPress: dragToReorder && !ResponsiveUtil.isDesktop()
              ? () {
                  showContextMenu();
                  HapticFeedback.lightImpact();
                }
              : null,
          child: PressableAnimation(child: _buildBody()),
        ),
      ),
    );
  }

  _buildSlidable({
    required Widget child,
    bool simple = false,
    double startExtentRatio = 0.16,
    double endExtentRatio = 0.64,
  }) {
    return Slidable(
      groupTag: "TokenLayout",
      enabled: !ResponsiveUtil.isWideLandscape(),
      startActionPane: ActionPane(
        extentRatio: startExtentRatio,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _processPin(),
            backgroundColor: widget.token.pinned
                ? ChewieTheme.primaryColor
                : ChewieTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            foregroundColor: ChewieTheme.primaryColor,
            icon: widget.token.pinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            label: widget.token.pinned
                ? appLocalizations.unPinTokenShort
                : appLocalizations.pinTokenShort,
            simple: simple,
            spacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            iconAndTextColor: widget.token.pinned ? Colors.white : null,
          ),
          const SizedBox(width: 6),
        ],
      ),
      endActionPane: ActionPane(
        extentRatio: endExtentRatio,
        motion: const ScrollMotion(),
        children: [
          const SizedBox(width: 6),
          SlidableAction(
            onPressed: (context) => _processViewQrCode(),
            backgroundColor: ChewieTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            foregroundColor: ChewieTheme.primaryColor,
            icon: LucideIcons.qrCode,
            label: appLocalizations.viewTokenQrCodeShort,
            spacing: 8,
            simple: simple,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          const SizedBox(width: 6),
          SlidableAction(
            onPressed: (context) => _processEdit(),
            backgroundColor: ChewieTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            foregroundColor: ChewieTheme.primaryColor,
            icon: LucideIcons.pencilLine,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            label: appLocalizations.editTokenShort,
            simple: simple,
            spacing: 8,
          ),
          const SizedBox(width: 6),
          SlidableAction(
            onPressed: (context) => showContextMenu(),
            backgroundColor: ChewieTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            foregroundColor: ChewieTheme.primaryColor,
            icon: LucideIcons.ellipsisVertical,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            label: appLocalizations.moreOptionShort,
            simple: simple,
            spacing: 8,
          ),
          const SizedBox(width: 6),
          SlidableAction(
            onPressed: (context) => _processDelete(),
            backgroundColor: Colors.red,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            foregroundColor: ChewieTheme.primaryColor,
            icon: LucideIcons.trash2,
            simple: simple,
            label: appLocalizations.deleteTokenShort,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            spacing: 8,
            iconAndTextColor: Colors.white,
          ),
        ],
      ),
      child: child,
    );
  }

  _buildBody() {
    switch (widget.layoutType) {
      case LayoutType.Simple:
        return _buildSimpleLayout();
      case LayoutType.Compact:
        return _buildCompactLayout();
      // case LayoutType.Tile:
      //   return _buildSlidable(
      //     startExtentRatio: 0.23,
      //     endExtentRatio: 0.9,
      //     child: _buildTileLayout(),
      //   );
      case LayoutType.List:
        return _buildSlidable(
          simple: true,
          child: _buildListLayout(),
        );
      case LayoutType.Spotlight:
        return _buildSlidable(
          startExtentRatio: 0.21,
          endExtentRatio: 0.8,
          child: _buildSpotlightLayout(),
        );
    }
  }

  showContextMenu() {
    if (ResponsiveUtil.isLandscape()) {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => TokenOptionBottomSheet(token: widget.token),
      );
    } else {
      BottomSheetBuilder.showBottomSheet(
        context,
        responsive: true,
        (context) => TokenOptionBottomSheet(token: widget.token),
      );
    }
  }

  _processCopyCode() {
    ChewieUtils.copy(context, getCurrentCode());
    TokenDao.incTokenCopyTimes(widget.token);
  }

  _processCopyNextCode() {
    ChewieUtils.copy(context, getNextCode());
    TokenDao.incTokenCopyTimes(widget.token);
  }

  _processEdit() {
    RouteUtil.pushDialogRoute(context, AddTokenScreen(token: widget.token));
  }

  _processPin() async {
    await TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
    IToast.showTop(
      widget.token.pinned
          ? appLocalizations.alreadyPinnedToken(widget.token.title)
          : appLocalizations.alreadyUnPinnedToken(widget.token.title),
    );
    homeScreenState?.updateToken(widget.token, pinnedStateChanged: true);
  }

  _processEditIcon() {
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => SelectIconBottomSheet(
        token: widget.token,
        onSelected: (path) => {},
        doUpdate: true,
      ),
    );
  }

  _processEditCategory() {
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (context) => SelectCategoryBottomSheet(token: widget.token),
    );
  }

  _processViewQrCode() {
    CloudOTPItemBuilder.showQrcodesDialog(
      context,
      title: widget.token.title,
      qrcodes: [OtpTokenParser.toUri(widget.token).toString()],
      asset: AssetFiles.getBrandPath(widget.token.imagePath),
    );
  }

  _processCopyUri() {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.copyUriClearWarningTitle,
      message: appLocalizations.copyUriClearWarningTip,
      onTapConfirm: () {
        ChewieUtils.copy(context, OtpTokenParser.toUri(widget.token));
      },
      onTapCancel: () {},
    );
  }

  _processResetCopyTimes() {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.resetCopyTimesTitle,
      message: appLocalizations.resetCopyTimesMessage(widget.token.title),
      onTapConfirm: () async {
        await TokenDao.resetSingleTokenCopyTimes(widget.token);
        homeScreenState?.resetCopyTimesSingle(widget.token);
        IToast.showTop(appLocalizations.resetSuccess);
      },
      onTapCancel: () {},
    );
  }

  _processDelete() {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.deleteTokenTitle(widget.token.title),
      message: appLocalizations.deleteTokenMessage(widget.token.title),
      onTapConfirm: () async {
        await TokenDao.deleteToken(widget.token);
        IToast.showTop(appLocalizations.deleteTokenSuccess(widget.token.title));
        homeScreenState?.removeToken(widget.token);
      },
      onTapCancel: () {},
    );
  }

  _buildVisibleLayout(Function(bool) builder) {
    return ChangeNotifierProvider.value(
      value: tokenLayoutNotifier,
      child: Selector<TokenLayoutNotifier, bool>(
        selector: (context, tokenLayoutNotifier) =>
            tokenLayoutNotifier.codeVisiable,
        builder: (context, codeVisiable, child) => builder(codeVisiable),
      ),
    );
  }

  _buildVisibleLayoutWithEye(Function(bool) builder) {
    return _buildVisibleLayout(
      (codeVisiable) => Selector<AppProvider, bool>(
        selector: (context, provider) => provider.showEye,
        builder: (context, showEye, child) =>
            showEye ? builder(codeVisiable) : builder(true),
      ),
    );
  }

  _buildEyeButton({
    double padding = 8,
    Color? color,
  }) {
    return _buildVisibleLayout(
      (codeVisiable) {
        if (codeVisiable) return emptyWidget;
        return Selector<AppProvider, bool>(
          selector: (context, provider) => provider.showEye,
          builder: (context, showEye, child) => showEye
              ? CircleIconButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    tokenLayoutNotifier.codeVisiable =
                        !tokenLayoutNotifier.codeVisiable;
                    setState(() {});
                  },
                  padding: EdgeInsets.all(padding),
                  icon: Icon(
                    LucideIcons.eye,
                    size: 20,
                    color:
                        color ?? ChewieTheme.labelMedium?.color,
                  ),
                )
              : emptyWidget,
        );
      },
    );
  }

  _buildHOTPRefreshButton({
    double padding = 8,
    Color? color,
  }) {
    return ChangeNotifierProvider.value(
      value: tokenLayoutNotifier,
      child: Selector<TokenLayoutNotifier, bool>(
        selector: (context, tokenLayoutNotifier) =>
            tokenLayoutNotifier.haveToResetHOTP,
        builder: (context, haveToResetHOTP, child) => haveToResetHOTP
            ? CircleIconButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.token.counterString =
                      (widget.token.counter + 1).toString();
                  TokenDao.updateTokenCounter(widget.token);
                  tokenLayoutNotifier.codeVisiable = true;
                  resetTimer();
                  setState(() {});
                },
                padding: EdgeInsets.all(padding),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color:
                      color ?? ChewieTheme.labelMedium?.color,
                ),
              )
            : emptyWidget,
      ),
    );
  }

  _buildCodeLayout({
    double letterSpacing = 5,
    double fontSize = 24,
    AlignmentGeometry alignment = Alignment.centerLeft,
    bool forceNoType = false,
  }) {
    return _buildVisibleLayout(
      (codeVisiable) => ChangeNotifierProvider.value(
        value: tokenLayoutNotifier,
        child: Selector<TokenLayoutNotifier, String>(
          selector: (context, tokenLayoutNotifier) => tokenLayoutNotifier.code,
          builder: (context, code, child) => Container(
            alignment: alignment,
            child: AutoSizeText(
              codeVisiable
                  ? code
                  : (isHOTP ? hotpPlaceholderText : placeholderText) *
                      widget.token.digits.digit,
              textAlign: TextAlign.center,
              style: ChewieTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    letterSpacing: letterSpacing,
                    color: ChewieTheme.primaryColor,
                  ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  _buildLinearProgress([bool hideProgressBar = false]) {
    return isHOTP || hideProgressBar
        ? const SizedBox(height: 1)
        : ValueListenableBuilder(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return Container(
                constraints: const BoxConstraints(minHeight: 2, maxHeight: 2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  color: progress > autoCopyNextCodeProgressThrehold
                      ? ChewieTheme.primaryColor
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey.withOpacity(0.3),
                ),
              );
            },
          );
  }

  _buildCircleProgress() {
    return Selector<AppProvider, bool>(
      selector: (context, provider) => provider.hideProgressBar,
      builder: (context, hideProgressBar, child) => hideProgressBar
          ? const SizedBox.shrink()
          : Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(left: 8, right: 4),
              child: Stack(
                children: [
                  ValueListenableBuilder(
                    valueListenable: progressNotifier,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: progressNotifier.value,
                        color: progressNotifier.value >
                                autoCopyNextCodeProgressThrehold
                            ? ChewieTheme.primaryColor
                            : Colors.red,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                  Center(
                    child: ValueListenableBuilder(
                      valueListenable: progressNotifier,
                      builder: (context, value, child) {
                        return Text(
                          (remainingMilliseconds / 1000).toStringAsFixed(0),
                          style: ChewieTheme.bodyMedium.apply(
                                color: currentProgress >
                                        autoCopyNextCodeProgressThrehold
                                    ? ChewieTheme.primaryColor
                                    : Colors.red,
                                fontSizeDelta: -3,
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  updateCode() {
    if (appProvider.autoDisplayNextCode &&
        currentProgress < autoCopyNextCodeProgressThrehold) {
      tokenLayoutNotifier.code = getNextCode();
    } else {
      tokenLayoutNotifier.code = getCurrentCode();
    }
  }

  _processTap() {
    if (!appProvider.showEye) {
      tokenLayoutNotifier.codeVisiable = true;
    }
    updateCode();
    if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.clickToCopyKey)) {
      if (ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoCopyNextCodeKey) &&
          currentProgress < autoCopyNextCodeProgressThrehold) {
        _processCopyNextCode();
      } else {
        _processCopyCode();
      }
      if (ChewieHiveUtil.getBool(
          CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey,
          defaultValue: false)) {
        if (ResponsiveUtil.isDesktop()) {
          int autoMinimizeAfterClickToCopyOption = ChewieHiveUtil.getInt(
              CloudOTPHiveUtil.autoMinimizeAfterClickToCopyOptionKey,
              defaultValue: 0);
          if (autoMinimizeAfterClickToCopyOption == 0) {
            windowManager.minimize();
          } else {
            windowManager.hide();
          }
        } else {
          MoveToBackground.moveTaskToBack();
        }
      }
    }
  }

  _buildSimpleLayout() {
    return ClickableWrapper(
      child: Material(
        color: widget.token.pinned
            ? ChewieTheme.primaryColor.withOpacity(0.15)
            : ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
            borderRadius: ChewieDimens.defaultBorderRadius),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: ChewieDimens.defaultBorderRadius,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                decoration: const BoxDecoration(
                    borderRadius: ChewieDimens.defaultBorderRadius),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CloudOTPItemBuilder.buildTokenImage(widget.token,
                            size: 32),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.token.issuer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.apply(fontWeightDelta: 2),
                          ),
                        ),
                        if (!isHOTP) _buildEyeButton(padding: 6),
                        if (isHOTP) _buildHOTPRefreshButton(padding: 6),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 56, maxHeight: 56),
                      child: _buildCodeLayout(
                        letterSpacing: 10,
                        alignment: Alignment.center,
                        fontSize: 27,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              Selector<AppProvider, bool>(
                selector: (context, provider) => provider.hideProgressBar,
                builder: (context, hideProgressBar, child) =>
                    _buildLinearProgress(hideProgressBar),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildCompactLayout() {
    return ClickableWrapper(
      child: Material(
        color: widget.token.pinned
            ? ChewieTheme.primaryColor.withOpacity(0.15)
            : ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
            borderRadius: ChewieDimens.defaultBorderRadius),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          customBorder: const RoundedRectangleBorder(
              borderRadius: ChewieDimens.defaultBorderRadius),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                decoration: const BoxDecoration(
                    borderRadius: ChewieDimens.defaultBorderRadius),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.token.issuer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.apply(fontWeightDelta: 2),
                              ),
                              Text(
                                widget.token.account,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChewieTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CloudOTPItemBuilder.buildTokenImage(widget.token,
                            size: 28),
                      ],
                    ),
                    Container(
                      constraints:
                          const BoxConstraints(minHeight: 56, maxHeight: 56),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildCodeLayout(letterSpacing: 8)),
                          if (isHOTP) _buildHOTPRefreshButton(padding: 4),
                          if (!isHOTP) _buildEyeButton(padding: 4),
                          CircleIconButton(
                            padding: const EdgeInsets.all(4),
                            icon: Icon(
                              LucideIcons.ellipsisVertical,
                              color:
                                  ChewieTheme.labelSmall?.color,
                              size: 20,
                            ),
                            onTap: showContextMenu,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Selector<AppProvider, bool>(
                selector: (context, provider) => provider.hideProgressBar,
                builder: (context, hideProgressBar, child) =>
                    _buildLinearProgress(hideProgressBar),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildSpotlightLayout() {
    return ClickableWrapper(
      child: Material(
        color: widget.token.pinned
            ? ChewieTheme.primaryColor.withOpacity(0.15)
            : ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
            borderRadius: ChewieDimens.defaultBorderRadius),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: ChewieDimens.defaultBorderRadius,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: ChewieDimens.defaultBorderRadius),
            padding:
                const EdgeInsets.only(left: 12, right: 12, top: 15, bottom: 8),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  child: CloudOTPItemBuilder.buildTokenImage(widget.token,
                      size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    constraints:
                        const BoxConstraints(maxHeight: 85, minHeight: 85),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.token.issuer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.apply(fontWeightDelta: 2),
                        ),
                        if (widget.token.account.isNotEmpty)
                          Text(
                            widget.token.account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChewieTheme.bodySmall,
                          ),
                        Container(
                          constraints: const BoxConstraints(
                              maxHeight: 45, minHeight: 45),
                          child: _buildCodeLayout(
                              fontSize: 28,
                              forceNoType: false,
                              letterSpacing: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                if (!isHOTP) _buildEyeButton(),
                if (isHOTP) _buildHOTPRefreshButton(),
                if (!isHOTP)
                  _buildVisibleLayoutWithEye((codeVisible) =>
                      codeVisible ? _buildCircleProgress() : emptyWidget),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildListLayout() {
    return ClickableWrapper(
      child: Material(
        color: widget.token.pinned
            ? ChewieTheme.primaryColor.withOpacity(0.15)
            : ChewieTheme.canvasColor,
        shape: const RoundedRectangleBorder(
            borderRadius: ChewieDimens.defaultBorderRadius),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: ChewieDimens.defaultBorderRadius,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: ChewieDimens.defaultBorderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                CloudOTPItemBuilder.buildTokenImage(widget.token, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.token.issuer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.apply(fontWeightDelta: 2),
                  ),
                ),
                _buildCodeLayout(),
                const SizedBox(width: 4),
                if (!isHOTP)
                  _buildEyeButton(padding: 6, color: ChewieTheme.primaryColor),
                if (!isHOTP)
                  _buildVisibleLayoutWithEye((codeVisible) =>
                      codeVisible ? _buildCircleProgress() : emptyWidget),
                if (isHOTP)
                  _buildHOTPRefreshButton(
                      padding: 6, color: ChewieTheme.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
