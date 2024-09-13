/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math';

import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

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

  NavigatorState? get navigatorState => _navigatorState;

  bool canNavigatorPop = true;

  pushPage(Widget page) {
    _navigatorState?.push(RouteUtil.getFadeRoute(page));
  }

  popAll() {
    if (mounted) Navigator.pop(context);
  }

  popPage() {
    if (_navigatorState!.canPop()) {
      _navigatorState?.pop();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width - 60;
    double height = MediaQuery.sizeOf(context).height - 60;
    double preferWidth = min(width, widget.preferMinWidth ?? 540);
    double preferHeight = min(width, widget.preferMinHeight ?? 720);
    double preferHorizontalMargin =
        width > preferWidth ? (width - preferWidth) / 2 : 0;
    double preferVerticalMargin =
        height > preferHeight ? (height - preferHeight) / 2 : 0;
    preferHorizontalMargin = max(preferHorizontalMargin, 20);
    preferVerticalMargin = max(preferVerticalMargin, 20);
    return PopScope(
      canPop: !canNavigatorPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          canNavigatorPop = _navigatorState?.canPop() ?? false;
        });
        popPage();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: preferHorizontalMargin, vertical: preferVerticalMargin),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Theme.of(context).dividerColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Utils.isDark(context)
                    ? Theme.of(context).shadowColor
                    : Colors.transparent,
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: 1,
              ).scale(2)
            ],
          ),
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
                    right: 8,
                    top: 8,
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
