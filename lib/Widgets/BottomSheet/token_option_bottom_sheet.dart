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
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/asset_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../Database/token_dao.dart';
import '../../Screens/Token/add_token_screen.dart';
import '../../Screens/Token/token_layout.dart';
import '../../TokenUtils/code_generator.dart';
import '../../TokenUtils/otp_token_parser.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../l10n/l10n.dart';
import '../cloudotp/cloudotp_item_builder.dart';

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

class TokenOptionBottomSheetState
    extends BaseDynamicState<TokenOptionBottomSheet> {
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

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
                top: radius,
                bottom:
                    ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.border,
            boxShadow: ChewieTheme.defaultBoxShadow,
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
          CloudOTPItemBuilder.buildTokenImage(widget.token, size: 36),
          const SizedBox(width: 12),
          ClickableGestureDetector(
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
                    style: ChewieTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      letterSpacing: 10,
                      color: ChewieTheme.primaryColor,
                    ),
                    maxLines: 1,
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
                    ? CircleIconButton(
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
                          color: ChewieTheme.bodyMedium.color,
                        ),
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
                            color: value > autoCopyNextCodeProgressThrehold
                                ? ChewieTheme.primaryColor
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
          leading: LucideIcons.copy,
          title: appLocalizations.copyTokenCode,
          onTap: () {
            Navigator.pop(context);
            ChewieUtils.copy(context, getCurrentCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        _buildItem(
          leading: LucideIcons.copySlash,
          title: appLocalizations.copyNextTokenCode,
          onTap: () {
            Navigator.pop(context);
            ChewieUtils.copy(context, getNextCode());
            TokenDao.incTokenCopyTimes(widget.token);
          },
        ),
        _buildItem(
          leading: LucideIcons.pencilLine,
          title: appLocalizations.editToken,
          onTap: () {
            Navigator.pop(context);
            RouteUtil.pushDialogRoute(
                context, AddTokenScreen(token: widget.token));
          },
        ),
        _buildItem(
          leading: widget.token.pinned
              ? Icons.push_pin_rounded
              : Icons.push_pin_outlined,
          title: widget.token.pinned
              ? appLocalizations.unPinToken
              : appLocalizations.pinToken,
          titleColor: widget.token.pinned ? ChewieTheme.primaryColor : null,
          leadingColor: widget.token.pinned ? ChewieTheme.primaryColor : null,
          onTap: () async {
            Navigator.pop(context);
            await TokenDao.updateTokenPinned(
                widget.token, !widget.token.pinned);
            IToast.showTop(
              widget.token.pinned
                  ? appLocalizations.alreadyPinnedToken(widget.token.title)
                  : appLocalizations.alreadyUnPinnedToken(widget.token.title),
            );
            homeScreenState?.updateToken(widget.token,
                pinnedStateChanged: true);
          },
        ),
        _buildItem(
          leading: LucideIcons.qrCode,
          title: appLocalizations.viewTokenQrCode,
          onTap: () {
            Navigator.pop(context);
            CloudOTPItemBuilder.showQrcodesDialog(
              context,
              title: widget.token.title,
              qrcodes: [OtpTokenParser.toUri(widget.token).toString()],
              asset: AssetFiles.getBrandPath(widget.token.imagePath),
            );
          },
        ),
        _buildItem(
          leading: LucideIcons.text,
          title: appLocalizations.copyTokenUri,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.copyUriClearWarningTitle,
              message: appLocalizations.copyUriClearWarningTip,
              onTapConfirm: () {
                ChewieUtils.copy(context, OtpTokenParser.toUri(widget.token));
                Navigator.pop(context);
              },
              onTapCancel: () {},
            );
          },
        ),
        _buildItem(
          leading: LucideIcons.shapes,
          title: appLocalizations.editTokenCategory,
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
          leading: LucideIcons.blend,
          title: appLocalizations.editTokenIcon,
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
            title: appLocalizations.currentCounter(widget.token.counter),
            onTap: () {},
          ),
        _buildItem(
          leading: LucideIcons.squarePercent,
          title: appLocalizations.currentCopyTimes(widget.token.copyTimes),
          onTap: () {},
        ),
        _buildItem(
          leading: LucideIcons.rotateCcw,
          title: appLocalizations.resetCopyTimes,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.resetCopyTimesTitle,
              message:
                  appLocalizations.resetCopyTimesMessage(widget.token.title),
              onTapConfirm: () async {
                await TokenDao.resetSingleTokenCopyTimes(widget.token);
                homeScreenState?.resetCopyTimesSingle(widget.token);
                IToast.showTop(appLocalizations.resetSuccess);
                setState(() {});
                Navigator.pop(context);
              },
              onTapCancel: () {},
            );
          },
        ),
        _buildItem(
          leading: LucideIcons.trash2,
          title: appLocalizations.deleteToken,
          titleColor: Colors.red,
          leadingColor: Colors.red,
          onTap: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.deleteTokenTitle(widget.token.title),
              message: appLocalizations.deleteTokenMessage(widget.token.title),
              onTapConfirm: () async {
                TokenDao.deleteToken(widget.token).then((value) {
                  IToast.showTop(
                      appLocalizations.deleteTokenSuccess(widget.token.title));
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
    return PressableAnimation(
      child: Material(
        color: backgroundColor ?? ChewieTheme.cardColor,
        borderRadius: ChewieDimens.defaultBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ChewieDimens.defaultBorderRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                borderRadius: ChewieDimens.defaultBorderRadius),
            child: Column(
              children: [
                Icon(
                  leading,
                  size: 24,
                  color: leadingColor ?? ChewieTheme.bodyMedium.color,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: AutoSizeText(
                    title,
                    maxLines: 1,
                    style: ChewieTheme.bodyMedium.copyWith(
                        color: titleColor ?? ChewieTheme.bodyMedium.color),
                  ),
                ),
              ],
            ),
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
