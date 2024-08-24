import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/TokenUtils/code_generator.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/token_option_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import '../../generated/l10n.dart';

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

  bool _codeVisiable = !HiveUtil.getBool(HiveUtil.defaultHideCodeKey);

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

class TokenLayoutState extends State<TokenLayout>
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

  _buildContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(S.current.copyTokenCode,
            onPressed: _processCopyCode),
        ContextMenuButtonConfig(S.current.copyNextTokenCode,
            onPressed: _processCopyNextCode),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig(
            widget.token.pinned ? S.current.unPinToken : S.current.pinToken,
            textColor:
                widget.token.pinned ? Theme.of(context).primaryColor : null,
            onPressed: _processPin),
        ContextMenuButtonConfig(S.current.editToken, onPressed: _processEdit),
        ContextMenuButtonConfig(S.current.editTokenIcon,
            onPressed: _processEditIcon),
        ContextMenuButtonConfig(S.current.editTokenCategory,
            onPressed: _processEditCategory),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig(S.current.viewTokenQrCode,
            onPressed: _processViewQrCode),
        ContextMenuButtonConfig(S.current.copyTokenUri,
            onPressed: _processCopyUri),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig.warning(S.current.resetCopyTimes,
            textColor: Colors.red, onPressed: _processResetCopyTimes),
        ContextMenuButtonConfig.warning(S.current.deleteToken,
            textColor: Colors.red, onPressed: _processDelete),
      ],
    );
  }

  _buildContextMenuRegion() {
    return ContextMenuRegion(
      key: ValueKey("contextMenuRegion${widget.token.keyString}"),
      behavior: ResponsiveUtil.isDesktop()
          ? const [ContextMenuShowBehavior.secondaryTap]
          : const [],
      contextMenu: _buildContextMenuButtons(),
      child: Selector<AppProvider, bool>(
        selector: (context, provider) => provider.dragToReorder,
        builder: (context, dragToReorder, child) => GestureDetector(
          onLongPress: dragToReorder && !ResponsiveUtil.isLandscape()
              ? () {
                  showContextMenu();
                  HapticFeedback.lightImpact();
                }
              : null,
          child: _buildBody(),
        ),
      ),
    );
  }

  _buildBody() {
    switch (widget.layoutType) {
      case LayoutType.Simple:
        return _buildSimpleLayout();
      case LayoutType.Compact:
        return _buildCompactLayout();
      case LayoutType.Tile:
        return _buildTileLayout();
      case LayoutType.List:
        return _buildListLayout();
      case LayoutType.Spotlight:
        return _buildSpotlightLayout();
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
    Utils.copy(context, getCurrentCode());
    TokenDao.incTokenCopyTimes(widget.token);
  }

  _processCopyNextCode() {
    Utils.copy(context, getNextCode());
    TokenDao.incTokenCopyTimes(widget.token);
  }

  _processEdit() {
    RouteUtil.pushDialogRoute(context, AddTokenScreen(token: widget.token),
        showClose: false);
  }

  _processPin() async {
    await TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
    IToast.showTop(
      widget.token.pinned
          ? S.current.alreadyUnPinnedToken(widget.token.title)
          : S.current.alreadyPinnedToken(widget.token.title),
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
    DialogBuilder.showInfoDialog(
      context,
      title: widget.token.title,
      onTapDismiss: () {},
      messageChild: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrettyQrView.data(
          data: OtpTokenParser.toUri(widget.token).toString(),
        ),
      ),
    );
  }

  _processCopyUri() {
    DialogBuilder.showConfirmDialog(
      context,
      title: S.current.copyUriClearWarningTitle,
      message: S.current.copyUriClearWarningTip,
      onTapConfirm: () {
        Utils.copy(context, OtpTokenParser.toUri(widget.token));
      },
      onTapCancel: () {},
    );
  }

  _processResetCopyTimes() {
    DialogBuilder.showConfirmDialog(
      context,
      title: S.current.resetCopyTimesTitle,
      message: S.current.resetCopyTimesMessage(widget.token.title),
      onTapConfirm: () async {
        await TokenDao.resetSingleTokenCopyTimes(widget.token);
        homeScreenState?.resetCopyTimesSingle(widget.token);
        IToast.showTop(S.current.resetSuccess);
      },
      onTapCancel: () {},
    );
  }

  _processDelete() {
    DialogBuilder.showConfirmDialog(
      context,
      title: S.current.deleteTokenTitle(widget.token.title),
      message: S.current.deleteTokenMessage(widget.token.title),
      onTapConfirm: () async {
        await TokenDao.deleteToken(widget.token);
        IToast.showTop(S.current.deleteTokenSuccess(widget.token.title));
        homeScreenState?.removeToken(widget.token);
      },
      onTapCancel: () {},
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
            ? Container(
                child: ItemBuilder.buildIconButton(
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
                        color ?? Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  context: context,
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
    return ChangeNotifierProvider.value(
      value: tokenLayoutNotifier,
      child: Selector<TokenLayoutNotifier, bool>(
        selector: (context, tokenLayoutNotifier) =>
            tokenLayoutNotifier.codeVisiable,
        builder: (context, codeVisiable, child) =>
            Selector<TokenLayoutNotifier, String>(
          selector: (context, tokenLayoutNotifier) => tokenLayoutNotifier.code,
          builder: (context, code, child) => Container(
            alignment: alignment,
            child: AutoSizeText(
              codeVisiable
                  ? code
                  : (isHOTP ? hotpPlaceholderText : placeholderText) *
                      widget.token.digits.digit,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    letterSpacing: letterSpacing,
                    color: Theme.of(context).primaryColor,
                  ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  _buildLinearProgress() {
    return isHOTP
        ? const SizedBox.shrink()
        : ValueListenableBuilder(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return Container(
                margin: const EdgeInsets.only(top: 3, bottom: 13),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 1,
                  color: progress > autoCopyNextCodeProgressThrehold
                      ? Theme.of(context).primaryColor
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
              margin: const EdgeInsets.only(left: 8),
              child: Stack(
                children: [
                  ValueListenableBuilder(
                    valueListenable: progressNotifier,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: progressNotifier.value,
                        color: progressNotifier.value >
                                autoCopyNextCodeProgressThrehold
                            ? Theme.of(context).primaryColor
                            : Colors.red,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                      );
                    },
                  ),
                  Center(
                    child: ValueListenableBuilder(
                      valueListenable: progressNotifier,
                      builder: (context, value, child) {
                        return Text(
                          (remainingMilliseconds / 1000).toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodyMedium?.apply(
                                color: currentProgress >
                                        autoCopyNextCodeProgressThrehold
                                    ? Theme.of(context).primaryColor
                                    : Colors.red,
                                fontSizeDelta: -2,
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
    tokenLayoutNotifier.codeVisiable = true;
    updateCode();
    if (HiveUtil.getBool(HiveUtil.clickToCopyKey)) {
      if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
          currentProgress < autoCopyNextCodeProgressThrehold) {
        _processCopyNextCode();
      } else {
        _processCopyCode();
      }
      if (HiveUtil.getBool(HiveUtil.autoMinimizeAfterClickToCopyKey,
          defaultValue: false)) {
        if (ResponsiveUtil.isDesktop()) {
          windowManager.minimize();
        } else {
          MoveToBackground.moveTaskToBack();
        }
      }
    }
  }

  _buildSimpleLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    ItemBuilder.buildTokenImage(widget.token, size: 32),
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
                    if (isHOTP) _buildHOTPRefreshButton(padding: 6),
                  ],
                ),
                const SizedBox(height: 8),
                Selector<AppProvider, bool>(
                  selector: (context, provider) => provider.hideProgressBar,
                  builder: (context, hideProgressBar, child) => Container(
                    constraints: BoxConstraints(
                      minHeight: hideProgressBar ? 42 : 58,
                      maxHeight: hideProgressBar ? 42 : 58,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCodeLayout(
                            letterSpacing: 10, alignment: Alignment.center),
                        const SizedBox(height: 5),
                        if (!hideProgressBar) _buildLinearProgress(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildCompactLayout() {
    TextTheme textTheme = Theme.of(context).textTheme;
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
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
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ItemBuilder.buildTokenImage(widget.token, size: 28),
                  ],
                ),
                const SizedBox(height: 6),
                Selector<AppProvider, bool>(
                  selector: (context, provider) => provider.hideProgressBar,
                  builder: (context, hideProgressBar, child) => Container(
                    constraints: BoxConstraints(
                      minHeight: hideProgressBar ? 39 : 53,
                      maxHeight: hideProgressBar ? 39 : 53,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildCodeLayout()),
                            if (isHOTP)
                              _buildHOTPRefreshButton(
                                padding: 4,
                                color: textTheme.labelSmall?.color,
                              ),
                            ItemBuilder.buildIconButton(
                              context: context,
                              padding: const EdgeInsets.all(4),
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.color,
                                size: 20,
                              ),
                              onTap: showContextMenu,
                            ),
                          ],
                        ),
                        if (!hideProgressBar) _buildLinearProgress(),
                        if (hideProgressBar) const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildTileLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    ItemBuilder.buildTokenImage(widget.token, size: 36),
                    const SizedBox(width: 8),
                    Expanded(
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
                          Text(
                            widget.token.account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isHOTP) _buildHOTPRefreshButton(),
                    ItemBuilder.buildIconButton(
                        context: context,
                        icon: Icon(Icons.edit_rounded,
                            color: Theme.of(context).iconTheme.color, size: 20),
                        onTap: _processEdit),
                    ItemBuilder.buildIconButton(
                        context: context,
                        icon: Icon(Icons.qr_code_rounded,
                            color: Theme.of(context).iconTheme.color, size: 20),
                        onTap: _processViewQrCode),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: Icon(Icons.more_vert_rounded,
                          color: Theme.of(context).iconTheme.color, size: 20),
                      onTap: showContextMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Selector<AppProvider, bool>(
                  selector: (context, provider) => provider.hideProgressBar,
                  builder: (context, hideProgressBar, child) => Container(
                    constraints: BoxConstraints(
                      minHeight: hideProgressBar ? 49 : 62,
                      maxHeight: hideProgressBar ? 49 : 62,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [_buildCodeLayout(fontSize: 30)],
                        ),
                        if (!hideProgressBar) _buildLinearProgress(),
                        if (hideProgressBar) const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildSpotlightLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 3),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  child: ItemBuilder.buildTokenImage(widget.token, size: 36),
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
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Container(
                          constraints: const BoxConstraints(
                              maxHeight: 45, minHeight: 45),
                          child: _buildCodeLayout(
                              fontSize: 30, forceNoType: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                isHOTP ? _buildHOTPRefreshButton() : _buildCircleProgress(),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildListLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: _processTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ItemBuilder.buildTokenImage(widget.token, size: 28),
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
                if (!isHOTP) _buildCircleProgress(),
                if (isHOTP)
                  _buildHOTPRefreshButton(
                      padding: 6, color: Theme.of(context).primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
