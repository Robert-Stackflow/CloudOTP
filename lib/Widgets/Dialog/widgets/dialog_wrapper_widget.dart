import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';

import '../../../Utils/route_util.dart';
import '../../../Utils/utils.dart';

class DialogWrapperWidget extends StatefulWidget {
  final Widget child;
  final double? preferMinWidth;
  final double? preferMinHeight;
  final bool showClose;

  const DialogWrapperWidget({
    super.key,
    required this.child,
    this.preferMinWidth,
    this.preferMinHeight,
    this.showClose = true,
  });

  @override
  State<StatefulWidget> createState() => DialogWrapperWidgetState();
}

class DialogWrapperWidgetState extends State<DialogWrapperWidget> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get _navigatorState => _navigatorKey.currentState;

  popPage() {
    if (_navigatorState!.canPop()) {
      _navigatorState?.pop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, widget.preferMinWidth ?? 540);
    double preferHeight = min(width, widget.preferMinHeight ?? 500);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    // preferHorizontalMargin = max(preferHorizontalMargin, 20);
    // preferVerticalMargin = max(preferVerticalMargin, 20);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: preferHorizontalMargin, vertical: preferVerticalMargin),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Utils.isDark(context)
                    ? Theme.of(context).shadowColor
                    : Colors.grey.shade400,
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 0,
              ).scale(4)
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (settings) =>
                      RouteUtil.getFadeRoute(widget.child),
                ),
                if (widget.showClose)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: ItemBuilder.buildIconButton(
                      context: context,
                      icon: const Icon(Icons.close_rounded),
                      onTap: () {
                        popPage();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
