import 'package:flutter/material.dart';

import '../../Resources/theme.dart';
import '../../Utils/iprint.dart';

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  final double radius;

  final Color? background;

  SliverAppBarDelegate({
    required this.tabBar,
    this.background,
    this.radius = 16,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? MyTheme.getBackground(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          tabBarTheme: const TabBarTheme(
            splashFactory: NoSplash.splashFactory,
          ),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

typedef SliverHeaderBuilder = Widget Function(
    BuildContext context, double shrinkOffset, bool overlapsContent);

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  SliverHeaderDelegate({
    required this.maxHeight,
    this.minHeight = 0,
    required Widget child,
  })  : builder = ((a, b, c) => child),
        assert(minHeight <= maxHeight && minHeight >= 0);

  SliverHeaderDelegate.fixedHeight({
    required double height,
    required Widget child,
  })  : builder = ((a, b, c) => child),
        maxHeight = height,
        minHeight = height;

  SliverHeaderDelegate.builder({
    required this.maxHeight,
    this.minHeight = 0,
    required this.builder,
  });

  final double maxHeight;
  final double minHeight;
  final SliverHeaderBuilder builder;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    Widget child = builder(context, shrinkOffset, overlapsContent);
    assert(() {
      if (child.key != null) {
        IPrint.debug(
            '${child.key}: shrink: $shrinkOffset，overlaps:$overlapsContent');
      }
      return true;
    }());
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(SliverHeaderDelegate old) {
    return old.maxExtent != maxExtent || old.minExtent != minExtent;
  }
}
