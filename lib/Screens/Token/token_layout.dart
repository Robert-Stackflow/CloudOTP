import 'dart:async';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/TokenUtils/mobile_otp.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/TokenUtils/steam_totp.dart';
import 'package:cloudotp/TokenUtils/yandex_otp.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
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

class TokenLayoutState extends State<TokenLayout>
    with TickerProviderStateMixin {
  bool _showCode = true;
  Timer? _timer;
  final double _autoCopyNextCodeProgressThrehold = 0.25;
  final String placeholderText = "*";

  int get remainingMilliseconds =>
      widget.token.period * 1000 -
      (DateTime.now().millisecondsSinceEpoch % (widget.token.period * 1000));

  double get currentProgress =>
      remainingMilliseconds / (widget.token.period * 1000);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (mounted) {
        setState(() {});
        getCurrentCode();
        if (remainingMilliseconds <= 50 &&
            HiveUtil.getBool(HiveUtil.autoHideCodeKey)) {
          setState(() {
            _showCode = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContextMenuRegion();
  }

  String getCurrentCode() {
    late String code;
    switch (widget.token.tokenType) {
      case OtpTokenType.TOTP:
        code = OTP.generateTOTPCodeString(
          widget.token.secret,
          DateTime.now().millisecondsSinceEpoch - widget.token.period * 1000,
          length: widget.token.digits.digit,
          interval: widget.token.period,
          algorithm: widget.token.algorithm.algorithm,
          isGoogle: true,
        );
        break;
      case OtpTokenType.HOTP:
        code = OTP.generateHOTPCodeString(
          widget.token.secret,
          widget.token.counter,
          length: widget.token.digits.digit,
          algorithm: widget.token.algorithm.algorithm,
          isGoogle: true,
        );
        break;
      case OtpTokenType.MOTP:
        code = MOTP(
          secret: widget.token.secret,
          pin: widget.token.pin,
        ).generate();
        break;
      case OtpTokenType.Steam:
        code = SteamTOTP(secret: widget.token.secret).generate();
        break;
      case OtpTokenType.Yandex:
        code = YandexOTP(
          pin: widget.token.pin,
          secret: widget.token.secret,
        ).generate();
        break;
    }
    return code;
  }

  getNextCode() {
    late String code;
    switch (widget.token.tokenType) {
      case OtpTokenType.TOTP:
        code = OTP.generateTOTPCodeString(
          widget.token.secret,
          DateTime.now().millisecondsSinceEpoch,
          length: widget.token.digits.digit,
          interval: widget.token.period,
          algorithm: widget.token.algorithm.algorithm,
          isGoogle: true,
        );
        break;
      case OtpTokenType.HOTP:
        code = OTP.generateHOTPCodeString(
          widget.token.secret,
          widget.token.counter + 1,
          length: widget.token.digits.digit,
          algorithm: widget.token.algorithm.algorithm,
          isGoogle: true,
        );
        break;
      case OtpTokenType.MOTP:
        code = MOTP(
          secret: widget.token.secret,
          pin: widget.token.pin,
          period: widget.token.period,
          digits: widget.token.digits.digit,
        ).generate(deltaMilliseconds: widget.token.period * 1000);
        break;
      case OtpTokenType.Steam:
        code = SteamTOTP(secret: widget.token.secret)
            .generate(deltaMilliseconds: 30000);
        break;
      case OtpTokenType.Yandex:
        code = YandexOTP(
          pin: widget.token.pin,
          secret: widget.token.secret,
        ).generate();
        break;
    }
    return code;
  }

  _buildContextMenuButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.copyTokenCode,
          onPressed: () {
            Utils.copy(context, getCurrentCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        ContextMenuButtonConfig(
          S.current.copyNextTokenCode,
          onPressed: () {
            Utils.copy(context, getNextCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig(S.current.editToken, onPressed: _processEdit),
        ContextMenuButtonConfig(
          widget.token.pinned ? S.current.unPinToken : S.current.pinToken,
          onPressed: () {
            TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
            IToast.showTop(
              widget.token.pinned
                  ? S.current.alreadyUnPinnedToken(getTitle())
                  : S.current.alreadyPinnedToken(getTitle()),
            );
            homeScreenState?.refresh();
          },
        ),
        ContextMenuButtonConfig(
          S.current.editTokenIcon,
          onPressed: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              (context) => SelectIconBottomSheet(
                token: widget.token,
                onSelected: (path) => {},
                doUpdate: true,
              ),
            );
          },
        ),
        ContextMenuButtonConfig(
          S.current.editTokenCategory,
          onPressed: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              (context) => SelectCategoryBottomSheet(token: widget.token),
            );
            homeScreenState?.refresh();
          },
        ),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig(S.current.viewTokenQrCode,
            onPressed: _processQrCode),
        ContextMenuButtonConfig(
          S.current.copyTokenUri,
          onPressed: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: "明文警告",
              message:
                  "你正在复制令牌的URI，你的令牌密钥将以明文形式暴露在文本中。除非你能确保该文本不会泄露，否则我们建议你导出为加密文件。",
              onTapConfirm: () {
                Utils.copy(context, OtpTokenParser.toUri(widget.token));
              },
              onTapCancel: () {},
              customDialogType: CustomDialogType.normal,
            );
          },
        ),
        ContextMenuButtonConfig.divider(),
        ContextMenuButtonConfig.warning(
          S.current.deleteToken,
          onPressed: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.deleteTokenTitle(getTitle()),
              message: S.current.deleteTokenMessage(getTitle()),
              onTapConfirm: () async {
                await TokenDao.deleteToken(widget.token);
                IToast.showTop(S.current.deleteTokenSuccess(getTitle()));
                homeScreenState?.refresh();
              },
              onTapCancel: () {},
              customDialogType: CustomDialogType.normal,
            );
          },
        ),
      ],
    );
  }

  _buildContextMenuRegion() {
    return ContextMenuRegion(
      behavior: ResponsiveUtil.isDesktop()
          ? const [ContextMenuShowBehavior.secondaryTap]
          : const [],
      contextMenu: _buildContextMenuButtons(),
      child: _buildBody(),
    );
  }

  getTitle() {
    return "${widget.token.issuer}:${widget.token.account}";
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
    context.contextMenuOverlay.show(_buildContextMenuButtons());
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
          onTap: () {
            setState(() {
              _showCode = true;
            });
            if (HiveUtil.getBool(HiveUtil.clickToCopyKey)) {
              if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
                  currentProgress < _autoCopyNextCodeProgressThrehold) {
                Utils.copy(context, getNextCode(),
                    toastText: S.current.alreadyCopiedNextCode);
                TokenDao.incTokenCopyTimes(widget.token);
              } else {
                Utils.copy(context, getCurrentCode());
                TokenDao.incTokenCopyTimes(widget.token);
              }
            }
          },
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
                Text(
                  _showCode
                      ? getCurrentCode()
                      : "*" * widget.token.digits.digit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        letterSpacing: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: currentProgress,
                  minHeight: 1,
                  color: currentProgress > _autoCopyNextCodeProgressThrehold
                      ? Theme.of(context).primaryColor
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildDetailLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: widget.token.pinned
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            setState(() {
              _showCode = true;
            });
            if (HiveUtil.getBool(HiveUtil.clickToCopyKey)) {
              if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
                  currentProgress < _autoCopyNextCodeProgressThrehold) {
                Utils.copy(context, getNextCode(),
                    toastText: S.current.alreadyCopiedNextCode);
                TokenDao.incTokenCopyTimes(widget.token);
              } else {
                Utils.copy(context, getCurrentCode());
                TokenDao.incTokenCopyTimes(widget.token);
              }
            }
          },
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
                    Expanded(
                      child: Text(
                        _showCode
                            ? getCurrentCode()
                            : placeholderText * widget.token.digits.digit,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                  letterSpacing: 5,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
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
                LinearProgressIndicator(
                  value: currentProgress,
                  minHeight: 1,
                  color: currentProgress > _autoCopyNextCodeProgressThrehold
                      ? Theme.of(context).primaryColor
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _processQrCode() {
    DialogBuilder.showInfoDialog(
      context,
      title: getTitle(),
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

  _processEdit() {
    if (ResponsiveUtil.isLandscape()) {
      DialogBuilder.showPageDialog(
        context,
        child: AddTokenScreen(token: widget.token),
        showClose: false,
      );
    } else {
      RouteUtil.pushCupertinoRoute(
        context,
        AddTokenScreen(token: widget.token),
      );
    }
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
          onTap: () {
            setState(() {
              _showCode = true;
            });
            if (HiveUtil.getBool(HiveUtil.clickToCopyKey)) {
              if (HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey) &&
                  currentProgress < _autoCopyNextCodeProgressThrehold) {
                Utils.copy(context, getNextCode(),
                    toastText: S.current.alreadyCopiedNextCode);
                TokenDao.incTokenCopyTimes(widget.token);
              } else {
                Utils.copy(context, getCurrentCode());
                TokenDao.incTokenCopyTimes(widget.token);
              }
            }
          },
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
                    ItemBuilder.buildTokenImage(widget.token, size: 40),
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
                        onTap: _processQrCode),
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
                  children: [
                    Flexible(
                      child: Text(
                        _showCode
                            ? getCurrentCode()
                            : placeholderText * widget.token.digits.digit,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                  letterSpacing: 5,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          _showCode ? getNextCode() : "",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    letterSpacing: 5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.color,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: currentProgress,
                  minHeight: 1,
                  color: currentProgress > _autoCopyNextCodeProgressThrehold
                      ? Theme.of(context).primaryColor
                      : Colors.red,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
