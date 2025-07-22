import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

enum TipBannerType { info, success, warning, error }

class TipBanner extends StatelessWidget {
  final String message;
  final TipBannerType type;
  final IconData? customIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry margin;

  const TipBanner({
    super.key,
    required this.message,
    this.type = TipBannerType.info,
    this.customIcon,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.symmetric(horizontal: 8),
  });

  factory TipBanner.info(
    String message, {
    Key? key,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return TipBanner(
      key: key,
      message: message,
      type: TipBannerType.info,
      customIcon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  factory TipBanner.success(
    String message, {
    Key? key,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return TipBanner(
      key: key,
      message: message,
      type: TipBannerType.success,
      customIcon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  factory TipBanner.warning(
    String message, {
    Key? key,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return TipBanner(
      key: key,
      message: message,
      type: TipBannerType.warning,
      customIcon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  factory TipBanner.error(
    String message, {
    Key? key,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return TipBanner(
      key: key,
      message: message,
      type: TipBannerType.error,
      customIcon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<TipBannerType, Color> defaultLightColors = {
      TipBannerType.info: Colors.blue.shade50,
      TipBannerType.success: Colors.green.shade50,
      TipBannerType.warning: Colors.orange.shade50,
      TipBannerType.error: Colors.red.shade50,
    };

    final Map<TipBannerType, Color> defaultDarkColors = {
      TipBannerType.info: Colors.blue.shade900.withOpacity(0.2),
      TipBannerType.success: Colors.green.shade900.withOpacity(0.2),
      TipBannerType.warning: Colors.orange.shade900.withOpacity(0.2),
      TipBannerType.error: Colors.red.shade900.withOpacity(0.2),
    };

    final Map<TipBannerType, Color> defaultLightTextColors = {
      TipBannerType.info: Colors.blue.shade700,
      TipBannerType.success: Colors.green.shade700,
      TipBannerType.warning: Colors.orange.shade700,
      TipBannerType.error: Colors.red.shade700,
    };

    final Map<TipBannerType, Color> defaultDarkTextColors = {
      TipBannerType.info: Colors.blue.shade100,
      TipBannerType.success: Colors.green.shade100,
      TipBannerType.warning: Colors.orange.shade100,
      TipBannerType.error: Colors.red.shade100,
    };

    final bool isDark = ColorUtil.isDark(context);

    final background = backgroundColor ??
        (isDark ? defaultDarkColors[type]! : defaultLightColors[type]!);
    final text = textColor ??
        (isDark ? defaultDarkTextColors[type]! : defaultLightTextColors[type]!);

    final Map<TipBannerType, IconData> defaultIcons = {
      TipBannerType.info: LucideIcons.info,
      TipBannerType.success: LucideIcons.circleCheck,
      TipBannerType.warning: LucideIcons.triangleAlert,
      TipBannerType.error: LucideIcons.circleX,
    };

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? background,
        borderRadius: ChewieDimens.borderRadius8,
      ),
      child: Row(
        children: [
          Icon(
            customIcon ?? defaultIcons[type],
            color: text,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: text,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
