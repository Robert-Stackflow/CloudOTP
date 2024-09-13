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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollToHideController {
  Function()? doShow;
  Function()? doHide;

  void show() {
    doShow?.call();
  }

  void hide() {
    doHide?.call();
  }
}

/// A widget that hides its child when the user scrolls down and shows it again when the user scrolls up.
/// This behavior is commonly used to hide elements like a bottom navigation bar to provide a more immersive user experience.
class ScrollToHide extends StatefulWidget {
  /// Creates a `ScrollToHide` widget.
  ///
  /// The [child], [scrollController], and [height] parameters are required.
  /// The [duration] parameter is optional and defaults to 300 milliseconds.
  ///
  /// The [child] is the widget that you want to hide/show based on the scroll direction.
  ///
  /// The [scrollController] is the `ScrollController` that is connected to the scrollable widget in your app.
  /// This is used to track the scroll position and determine whether to hide or show the child widget.
  ///
  /// The [height] is the initial height of the child widget. When the widget is hidden, its height will be animated to 0.
  const ScrollToHide({
    super.key,
    required this.child,
    required this.scrollController,
    this.duration = const Duration(milliseconds: 300),
    required this.hideDirection,
    this.width,
    this.enabled = true,
    this.height,
    this.controller,
  });

  final ScrollToHideController? controller;

  final bool enabled;

  /// The widget that you want to hide/show based on the scroll direction.
  final Widget child;

  /// The `ScrollController` that is connected to the scrollable widget in your app.
  /// This is used to track the scroll position and determine whether to hide or show the child widget.
  final ScrollController scrollController;

  /// The duration of the animation when the child widget is hidden or shown.
  final Duration duration;

  /// The initial height of the child widget. When the widget is hidden, its height will be animated to 0.
  final double? height;

  /// The initial width of the child widget, its width will be animated to 0 .by providing width you want the hide direction to be horizontal.
  final Axis hideDirection;

  /// The initial width of the child widget, its width will be animated to 0 .by providing width you want the hide direction to be horizontal.
  final double? width;

  @override
  State<ScrollToHide> createState() => ScrollToHideState();
}

class ScrollToHideState extends State<ScrollToHide> {
  bool isShown = true;

  @override
  void initState() {
    widget.scrollController.addListener(listen);
    widget.controller?.doShow = show;
    widget.controller?.doHide = hide;
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(() {});
    super.dispose();
  }

  @override
  void didUpdateWidget(ScrollToHide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      widget.scrollController.addListener(listen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      opacity: isShown ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: widget.duration,
        height: widget.hideDirection == Axis.vertical
            ? (isShown ? widget.height : 0)
            : widget.height,
        width: widget.hideDirection == Axis.horizontal
            ? (isShown ? widget.width : 0)
            : widget.width,
        curve: Curves.linear,
        clipBehavior: Clip.none,
        child: Wrap(
          children: [
            widget.child,
          ],
        ),
      ),
    );
  }

  /// Shows the child widget if it is currently hidden.
  void show() {
    if (!isShown && mounted) {
      setState(() => isShown = true);
    }
  }

  /// Hides the child widget if it is currently shown.
  void hide() {
    if (isShown && mounted) {
      setState(
        () => isShown = false,
      );
    }
  }

  void listen() {
    if (widget.enabled) {
      final direction = widget.scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.forward) {
        show();
      } else if (direction == ScrollDirection.reverse) {
        hide();
      }
    }
  }
}
