import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/WaterfallFlow/scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../Database/token_dao.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../TokenUtils/code_generator.dart';
import '../../TokenUtils/otp_token_parser.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Dialog/dialog_builder.dart';
import '../WaterfallFlow/sliver_waterfall_flow.dart';
import 'bottom_sheet_builder.dart';

class TokenOptionBottomSheet extends StatefulWidget {
  const TokenOptionBottomSheet({
    super.key,
    required this.token,
    this.forceShowCode,
  });

  final OtpToken token;
  final bool? forceShowCode;

  @override
  TokenOptionBottomSheetState createState() => TokenOptionBottomSheetState();
}

class TokenOptionBottomSheetState extends State<TokenOptionBottomSheet> {
  final ValueNotifier<double> _progressNotifier = ValueNotifier(1);
  final ValueNotifier<String> _codeNotifier = ValueNotifier("");
  final ValueNotifier<bool> _codeVisiableNotifier =
      ValueNotifier(!HiveUtil.getBool(HiveUtil.defaultHideCodeKey));
  Timer? _timer;

  int get remainingMilliseconds => widget.token.period == 0
      ? 0
      : widget.token.period * 1000 -
          (DateTime.now().millisecondsSinceEpoch %
              (widget.token.period * 1000));

  double get currentProgress => widget.token.period == 0
      ? 0
      : remainingMilliseconds / (widget.token.period * 1000);

  bool get isHOTP =>
      // ignore: unnecessary_null_comparison
      widget.token.tokenType == OtpTokenType.HOTP;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _codeNotifier.value = getCurrentCode();
    if (widget.forceShowCode != null) {
      _codeVisiableNotifier.value = widget.forceShowCode!;
    }
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        _progressNotifier.value = currentProgress;
        _codeNotifier.value = getCurrentCode();
        if (remainingMilliseconds <= 180 &&
            appProvider.autoHideCode &&
            widget.forceShowCode != true) {
          _codeVisiableNotifier.value = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            shrinkWrap: true,
            children: [
              _buildHeader(),
              _buildPrimaryButtons(),
            ],
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ItemBuilder.buildTokenImage(widget.token, size: 36),
          const SizedBox(width: 12),
          ItemBuilder.buildClickItem(
            GestureDetector(
              onTap: () {
                _codeVisiableNotifier.value = !_codeVisiableNotifier.value;
                HapticFeedback.lightImpact();
              },
              child: ValueListenableBuilder(
                valueListenable: _codeVisiableNotifier,
                builder: (context, value, child) {
                  return ValueListenableBuilder(
                    valueListenable: _codeNotifier,
                    builder: (context, value, child) {
                      return AutoSizeText(
                        _codeVisiableNotifier.value
                            ? _codeNotifier.value
                            : "*" * widget.token.digits.digit,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                  letterSpacing: 10,
                                  color: Theme.of(context).primaryColor,
                                ),
                        maxLines: 1,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          if (!isHOTP)
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _progressNotifier,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: _progressNotifier.value,
                        color: _progressNotifier.value >
                                autoCopyNextCodeProgressThrehold
                            ? Theme.of(context).primaryColor
                            : Colors.red,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                      );
                    },
                  ),
                  Center(
                    child: ValueListenableBuilder(
                      valueListenable: _progressNotifier,
                      builder: (context, value, child) {
                        return Text(
                          (remainingMilliseconds / 1000).toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodyMedium?.apply(
                                color: currentProgress >
                                        autoCopyNextCodeProgressThrehold
                                    ? Theme.of(context).primaryColor
                                    : Colors.red,
                                fontWeightDelta: 2,
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  _buildPrimaryButtons() {
    return WaterfallFlow(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 16),
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      children: [
        _buildItem(
          leading: Icons.copy_rounded,
          title: S.current.copyTokenCode,
          onTap: () {
            Navigator.pop(context);
            Utils.copy(context, getCurrentCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        _buildItem(
          leading: Icons.content_copy_rounded,
          title: S.current.copyNextTokenCode,
          onTap: () {
            Navigator.pop(context);
            Utils.copy(context, getNextCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        _buildItem(
          leading: Icons.edit_rounded,
          title: S.current.editToken,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushDialogRoute(
                context, AddTokenScreen(token: widget.token),
                showClose: false);
          },
        ),
        _buildItem(
          leading: widget.token.pinned
              ? Icons.push_pin_rounded
              : Icons.push_pin_outlined,
          title:
              widget.token.pinned ? S.current.unPinToken : S.current.pinToken,
          titleColor: widget.token.pinned ? Colors.green : null,
          leadingColor: widget.token.pinned ? Colors.green : null,
          onTap: () {
            Navigator.pop(context);
            TokenDao.updateTokenPinned(widget.token, !widget.token.pinned);
            IToast.showTop(
              widget.token.pinned
                  ? S.current.alreadyUnPinnedToken(widget.token.title)
                  : S.current.alreadyPinnedToken(widget.token.title),
            );
            homeScreenState?.refresh();
          },
        ),
        _buildItem(
          leading: Icons.qr_code_rounded,
          title: S.current.viewTokenQrCode,
          onTap: () {
            Navigator.pop(context);
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
          },
        ),
        _buildItem(
          leading: Icons.text_fields_rounded,
          title: S.current.copyTokenUri,
          onTap: () {
            Navigator.pop(context);
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.copyUriClearWarningTitle,
              message: S.current.copyUriClearWarningTip,
              onTapConfirm: () {
                Utils.copy(rootContext, OtpTokenParser.toUri(widget.token));
              },
              onTapCancel: () {},
            );
          },
        ),
        _buildItem(
          leading: Icons.category_outlined,
          title: S.current.editTokenCategory,
          onTap: () {
            Navigator.pop(context);
            BottomSheetBuilder.showBottomSheet(
              context,
              responsive: true,
              (context) => SelectCategoryBottomSheet(token: widget.token),
            );
            homeScreenState?.refresh();
          },
        ),
        _buildItem(
          leading: Icons.image_search_rounded,
          title: S.current.editTokenIcon,
          onTap: () {
            Navigator.pop(context);
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
        _buildItem(
          leading: Icons.delete_outline_rounded,
          title: S.current.deleteToken,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.deleteTokenTitle(widget.token.title),
              message: S.current.deleteTokenMessage(widget.token.title),
              onTapConfirm: () async {
                await TokenDao.deleteToken(widget.token);
                IToast.showTop(
                    S.current.deleteTokenSuccess(widget.token.title));
                homeScreenState?.refresh();
              },
              onTapCancel: () {},
            );
          },
        ),
      ],
    );
  }

  _buildItem({
    required IconData leading,
    required String title,
    Color? titleColor,
    Color? leadingColor,
    Function()? onTap,
  }) {
    return Material(
      color: Theme.of(context).canvasColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                leading,
                size: 24,
                color: leadingColor ??
                    Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: titleColor ??
                          Theme.of(context).textTheme.bodyMedium?.color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getCurrentCode() {
    return CodeGenerator.getCurrentCode(widget.token);
  }

  getNextCode() {
    return CodeGenerator.getNextCode(widget.token);
  }
}
