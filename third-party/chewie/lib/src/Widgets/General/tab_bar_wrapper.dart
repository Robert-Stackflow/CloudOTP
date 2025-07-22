import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class TabBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<Widget> tabs;
  final double height;
  final EdgeInsetsGeometry containerPadding;
  final EdgeInsetsGeometry tabBarPadding;
  final EdgeInsetsGeometry labelPadding;
  final ValueChanged<int>? onTap;
  final bool showBorder;
  final Color? background;
  final double? width;
  final bool forceUnscrollable;

  const TabBarWrapper({
    super.key,
    required this.tabController,
    required this.tabs,
    this.height = 56,
    this.containerPadding = const EdgeInsets.symmetric(vertical: 4),
    this.tabBarPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.onTap,
    this.showBorder = false,
    this.background,
    this.width,
    this.forceUnscrollable = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    bool scrollable = false;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      scrollable = true;
    } else {
      scrollable = tabs.length > 3;
    }
    scrollable = forceUnscrollable ? false : scrollable;

    var titleMedium = ChewieTheme.titleMedium;

    return Container(
      height: height,
      width: width,
      padding: containerPadding,
      decoration: BoxDecoration(
        color: background ?? ChewieTheme.canvasColor,
        border: showBorder
            ? const Border(bottom: BorderSide(color: Colors.grey, width: 0.5))
            : null,
      ),
      child: TabBar(
        controller: tabController,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: tabs,
        labelPadding: labelPadding,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        padding: tabBarPadding,
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : null,
        physics: const BouncingScrollPhysics(),
        labelStyle: titleMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF1F1F1),
        ),
        unselectedLabelStyle: titleMedium.copyWith(color: Colors.grey),
        indicator: UnderlinedTabIndicator(
          borderColor: ChewieTheme.primaryColor,
          indicatorBottom: 4,
          indicatorWidth: 12,
          borderWidth: 3,
        ),
        onTap: onTap,
      ),
    );
  }
}
