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
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Database/token_dao.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/token_layout.dart';
import '../../TokenUtils/code_generator.dart';
import '../../TokenUtils/otp_token_parser.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../Dialog/dialog_builder.dart';
import '../WaterfallFlow/scroll_view.dart';
import '../WaterfallFlow/sliver_waterfall_flow.dart';
import 'bottom_sheet_builder.dart';

class TokenOptionBottomSheet extends StatefulWidget {
  const TokenOptionBottomSheet({
    super.key,
    required this.token,
    this.isNewToken,
  });

  final OtpToken token;
  final bool? isNewToken;

  @override
  TokenOptionBottomSheetState createState() => TokenOptionBottomSheetState();
}

class TokenOptionBottomSheetState extends State<TokenOptionBottomSheet> {
  TokenLayoutNotifier tokenLayoutNotifier = TokenLayoutNotifier();

  final ValueNotifier<double> progressNotifier = ValueNotifier(0);
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
    updateCode();
    if (widget.isNewToken != null) {
      tokenLayoutNotifier.codeVisiable = widget.isNewToken!;
    }
    super.initState();
    resetTimer();
    progressNotifier.value = currentProgress;
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

  updateCode() {
    if (appProvider.autoDisplayNextCode &&
        currentProgress < autoCopyNextCodeProgressThrehold) {
      tokenLayoutNotifier.code = getNextCode();
    } else {
      tokenLayoutNotifier.code = getCurrentCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isWideLandscape()
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
                tokenLayoutNotifier.codeVisiable =
                    !tokenLayoutNotifier.codeVisiable;
                HapticFeedback.lightImpact();
              },
              child: ChangeNotifierProvider.value(
                value: tokenLayoutNotifier,
                child: Selector<TokenLayoutNotifier, bool>(
                  selector: (context, tokenLayoutNotifier) =>
                      tokenLayoutNotifier.codeVisiable,
                  builder: (context, codeVisiable, child) =>
                      Selector<TokenLayoutNotifier, String>(
                    selector: (context, tokenLayoutNotifier) =>
                        tokenLayoutNotifier.code,
                    builder: (context, code, child) => AutoSizeText(
                      codeVisiable
                          ? code
                          : (isHOTP ? hotpPlaceholderText : placeholderText) *
                              widget.token.digits.digit,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            letterSpacing: 10,
                            color: Theme.of(context).primaryColor,
                          ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (isHOTP)
            ChangeNotifierProvider.value(
              value: tokenLayoutNotifier,
              child: Selector<TokenLayoutNotifier, bool>(
                selector: (context, tokenLayoutNotifier) =>
                    tokenLayoutNotifier.haveToResetHOTP,
                builder: (context, haveToResetHOTP, child) => haveToResetHOTP
                    ? ItemBuilder.buildIconButton(
                        onTap: () {
                          widget.token.counterString =
                              (widget.token.counter + 1).toString();
                          TokenDao.updateTokenCounter(widget.token);
                          homeScreenState?.updateToken(widget.token,
                              counterChanged: true);
                          tokenLayoutNotifier.codeVisiable = true;
                          resetTimer();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        context: context,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          if (!isHOTP)
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                children: [
                  ValueListenableBuilder(
                    valueListenable: progressNotifier,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        color: value > autoCopyNextCodeProgressThrehold
                            ? Theme.of(context).primaryColor
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
                          style: Theme.of(context).textTheme.bodyMedium?.apply(
                                color: value > autoCopyNextCodeProgressThrehold
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
          leading: Icons.token_outlined,
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
          titleColor:
              widget.token.pinned ? Theme.of(context).primaryColor : null,
          leadingColor:
              widget.token.pinned ? Theme.of(context).primaryColor : null,
          onTap: () async {
            Navigator.pop(context);
            await TokenDao.updateTokenPinned(
                widget.token, !widget.token.pinned);
            IToast.showTop(
              widget.token.pinned
                  ? S.current.alreadyPinnedToken(widget.token.title)
                  : S.current.alreadyUnPinnedToken(widget.token.title),
            );
            homeScreenState?.updateToken(widget.token,
                pinnedStateChanged: true);
          },
        ),
        _buildItem(
          leading: Icons.qr_code_rounded,
          title: S.current.viewTokenQrCode,
          onTap: () {
            Navigator.pop(context);
            DialogBuilder.showQrcodesDialog(
              context,
              title: widget.token.title,
              qrcodes: [OtpTokenParser.toUri(widget.token).toString()],
              asset: AssetUtil.getBrandPath(widget.token.imagePath),
            );
          },
        ),
        _buildItem(
          leading: Icons.text_fields_rounded,
          title: S.current.copyTokenUri,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.copyUriClearWarningTitle,
              message: S.current.copyUriClearWarningTip,
              onTapConfirm: () {
                Utils.copy(rootContext, OtpTokenParser.toUri(widget.token));
                Navigator.pop(context);
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
        if (widget.token.tokenType == OtpTokenType.HOTP)
          _buildItem(
            leading: Icons.plus_one_rounded,
            title: S.current.currentCounter(widget.token.counter),
            onTap: () {},
          ),
        _buildItem(
          leading: Icons.calculate_outlined,
          title: S.current.currentCopyTimes(widget.token.copyTimes),
          onTap: () {},
        ),
        _buildItem(
          leading: Icons.repeat_one_rounded,
          title: S.current.resetCopyTimes,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.resetCopyTimesTitle,
              message: S.current.resetCopyTimesMessage(widget.token.title),
              onTapConfirm: () async {
                await TokenDao.resetSingleTokenCopyTimes(widget.token);
                homeScreenState?.resetCopyTimesSingle(widget.token);
                IToast.showTop(S.current.resetSuccess);
                setState(() {});
                Navigator.pop(context);
              },
              onTapCancel: () {},
            );
          },
        ),
        _buildItem(
          leading: Icons.delete_outline_rounded,
          title: S.current.deleteToken,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.deleteTokenTitle(widget.token.title),
              message: S.current.deleteTokenMessage(widget.token.title),
              onTapConfirm: () async {
                TokenDao.deleteToken(widget.token).then((value) {
                  IToast.showTop(
                      S.current.deleteTokenSuccess(widget.token.title));
                  homeScreenState?.removeToken(widget.token);
                });
                Navigator.pop(context);
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
    Color? backgroundColor,
    Function()? onTap,
  }) {
    return Material(
      color: backgroundColor ?? Theme.of(context).cardColor,
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
              SizedBox(
                height: 20,
                child: AutoSizeText(
                  title,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: titleColor ??
                            Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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
