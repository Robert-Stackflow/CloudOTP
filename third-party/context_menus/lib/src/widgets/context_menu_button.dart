import 'package:flutter/material.dart';

typedef Widget ContextMenuButtonBuilder(
  BuildContext context,
  ContextMenuButtonConfig config, [
  ContextMenuButtonStyle? style,
]);

/// The default ContextMenu button. To provide your own, override [ContextMenuOverlay] buttonBuilder.
/// TODO: This should use FocusableControlBuilder?
class ContextMenuButton extends StatefulWidget {
  const ContextMenuButton(
    this.config, {
    this.style,
    super.key,
  });

  final ContextMenuButtonConfig config;
  final ContextMenuButtonStyle? style;

  @override
  _ContextMenuButtonState createState() => _ContextMenuButtonState();
}

class _ContextMenuButtonState extends State<ContextMenuButton> {
  bool _isMouseOver = false;

  set isMouseOver(bool isMouseOver) {
    setState(() => _isMouseOver = isMouseOver);
  }

  ContextMenuButtonConfig get config => widget.config;

  @override
  Widget build(BuildContext context) {
    bool isDisabled = widget.config.onPressed == null;
    bool showMouseOver = _isMouseOver && !isDisabled;

    final ThemeData theme = Theme.of(context);
    Color defaultTextColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    TextStyle? defaultTextStyle = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSecondary);
    TextStyle? shortcutTextStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSecondary);

    ContextMenuButtonStyle style = ContextMenuButtonStyle(
      textStyle: widget.style?.textStyle ?? defaultTextStyle,
      shortcutTextStyle: widget.style?.shortcutTextStyle ?? shortcutTextStyle,
      fgColor: widget.style?.fgColor ?? defaultTextColor,
      bgColor: widget.style?.bgColor ?? Colors.transparent,
      hoverBgColor:
          widget.style?.hoverBgColor ?? theme.colorScheme.primaryContainer,
      hoverFgColor: widget.style?.hoverFgColor ?? theme.colorScheme.secondary,
      padding: widget.style?.padding ?? EdgeInsets.all(6),
    );

    /// Handling our own clicks
    return GestureDetector(
      onTapDown: (_) => isMouseOver = true,
      onTapUp: (_) {
        isMouseOver = false;
        widget.config.onPressed?.call();
      },
      child: MouseRegion(
        onEnter: (_) => isMouseOver = true,
        onExit: (_) => isMouseOver = false,
        cursor: !isDisabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Opacity(
          opacity: isDisabled ? style.disabledOpacity : 1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            color: showMouseOver ? style.hoverBgColor : style.bgColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Optional Icon
                if (config.icon != null) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: (showMouseOver)
                        ? config.iconHover ?? config.icon!
                        : config.icon!,
                  ),
                  SizedBox(width: 16)
                ],

                /// Main Label
                Text(
                  config.label,
                  style: style.textStyle!.copyWith(
                    color: showMouseOver ? style.hoverFgColor : style.fgColor,
                  ),
                ),
                Spacer(),

                /// Shortcut Label
                if (config.shortcutLabel != null) ...[
                  Opacity(
                    opacity: showMouseOver ? 1 : .7,
                    child: Text(
                      config.shortcutLabel!,
                      style: (style.shortcutTextStyle ?? style.textStyle!)
                          .copyWith(
                              color: showMouseOver
                                  ? style.hoverFgColor
                                  : style.fgColor),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContextMenuButtonStyle {
  const ContextMenuButtonStyle({
    this.fgColor,
    this.bgColor,
    this.hoverFgColor,
    this.hoverBgColor,
    this.padding,
    this.textStyle,
    this.shortcutTextStyle,
    this.disabledOpacity = 0.7,
  });

  final Color? fgColor;
  final Color? bgColor;
  final Color? hoverFgColor;
  final Color? hoverBgColor;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final TextStyle? shortcutTextStyle;
  final double disabledOpacity;

  ContextMenuButtonStyle copyWith({
    Color? fgColor,
    Color? bgColor,
    Color? hoverFgColor,
    Color? hoverBgColor,
    EdgeInsets? padding,
    TextStyle? textStyle,
    TextStyle? shortcutTextStyle,
    double disabledOpacity = 0.7,
  }) {
    return ContextMenuButtonStyle(
      fgColor: fgColor ?? this.fgColor,
      bgColor: bgColor ?? this.bgColor,
      hoverFgColor: hoverFgColor ?? this.hoverFgColor,
      hoverBgColor: hoverBgColor ?? this.hoverBgColor,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      disabledOpacity: disabledOpacity,
    );
  }
}

class ContextMenuButtonConfig {
  ContextMenuButtonConfig(
    this.label, {
    required this.onPressed,
    this.textColor,
    this.shortcutLabel,
    this.icon,
    this.checked = false,
    this.iconHover,
    this.type = ContextMenuButtonConfigType.normal,
  });

  ContextMenuButtonConfig.divider()
      : label = "",
        checked = false,
        textColor = null,
        type = ContextMenuButtonConfigType.divider,
        shortcutLabel = "",
        icon = null,
        iconHover = null,
        onPressed = null;

  ContextMenuButtonConfig.warning(
    this.label, {
    required this.onPressed,
    this.textColor,
    this.checked = false,
    this.shortcutLabel,
    this.icon,
    this.iconHover,
    this.type = ContextMenuButtonConfigType.warning,
  });

  ContextMenuButtonConfig.checkbox(
    this.label, {
    this.checked = false,
    this.textColor,
    required this.onPressed,
    this.shortcutLabel,
    this.icon,
    this.iconHover,
    this.type = ContextMenuButtonConfigType.checkbox,
  });

  final String label;
  final String? shortcutLabel;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? iconHover;
  final bool checked;
  final ContextMenuButtonConfigType type;
  final Color? textColor;
}

enum ContextMenuButtonConfigType {
  normal,
  divider,
  warning,
  checkbox,
}
