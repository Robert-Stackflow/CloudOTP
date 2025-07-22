import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class CustomInfoDialogWidget extends StatefulWidget {
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
  State<CustomInfoDialogWidget> createState() => _CustomInfoDialogWidgetState();
}

class _CustomInfoDialogWidgetState
    extends BaseDynamicState<CustomInfoDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ResponsiveUtil.isDesktop()
          ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
          : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Align(
        alignment: widget.align,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: ResponsiveUtil.isWideDevice()
                ? const BoxConstraints(maxWidth: 400)
                : null,
            margin: widget.margin ?? const EdgeInsets.all(16),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ?? ChewieTheme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                    widget.roundbottom ? ChewieDimens.dimen16 : 0),
                top:
                    Radius.circular(widget.roundTop ? ChewieDimens.dimen16 : 0),
              ),
              border: ChewieTheme.border,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.title != null) ...[
                  Text(
                    widget.title ?? "",
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.message.notNullOrEmpty)
                  widget.renderHtml
                      ? CustomHtmlWidget(
                          content: widget.message!,
                          style: TextStyle(
                            color:
                                widget.textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        )
                      : Text(
                          widget.message!,
                          style: TextStyle(
                            color:
                                widget.textColor ?? ChewieTheme.bodySmall.color,
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign: widget.messageTextAlign,
                        ),
                if (widget.messageChild != null) widget.messageChild!,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RoundIconTextButton(
                        color: widget.buttonTextColor ?? Colors.white,
                        text: widget.buttonText,
                        fontSizeDelta: 2,
                        height: 48,
                        onPressed: () {
                          widget.onTapDismiss.call();
                          Navigator.pop(context);
                        },
                        background: CustomDialogColors.getBgColor(
                          context,
                          widget.customDialogType,
                          widget.color ?? ChewieTheme.primaryColor,
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
