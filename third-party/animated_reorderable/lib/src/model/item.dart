part of model;

class Item extends widgets.ChangeNotifier {
  Item({
    required this.key,
    required ItemBuilder builder,
  }) : _builder = builder;

  final Key key;
  ItemBuilder _builder;

  ItemBuilder get builder => _builder;

  T setBuilder<T extends ItemBuilder>(T value, {bool notify = true}) {
    if (_builder == value) return value;
    _builder = value;
    if (notify) notifyListeners();
    return value;
  }

  @override
  void dispose() {
    builder.dispose();
    super.dispose();
  }

  @override
  String toString() => 'Item(id: $key)';
}

extension ItemAnimations on Item {
  Future animateItemBuilder({
    required widgets.AnimatedItemBuilder builder,
    required TickerProvider vsync,
    required Duration duration,
    double? from = 0,
  }) {
    final originalBuilder = this.builder;
    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    setBuilder(
      ItemBuilder.adaptAnimatedItemBuilder(
        builder,
        controller: controller,
      ),
      notify: false,
    );

    return controller.forward(from: from).whenComplete(() {
      setBuilder(originalBuilder);
      controller.dispose();
    });
  }

  Future animateRemovedItemBuilder({
    required widgets.AnimatedRemovedItemBuilder builder,
    required TickerProvider vsync,
    required Duration duration,
  }) {
    final from = this.builder.asAnimated?.stopAnimation() ?? 1.0;
    final controller = AnimationController(vsync: vsync, duration: duration);

    setBuilder(
      ItemBuilder.adaptAnimatedRemovedItemBuilder(
        builder,
        controller: controller,
      ),
      notify: false,
    );

    return controller.reverse(from: from);
  }
}
