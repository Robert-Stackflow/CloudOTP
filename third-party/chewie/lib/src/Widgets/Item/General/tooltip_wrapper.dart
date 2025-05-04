import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Scaffold/my_tooltip.dart';

class ToolTipWrapper extends StatelessWidget {
  final String? message;
  final Widget child;
  final TooltipPosition? position;
  final Duration? waitDuration;

  const ToolTipWrapper({
    super.key,
    required this.message,
    required this.child,
    this.position = TooltipPosition.bottom,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    if (message != null && message!.isNotEmpty) {
      return MyTooltip(
        message: message,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ChewieTheme.defaultDecoration
            .copyWith(color: ChewieTheme.canvasColor, border: null),
        textStyle: ChewieTheme.bodyMedium,
        waitDuration: waitDuration,
        position: position ?? TooltipPosition.bottom,
        child: child,
      );
    } else {
      return child;
    }
  }
}
