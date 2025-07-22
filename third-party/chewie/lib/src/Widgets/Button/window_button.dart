import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

typedef WindowButtonIconBuilder = Widget Function(
    WindowButtonContext buttonContext);
typedef WindowButtonBuilder = Widget Function(
    WindowButtonContext buttonContext, Widget icon);

class WindowButtonContext {
  BuildContext context;
  MouseState mouseState;
  Color? backgroundColor;
  Color iconColor;

  WindowButtonContext({
    required this.context,
    required this.mouseState,
    this.backgroundColor,
    required this.iconColor,
  });
}

class WindowButtonColors {
  late Color normal;
  late Color selected;
  late Color mouseOver;
  late Color mouseDown;
  late Color iconNormal;
  late Color iconSelected;
  late Color iconMouseOver;
  late Color iconMouseDown;

  WindowButtonColors({
    Color? normal,
    Color? selected,
    Color? mouseOver,
    Color? mouseDown,
    Color? iconNormal,
    Color? iconSelected,
    Color? iconMouseOver,
    Color? iconMouseDown,
  }) {
    this.normal = normal ?? _defaultButtonColors.normal;
    this.selected = selected ?? _defaultButtonColors.selected;
    this.mouseOver = mouseOver ?? _defaultButtonColors.mouseOver;
    this.mouseDown = mouseDown ?? _defaultButtonColors.mouseDown;
    this.iconNormal = iconNormal ?? _defaultButtonColors.iconNormal;
    this.iconSelected = iconSelected ?? _defaultButtonColors.iconSelected;
    this.iconMouseOver = iconMouseOver ?? _defaultButtonColors.iconMouseOver;
    this.iconMouseDown = iconMouseDown ?? _defaultButtonColors.iconMouseDown;
  }
}

final _defaultButtonColors = WindowButtonColors(
  normal: Colors.transparent,
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFF404040),
  mouseDown: const Color(0xFF202020),
  iconMouseOver: const Color(0xFFFFFFFF),
  iconMouseDown: const Color(0xFFF0F0F0),
  selected: const Color(0xFF202020),
  iconSelected: const Color(0xFF805306),
);

class WindowButton extends StatelessWidget {
  final WindowButtonBuilder? builder;
  final WindowButtonIconBuilder? iconBuilder;
  late final WindowButtonColors colors;
  final bool enableAnimation;
  final bool enablePressedAnimation;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;
  final double rotateTurns;
  final bool selected;
  final Size buttonSize;
  final String? tooltip;
  final TooltipPosition? tooltipPosition;

  WindowButton({
    super.key,
    WindowButtonColors? colors,
    this.builder,
    required this.iconBuilder,
    this.padding,
    this.selected = false,
    this.onPressed,
    this.buttonSize = const Size(36, 36),
    this.borderRadius,
    this.enableAnimation = false,
    this.enablePressedAnimation = true,
    this.rotateTurns = 0,
    this.tooltip,
    this.tooltipPosition,
  }) {
    this.colors = colors ?? _defaultButtonColors;
  }

  Color getBackgroundColor(MouseState mouseState) {
    if (mouseState.isMouseDown) return colors.mouseDown;
    if (mouseState.isMouseOver) return colors.mouseOver;
    if (selected) return colors.selected;
    return colors.normal;
  }

  Color getIconColor(MouseState mouseState) {
    if (selected) return colors.iconSelected;
    if (mouseState.isMouseDown) return colors.iconMouseDown;
    if (mouseState.isMouseOver) return colors.iconMouseOver;
    return colors.iconNormal;
  }

  Widget buildAnimatedIcon(Widget icon, MouseState mouseState) {
    final rotateIcon = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: rotateTurns),
      duration: 200.ms,
      curve: Curves.easeInOut,
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle * pi,
          child: child,
        );
      },
      child: icon,
    );

    if (!enableAnimation) return rotateIcon;

    final hoverAnimated = rotateIcon
        .animate(
          target: mouseState.isMouseOver ? 1 : 0,
          autoPlay: true,
        )
        .scaleXY(
          end: 1.05,
          duration: 150.ms,
          curve: Curves.easeInOut,
        )
        .fade(
          end: 1.0,
          duration: 150.ms,
          curve: Curves.easeInOut,
        );

    final selectedAnimated = hoverAnimated
        .animate(
          target: selected ? 1 : 0,
          autoPlay: true,
        )
        .scaleXY(
          begin: selected ? 0 : 1.0,
          end: selected ? 1.05 : 1.0,
          duration: 300.ms,
          curve: Curves.easeInOutBack,
        );

    return selectedAnimated;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return emptyWidget;
    } else {
      if (Platform.isMacOS) {
        return emptyWidget;
      }
    }
    var widget = MouseStateBuilder(
      builder: (context, mouseState) {
        WindowButtonContext buttonContext = WindowButtonContext(
          mouseState: mouseState,
          context: context,
          backgroundColor: getBackgroundColor(mouseState),
          iconColor: getIconColor(mouseState),
        );

        var icon =
            (iconBuilder != null) ? iconBuilder!(buttonContext) : emptyWidget;
        double borderSize = 0;
        double defaultPadding = (30 - borderSize) / 3 - (borderSize / 2);
        var padding = this.padding ?? EdgeInsets.all(defaultPadding);
        Widget iconWithPadding = Container(
          padding: padding,
          color: buttonContext.backgroundColor,
          child: buildAnimatedIcon(icon, mouseState),
        );
        var button =
            (builder != null) ? builder!(buttonContext, icon) : iconWithPadding;
        var animatedButton = PressableAnimation(
          onTap: onPressed,
          scaleFactor: enablePressedAnimation ? 0.02 : 0,
          child: button,
        );
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: SizedBox(
              width: buttonSize.width,
              height: buttonSize.height,
              child: InkAnimation(
                borderRadius: borderRadius ?? BorderRadius.zero,
                color: Colors.transparent,
                onTap: () {
                  if (onPressed != null) onPressed!();
                },
                child: animatedButton,
              ),
            ),
          ),
        );
      },
      onPressed: () {
        // Handle onPressed if necessary
      },
    );

    return ToolTipWrapper(
      message: tooltip,
      position: tooltipPosition,
      child: widget,
    );
  }
}

class ToolButton extends WindowButton {
  ToolButton({
    super.key,
    required BuildContext context,
    super.selected,
    WindowButtonColors? colors,
    super.onPressed,
    EdgeInsets? padding,
    WindowButtonIconBuilder? iconBuilder,
    IconData? icon,
    IconData? selectedIcon,
    double iconSize = 22,
    Size? buttonSize,
    double? rotateTurns,
    BorderRadius? borderRadius,
    super.enableAnimation = true,
    super.enablePressedAnimation = true,
    super.tooltip,
    super.tooltipPosition,
  }) : super(
          buttonSize: buttonSize ?? const Size(38, 38),
          padding: padding ?? EdgeInsets.zero,
          colors: colors ?? ChewieColors.getNormalButtonColors(context),
          borderRadius: borderRadius ?? ChewieDimens.borderRadius8,
          iconBuilder: iconBuilder ??
              (buttonContext) => Transform.rotate(
                    angle: rotateTurns ?? 0,
                    child: Icon(
                      selected ? selectedIcon ?? icon : icon,
                      color: buttonContext.iconColor,
                      size: iconSize,
                    ),
                  ),
        );

  static Widget dynamicButton({
    required IconData Function(BuildContext context, bool isDark)? iconBuilder,
    required VoidCallback onTap,
    Function(BuildContext context, dynamic value, Widget? child)? onChangemode,
    String? tooltip,
    TooltipPosition? tooltipPosition,
    double iconSize = 24,
  }) {
    return Selector<ChewieProvider, ActiveThemeMode>(
      selector: (context, chewieProvider) => chewieProvider.themeMode,
      builder: (context, themeMode, child) {
        onChangemode?.call(context, themeMode, child);
        return ToolButton(
          context: context,
          icon: iconBuilder?.call(context, themeMode == ActiveThemeMode.dark),
          onPressed: onTap,
          tooltip: tooltip,
          padding: const EdgeInsets.all(8),
          tooltipPosition: tooltipPosition,
          iconSize: iconSize,
        );
      },
    );
  }
}

class StayOnTopWindowButton extends WindowButton {
  StayOnTopWindowButton({
    super.key,
    super.colors,
    super.onPressed,
    double iconSize = 22,
    super.buttonSize,
    super.borderRadius,
    required BuildContext context,
    double? rotateTurns,
  }) : super(
          enableAnimation: false,
          padding: EdgeInsets.zero,
          rotateTurns: rotateTurns ?? 0,
          iconBuilder: (buttonContext) => Icon(
            rotateTurns == 0 ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: buttonContext.iconColor,
            size: iconSize,
          ),
        );
}

class MinimizeWindowButton extends WindowButton {
  MinimizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            enableAnimation: animate ?? false,
            padding: EdgeInsets.zero,
            iconBuilder: (buttonContext) => Icon(Icons.horizontal_rule_rounded,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => windowManager.minimize());
}

class MaximizeWindowButton extends WindowButton {
  MaximizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            padding: EdgeInsets.zero,
            enableAnimation: animate ?? false,
            iconBuilder: (buttonContext) => Icon(
                Icons.check_box_outline_blank_rounded,
                size: 19,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => ResponsiveUtil.maximizeOrRestore());
}

class RestoreWindowButton extends WindowButton {
  RestoreWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    super.borderRadius,
    bool? animate,
  }) : super(
            padding: EdgeInsets.zero,
            enableAnimation: animate ?? false,
            iconBuilder: (buttonContext) => Icon(Icons.fullscreen_exit_rounded,
                color: buttonContext.iconColor),
            onPressed: onPressed ?? () => ResponsiveUtil.maximizeOrRestore());
}

final _defaultCloseButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: const Color(0xFFFFFFFF));

class CloseWindowButton extends WindowButton {
  CloseWindowButton({
    super.key,
    WindowButtonColors? colors,
    VoidCallback? onPressed,
    super.borderRadius,
    super.buttonSize,
    double iconSize = 22,
    bool? animate,
  }) : super(
            colors: colors ?? _defaultCloseButtonColors,
            padding: EdgeInsets.zero,
            enableAnimation: animate ?? false,
            iconBuilder: (buttonContext) => Icon(Icons.close_rounded,
                size: iconSize, color: buttonContext.iconColor),
            onPressed: onPressed ?? () => windowManager.close());
}
