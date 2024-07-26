import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

const double DEFAULT_BAR_HEIGHT = 60;

const double DEFAULT_INDICATOR_HEIGHT = 2;

// ignore: must_be_immutable
class TitledBottomNavigationBar extends StatefulWidget {
  final bool reverse;
  final Curve curve;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? inactiveStripColor;
  final Color? indicatorColor;
  final Color? backgroundColor;
  final bool enableShadow;
  int currentIndex;

  /// Called when a item is tapped.
  ///
  /// This provide the selected item's index.
  final ValueChanged<int> onTap;

  final ValueChanged<int>? onDoubleTap;

  /// The items of this navigation bar.
  ///
  /// This should contain at least two items and five at most.
  final List<TitledNavigationBarItem> items;

  /// The selected item is indicator height.
  ///
  /// Defaults to [DEFAULT_INDICATOR_HEIGHT].
  final double indicatorHeight;

  /// Change the navigation bar's size.
  ///
  /// Defaults to [DEFAULT_BAR_HEIGHT].
  final double height;

  TitledBottomNavigationBar({
    super.key,
    this.reverse = false,
    this.curve = Curves.linear,
    required this.onTap,
    this.onDoubleTap,
    required this.items,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.inactiveStripColor,
    this.indicatorColor,
    this.enableShadow = true,
    this.currentIndex = 0,
    this.height = DEFAULT_BAR_HEIGHT,
    this.indicatorHeight = DEFAULT_INDICATOR_HEIGHT,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  State createState() => _TitledBottomNavigationBarState();
}

class _TitledBottomNavigationBarState extends State<TitledBottomNavigationBar> {
  bool get reverse => widget.reverse;

  Curve get curve => widget.curve;

  List<TitledNavigationBarItem> get items => widget.items;

  double width = 0;
  Color? activeColor;
  Duration duration = const Duration(milliseconds: 270);

  double _getIndicatorPosition(int index) {
    var isLtr = Directionality.of(context) == TextDirection.ltr;
    if (isLtr) {
      return lerpDouble(-1.0, 1.0, index / (items.length - 1))!;
    } else {
      return lerpDouble(1.0, -1.0, index / (items.length - 1))!;
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.sizeOf(context).width;
    activeColor = widget.activeColor ?? Theme.of(context).indicatorColor;

    return Container(
      height: widget.height + MediaQuery.of(context).viewPadding.bottom,
      width: width,
      decoration: BoxDecoration(
        color: widget.inactiveStripColor ?? Theme.of(context).cardColor,
        boxShadow: widget.enableShadow
            ? [
                const BoxShadow(color: Colors.black12, blurRadius: 1),
              ]
            : null,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: widget.indicatorHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((item) {
                var index = items.indexOf(item);
                return Listener(
                  onPointerDown: (event) => _select(index),
                  child: GestureDetector(
                    onDoubleTap: () => _doubleTap(index),
                    child: _buildItemWidget(item, index == widget.currentIndex),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            top: 0,
            width: width,
            child: AnimatedAlign(
              alignment:
                  Alignment(_getIndicatorPosition(widget.currentIndex), 0),
              curve: curve,
              duration: duration,
              child: Container(
                color: widget.indicatorColor ?? activeColor,
                width: width / items.length,
                height: widget.indicatorHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _select(int index) {
    widget.currentIndex = index;
    widget.onTap(widget.currentIndex);
    setState(() {});
  }

  void _doubleTap(int index) {
    widget.onDoubleTap?.call(widget.currentIndex);

    setState(() {});
  }

  Widget _buildIcon(TitledNavigationBarItem item) {
    return IconTheme(
      data: IconThemeData(
        color: reverse ? widget.inactiveColor : activeColor,
      ),
      child: item.icon,
    );
  }

  Widget _buildText(TitledNavigationBarItem item) {
    return DefaultTextStyle.merge(
      child: item.title,
      style: TextStyle(color: reverse ? activeColor : widget.inactiveColor),
    );
  }

  Widget _buildItemWidget(TitledNavigationBarItem item, bool isSelected) {
    return Container(
      color: item.backgroundColor,
      height: widget.height,
      width: width / items.length,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          AnimatedOpacity(
            opacity: isSelected ? 0.0 : 1.0,
            duration: duration,
            curve: curve,
            child: reverse ? _buildIcon(item) : _buildText(item),
          ),
          AnimatedAlign(
            duration: duration,
            alignment: isSelected ? Alignment.center : const Alignment(0, 5.2),
            child: reverse ? _buildText(item) : _buildIcon(item),
          ),
        ],
      ),
    );
  }
}

class TitledNavigationBarItem {
  /// The title of this item.
  final Widget title;

  /// The icon of this item.
  ///
  /// If this is not a [Icon] widget, you must handle the color manually.
  final Widget icon;

  /// The background color of this item.
  ///
  /// Defaults to [Colors.white].
  final Color backgroundColor;

  TitledNavigationBarItem({
    required this.icon,
    required this.title,
    this.backgroundColor = Colors.white,
  });
}
