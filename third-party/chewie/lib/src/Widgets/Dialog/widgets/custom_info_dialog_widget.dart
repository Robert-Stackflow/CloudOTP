import 'dart:ui';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Widgets/Component/custom_html_widget.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/colors.dart';
import 'package:awesome_chewie/src/Widgets/Dialog/custom_dialog.dart';

class CustomInfoDialogWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? messageChild;
  final String? imagePath;
  final String buttonText;
  final VoidCallback onTapDismiss;
  final CustomDialogType customDialogType;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? buttonTextColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final TextAlign? messageTextAlign;
  final bool roundbottom;
  final bool roundTop;

  /// If you don't want any icon or image, you toggle it to true.
  final bool renderHtml;

  final Alignment align;

  const CustomInfoDialogWidget({
    super.key,
    this.title,
    this.message,
    this.messageChild,
    required this.buttonText,
    required this.onTapDismiss,
    required this.customDialogType,
    this.textColor = const Color(0xFF707070),
    this.color = const Color(0xFF179DFF),
    this.backgroundColor,
    this.buttonTextColor,
    this.imagePath,
    this.padding,
    this.margin,
    required this.renderHtml,
    this.align = Alignment.bottomCenter,
    this.messageTextAlign = TextAlign.center,
    this.roundTop = true,
    this.roundbottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ResponsiveUtil.isDesktop()
          ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(roundbottom ? ChewieDimens.dimen8 : 0),
                top: Radius.circular(roundTop ? ChewieDimens.dimen8 : 0),
              ),
              border: ChewieTheme.border,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (title != null) ...[
                  Text(
                    title ?? "",
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
                          content: message!,
                          style: TextStyle(
                            color: textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        )
                      : Text(
                          message!,
                          style: TextStyle(
                            color: textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign: messageTextAlign,
                        ),
                if (messageChild != null) messageChild!,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RoundIconTextButton(
                        color: buttonTextColor ?? Colors.white,
                        text: buttonText,
                        fontSizeDelta: 2,
                        height: 48,
                        onPressed: () {
                          onTapDismiss.call();
                          Navigator.pop(context);
                        },
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
