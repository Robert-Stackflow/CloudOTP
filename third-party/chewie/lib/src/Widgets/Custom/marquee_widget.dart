import 'dart:async';

import 'package:flutter/cupertino.dart';

class MarqueeWidget extends StatefulWidget {
  /// 子视图数量
  final int count;

  ///子视图构建器
  final IndexedWidgetBuilder itemBuilder;

  ///轮播的时间间隔
  final int loopSeconds;

  final bool autoPlay;

  final PageController controller;

  final Function(int index)? onPageChanged;

  const MarqueeWidget({
    super.key,
    required this.count,
    required this.itemBuilder,
    this.loopSeconds = 5,
    this.autoPlay = false,
    required this.controller,
    this.onPageChanged,
  });

  @override
  MarqueeWidgetState createState() => MarqueeWidgetState();

  void switchTo(int index) {}
}

class MarqueeWidgetState extends State<MarqueeWidget> {
  late PageController _controller;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _timer = Timer.periodic(Duration(seconds: widget.loopSeconds), (timer) {
      if (widget.autoPlay) {
        if (_controller.page != null) {
          if (_controller.page!.round() >= widget.count) {
            _controller.jumpToPage(0);
          }
          _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        controller: _controller,
        itemBuilder: (buildContext, index) {
          if (index < widget.count) {
            return widget.itemBuilder(buildContext, index);
          } else {
            return widget.itemBuilder(buildContext, 0);
          }
        },
        itemCount: widget.count + 1,
        onPageChanged: widget.onPageChanged,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }
}
