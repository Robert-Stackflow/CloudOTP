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
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

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
  double _progress = 1;

  double get progress => _progress;

  set progress(double value) {
    _progress = value;
    notifyListeners();
  }

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
}

class TokenLayoutState extends State<TokenLayout>
    with TickerProviderStateMixin {
  Timer? _timer;

  TokenLayoutNotifier tokenLayoutNotifier = TokenLayoutNotifier();

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

  updateInfo() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        tokenLayoutNotifier.progress = currentProgress;
        tokenLayoutNotifier.code = getCurrentCode();
        if (remainingMilliseconds <= 180 && appProvider.autoHideCode) {
          tokenLayoutNotifier.codeVisiable = false;
        }
      }
    });
    tokenLayoutNotifier.code = getCurrentCode();
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
        ContextMenuButtonConfig.warning(S.current.deleteToken,
            onPressed: _processDelete),
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
      child: _buildBody(),
    );
  }

  _buildBody() {
    switch (widget.layoutType) {
      case LayoutType.Simple:
        return _buildSimpleLayout();
      case LayoutType.Compact:
        return _buildDetailLayout();
      case LayoutType.Tile:
        return _buildLargeLayout();
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

  _processPin() {
    TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
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
      customDialogType: CustomDialogType.normal,
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
      customDialogType: CustomDialogType.normal,
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
      customDialogType: CustomDialogType.normal,
    );
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
                    const SizedBox(width: 12),
                    Flexible(
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
                  ],
                ),
                const SizedBox(height: 8),
                _buildCodeLayout(
                    letterSpacing: 10, alignment: Alignment.center),
                const SizedBox(height: 8),
                isHOTP ? const SizedBox(height: 1) : _buildProgressBar(),
                const SizedBox(height: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildCodeLayout({
    double letterSpacing = 5,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    if (widget.token.issuer == "Google" || widget.token.issuer == "Reddit") {
      print("${widget.token.title} ${tokenLayoutNotifier.hashCode.toString()}");
    }
    return ChangeNotifierProvider.value(
      value: tokenLayoutNotifier,
      child: Selector<TokenLayoutNotifier, bool>(
        selector: (context, tokenLayoutNotifier) =>
            tokenLayoutNotifier.codeVisiable,
        builder: (context, codeVisiable, child) {
          return Selector<TokenLayoutNotifier, String>(
            selector: (context, tokenLayoutNotifier) =>
                tokenLayoutNotifier.code,
            builder: (context, code, child) {
              return Container(
                constraints: const BoxConstraints(minHeight: 36),
                alignment: alignment,
                child: AutoSizeText(
                  codeVisiable ? code : "*" * widget.token.digits.digit,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        letterSpacing: letterSpacing,
                        color: Theme.of(context).primaryColor,
                      ),
                  maxLines: 1,
                ),
              );
            },
          );
        },
      ),
    );
  }

  _buildProgressBar() {
    return ChangeNotifierProvider.value(
      value: tokenLayoutNotifier,
      child: Selector<TokenLayoutNotifier, double>(
        selector: (context, tokenLayoutNotifier) =>
            tokenLayoutNotifier.progress,
        builder: (context, progress, child) {
          return LinearProgressIndicator(
            value: progress,
            minHeight: 1,
            color: progress > autoCopyNextCodeProgressThrehold
                ? Theme.of(context).primaryColor
                : Colors.red,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: Colors.grey.withOpacity(0.3),
          );
        },
      ),
    );
  }

  _processTap() {
    tokenLayoutNotifier.codeVisiable = true;
    if (HiveUtil.getBool(HiveUtil.clickToCopyKey)) {
      if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
          currentProgress < autoCopyNextCodeProgressThrehold) {
        _processCopyNextCode();
      } else {
        _processCopyCode();
      }
    }
  }

  _buildDetailLayout() {
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildCodeLayout()),
                    ItemBuilder.buildIconButton(
                      context: context,
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).textTheme.labelSmall?.color,
                        size: 20,
                      ),
                      onTap: showContextMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                isHOTP ? const SizedBox(height: 1) : _buildProgressBar(),
                const SizedBox(height: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildLargeLayout() {
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
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                      onTap: showContextMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [_buildCodeLayout()],
                ),
                const SizedBox(height: 3),
                isHOTP ? const SizedBox(height: 1) : _buildProgressBar(),
                const SizedBox(height: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
