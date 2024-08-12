part of model;

typedef AnimatedItemDecorator = widgets.Widget Function(
  widgets.Widget child,
  int index,
  Animation<double> animation,
);

abstract class ItemDecorator {
  factory ItemDecorator.adaptAnimatedItemDecorator(
    AnimatedItemDecorator decorator, {
    required widgets.AnimationController controller,
  }) =>
      AnimatedItemDecoratorAdapter(decorator, controller: controller);

  widgets.Widget? decorate(widgets.Widget? child, int index);

  void dispose();
}

class AnimatedItemDecoratorAdapter implements ItemDecorator {
  AnimatedItemDecoratorAdapter(
    this.decorator, {
    required this.controller,
  });

  final widgets.AnimationController controller;
  AnimatedItemDecorator decorator;

  @override
  widgets.Widget? decorate(widgets.Widget? child, int index) {
    return child != null ? decorator.call(child, index, controller.view) : null;
  }

  TickerFuture forwardAnimation({double? from}) =>
      controller.forward(from: from);

  TickerFuture reverseAnimation({double? from}) =>
      controller.reverse(from: from);

  double stopDecoration() {
    final result = controller.value;
    controller.stop();
    return result;
  }

  @override
  void dispose() {
    controller.dispose();
  }
}
