import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:awesome_chewie/awesome_chewie.dart';

class CircleIconButton extends StatefulWidget {
  final dynamic icon;
  final Function()? onTap;
  final Function()? onLongPress;
  final EdgeInsets? padding;
  final Color? background;
  final String? tooltip;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.padding,
    this.background,
    this.tooltip,
  });

  @override
  CircleIconButtonState createState() => CircleIconButtonState();

  Widget dynamicButton({
    required dynamic icon,
    required Function()? onTap,
    Function(BuildContext context, dynamic value, Widget? child)? onChangemode,
  }) {
    return Selector<ChewieProvider, ActiveThemeMode>(
      selector: (context, globalProvider) => globalProvider.themeMode,
      builder: (context, themeMode, child) {
        onChangemode?.call(context, themeMode, child);
        return CircleIconButton(icon: icon, onTap: onTap);
      },
    );
  }
}

class CircleIconButtonState extends State<CircleIconButton> {
  @override
  Widget build(BuildContext context) {
    var res = InkAnimation(
      color: widget.background ?? Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: PressableAnimation(
        onTap: widget.onTap,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(8),
          child: widget.icon ?? emptyWidget,
        ),
      ),
    );
    return ToolTipWrapper(
      message: widget.tooltip,
      position: TooltipPosition.top,
      child: res,
    );
  }
}

class BlankIconButton extends StatefulWidget {
  const BlankIconButton({super.key});

  @override
  BlankIconButtonState createState() => BlankIconButtonState();
}

class BlankIconButtonState extends State<BlankIconButton> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: false,
      maintainAnimation: true,
      maintainState: true,
      maintainSize: true,
      child: CircleIconButton(
        icon: Icon(Icons.more_vert_rounded, color: ChewieTheme.iconColor),
        onTap: () {},
      ),
    );
  }
}
