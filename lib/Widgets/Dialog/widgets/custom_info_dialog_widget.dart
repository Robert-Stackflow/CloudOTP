import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../../Utils/utils.dart';
import '../colors.dart';
import '../custom_dialog.dart';

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
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.all(24),
    required this.renderHtml,
    this.align = Alignment.bottomCenter,
    this.messageTextAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Align(
      alignment: align,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 340,
          ),
          margin: margin ?? const EdgeInsets.all(24),
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor ?? MyTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (title != null)
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
              if (Utils.isNotEmpty(title)) const SizedBox(height: 20),
              if (Utils.isNotEmpty(message))
                renderHtml
                    ? ItemBuilder.buildHtmlWidget(
                        context,
                        message!,
                        textStyle: TextStyle(
                          color: textColor ??
                              Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      )
                    : Text(
                        message!,
                        style: TextStyle(
                          color: textColor ??
                              Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.5,
                          fontSize: 15,
                        ),
                        textAlign: messageTextAlign,
                      ),
              if (messageChild != null) messageChild!,
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ItemBuilder.buildRoundButton(
                      context,
                      color: buttonTextColor ?? Colors.white,
                      text: buttonText,
                      fontSizeDelta: 2,
                      onTap: () {
                        onTapDismiss.call();
                        Navigator.pop(context);
                      },
                      background: CustomDialogColors.getBgColor(
                        context,
                        customDialogType,
                        color ?? Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
