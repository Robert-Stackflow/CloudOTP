import 'package:flutter/material.dart';

import '../../../Utils/asset_util.dart';
import '../../../Utils/utils.dart';
import '../colors.dart';
import '../custom_dialog.dart';
import '../widgets/custom_dialog_button.dart';

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

  /// If you don't want any icon or image, you toggle it to true.
  final bool noImage;

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
    required this.noImage,
    this.align = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
            color: backgroundColor ?? theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!noImage)
                Image.asset(
                  imagePath ?? AssetUtil.infoIcon,
                  package: imagePath != null ? null : 'panara_dialogs',
                  width: 84,
                  height: 84,
                  color: imagePath != null
                      ? null
                      : CustomDialogColors.getBgColor(
                          context,
                          customDialogType,
                          color,
                        ),
                ),
              if (!noImage) const SizedBox(height: 24),
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
                Text(
                  message!,
                  style: TextStyle(
                    color: textColor ??
                        Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.start,
                ),
              if (messageChild != null) messageChild!,
              const SizedBox(height: 15),
              CustomDialogButton(
                buttonTextColor: buttonTextColor ?? Colors.white,
                text: buttonText,
                onTap: () {
                  onTapDismiss.call();
                  Navigator.pop(context);
                },
                bgColor: CustomDialogColors.getBgColor(
                  context,
                  customDialogType,
                  color ?? Theme.of(context).primaryColor,
                ),
                isOutlined: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
