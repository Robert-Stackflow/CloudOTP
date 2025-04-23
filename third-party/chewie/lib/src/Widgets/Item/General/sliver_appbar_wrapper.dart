import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Widgets/Scaffold/my_appbar.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/circle_icon_button.dart';

class SliverAppBarWrapper extends StatelessWidget {
  final BuildContext context;
  final Widget? backgroundWidget;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final Widget? title;
  final bool centerTitle;
  final double expandedHeight;
  final double titleLeftMargin;
  final double? collapsedHeight;
  final double leftSpacing;
  final double rightSpacing;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const SliverAppBarWrapper({
    super.key,
    required this.context,
    this.backgroundWidget,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.title,
    this.centerTitle = false,
    this.expandedHeight = 320,
    this.titleLeftMargin = 0,
    this.collapsedHeight,
    this.leftSpacing = 8,
    this.rightSpacing = 8,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    var finalTitleWidget = Container(
      margin: EdgeInsets.only(left: titleLeftMargin),
      child: title,
    );
    var leading = Container(
      margin: EdgeInsets.only(left: leftSpacing),
      child: CircleIconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onTap: () => Navigator.pop(context),
      ),
    );

    return MySliverAppBar(
      systemOverlayStyle: systemOverlayStyle,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight ??
          max(100, kToolbarHeight + MediaQuery.of(context).padding.top),
      pinned: true,
      leadingWidth: showLeading ? 56 : 0,
      leading: showLeading ? leading : null,
      automaticallyImplyLeading: false,
      backgroundWidget: backgroundWidget,
      title: centerTitle ? Center(child: finalTitleWidget) : finalTitleWidget,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      actions: [
        if (actions != null) ...?actions,
        SizedBox(width: rightSpacing),
      ],
    );
  }
}
