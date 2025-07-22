import 'package:flutter/material.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class HoverIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final EdgeInsets? padding;
  final Color? background;
  final String? tooltip;
  final TooltipPosition? position;
  final Color? filterColor;

  const HoverIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.background,
    this.tooltip,
    this.filterColor,
    this.position = TooltipPosition.bottom,
  });

  @override
  HoverIconButtonState createState() => HoverIconButtonState();
}

class HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconWithHover = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ColorFiltered(
        colorFilter: _isHovered
            ? ColorFilter.mode(
                (widget.filterColor ?? Colors.white).withOpacity(0.5),
                BlendMode.srcATop,
              )
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: widget.icon,
      ),
    );

    final button = GestureDetector(
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.background ?? Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: iconWithHover,
      ),
    );

    return ToolTipWrapper(
      message: widget.tooltip,
      position: widget.position,
      child: button,
    );
  }
}
