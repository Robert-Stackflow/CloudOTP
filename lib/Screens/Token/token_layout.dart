import 'dart:async';

import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:cloudotp/TokenUtils/otp_token_parser.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/TextDrawable/text_drawable_widget.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';

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
  double _remainProgress = 0.0;
  bool _showCode = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          int remain = OTP.remainingSeconds(interval: widget.token.period);
          double tmp = remain / widget.token.period;
          if (remain == 1) _showCode = false;
          _remainProgress = tmp;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildContextMenuRegion();
  }

  getCurrentCode() {
    String code = OTP.generateTOTPCodeString(
      widget.token.secret,
      DateTime.now().millisecondsSinceEpoch - widget.token.period * 1000,
      length: widget.token.digits.digit,
      interval: widget.token.period,
      algorithm: widget.token.algorithm.algorithm,
      isGoogle: true,
    );
    return code;
  }

  getNextCode() {
    String code = OTP.generateTOTPCodeString(
      widget.token.secret,
      DateTime.now().millisecondsSinceEpoch,
      length: widget.token.digits.digit,
      interval: widget.token.period,
      algorithm: widget.token.algorithm.algorithm,
      isGoogle: true,
    );
    return code;
  }

  _buildContextMenuRegion() {
    return ContextMenuRegion(
      behavior: const [ContextMenuShowBehavior.secondaryTap],
      contextMenu: GenericContextMenu(
        buttonConfigs: [
          ContextMenuButtonConfig(
            "复制令牌",
            onPressed: () {
              Utils.copy(context, getCurrentCode());
            },
          ),
          ContextMenuButtonConfig(
            "复制下一个令牌",
            onPressed: () {
              Utils.copy(context, getNextCode());
            },
          ),
          ContextMenuButtonConfig.divider(),
          ContextMenuButtonConfig(
            "编辑详情",
            onPressed: () {
              DialogBuilder.showPageDialog(
                context,
                child: AddTokenScreen(token: widget.token),
                showClose: false,
              );
            },
          ),
          ContextMenuButtonConfig(
            widget.token.pinned ? "取消置顶" : "置顶令牌",
            onPressed: () {
              TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
              IToast.showTop(
                widget.token.pinned
                    ? "已取消置顶令牌${getTitle()}"
                    : "已置顶令牌${getTitle()}",
              );
              homeScreenState?.refresh();
            },
          ),
          ContextMenuButtonConfig(
            "更改图标",
            onPressed: () {
              homeScreenState?.refresh();
            },
          ),
          ContextMenuButtonConfig(
            "更改分类",
            onPressed: () {
              homeScreenState?.refresh();
            },
          ),
          ContextMenuButtonConfig.divider(),
          ContextMenuButtonConfig(
            "查看二维码",
            onPressed: () {
              DialogBuilder.showInfoDialog(
                context,
                buttonText: "确认",
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
            },
          ),
          ContextMenuButtonConfig(
            "复制URI",
            onPressed: () {
              Utils.copy(context, OtpTokenParser.toUri(widget.token));
            },
          ),
          ContextMenuButtonConfig.divider(),
          ContextMenuButtonConfig.warning(
            "删除令牌",
            onPressed: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: "删除令牌",
                message: "是否删除令牌${getTitle()}?",
                confirmButtonText: "确认",
                cancelButtonText: "取消",
                onTapConfirm: () {
                  TokenDao.deleteToken(widget.token);
                  IToast.showTop(
                    "已删除令牌${getTitle()}",
                  );
                  homeScreenState?.refresh();
                },
                onTapCancel: () {},
                customDialogType: CustomDialogType.normal,
              );
            },
          ),
        ],
      ),
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
      case LayoutType.Detail:
        return _buildDetailLayout();
    }
  }

  _buildSimpleLayout() {
    return ItemBuilder.buildClickItem(
      Material(
        color: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            setState(() {
              _showCode = !_showCode;
            });
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
                  _showCode ? getCurrentCode() : "******",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        letterSpacing: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _remainProgress,
                  minHeight: 1,
                  color: Theme.of(context).primaryColor,
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
        color: Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            setState(() {
              _showCode = !_showCode;
            });
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
                    TextDrawable(
                      text: widget.token.issuer,
                      boxShape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(5),
                      width: 32,
                      height: 32,
                    ),
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
                  _showCode ? getCurrentCode() : "******",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        letterSpacing: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _remainProgress,
                  minHeight: 1,
                  color: Theme.of(context).primaryColor,
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
