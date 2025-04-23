import 'dart:ui';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Widgets/Component/custom_html_widget.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/colors.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';

class CustomConfirmDialogWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? imagePath;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onTapConfirm;
  final VoidCallback onTapCancel;
  final CustomDialogType customDialogType;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? buttonTextColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? radiusDimen;
  final TextAlign? messageTextAlign;

  final bool renderHtml;

  final Alignment align;

  const CustomConfirmDialogWidget({
    super.key,
    this.title,
    required this.message,
    required this.confirmButtonText,
    required this.cancelButtonText,
    required this.onTapConfirm,
    required this.onTapCancel,
    required this.customDialogType,
    this.color,
    this.backgroundColor,
    this.textColor = const Color(0xFF707070),
    this.buttonTextColor = Colors.white,
    this.imagePath,
    this.padding,
    this.margin,
    required this.renderHtml,
    this.radiusDimen,
    this.align = Alignment.bottomCenter,
    this.messageTextAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Align(
        alignment: align,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: ResponsiveUtil.isWideLandscape()
                ? const BoxConstraints(maxWidth: 400)
                : null,
            margin: margin ?? const EdgeInsets.all(16),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: backgroundColor ?? ChewieTheme.scaffoldBackgroundColor,
              borderRadius:
                  BorderRadius.circular(radiusDimen ?? ChewieDimens.dimen8),
              border: ChewieTheme.border,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (title.notNullOrEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                if (message.notNullOrEmpty)
                  renderHtml
                      ? CustomHtmlWidget(
                          content: message,
                          style: TextStyle(
                            color: textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        )
                      : Text(
                          message,
                          style: TextStyle(
                            color: textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign: messageTextAlign,
                        ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: RoundIconTextButton(
                        fontSizeDelta: 2,
                        color: ChewieTheme.errorColor,
                        height: 48,
                        onPressed: () {
                          onTapCancel.call();
                          Navigator.pop(context);
                        },
                        text: cancelButtonText,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: RoundIconTextButton(
                        color:
                            buttonTextColor ?? ChewieTheme.primaryButtonColor,
                        fontSizeDelta: 2,
                        height: 48,
                        onPressed: () {
                          Navigator.pop(context);
                          onTapConfirm.call();
                        },
                        text: confirmButtonText,
                        background: CustomDialogColors.getBgColor(
                          context,
                          customDialogType,
                          color ?? ChewieTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
