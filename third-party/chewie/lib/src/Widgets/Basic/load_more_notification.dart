import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class LoadMoreNotification extends StatelessWidget {
  final Function()? onLoad;
  final Widget child;
  final bool noMore;

  const LoadMoreNotification({
    super.key,
    required this.child,
    required this.noMore,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0) {
          return false;
        }
        if (!noMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - kLoadExtentOffset) {
          onLoad?.call();
        }
        return false;
      },
      child: child,
    );
  }
}
