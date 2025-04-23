import 'package:flutter/cupertino.dart';

class ClickableWrapper extends StatelessWidget {
  final Widget child;
  final bool clickable;

  const ClickableWrapper({
    super.key,
    required this.child,
    this.clickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: child,
    );
  }
}
