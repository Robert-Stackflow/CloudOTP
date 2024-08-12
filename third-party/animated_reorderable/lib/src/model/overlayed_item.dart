part of model;

typedef OverlayedItemDragStartCallback = void Function(
  DragStartDetails details,
  OverlayedItem item,
);
typedef OverlayedItemDragUpdateCallback = void Function(
  DragUpdateDetails details,
  OverlayedItem item,
);
typedef OverlayedItemDragEndCallback = void Function(
  DragEndDetails details,
  OverlayedItem item,
);
typedef RecognizerFactory = gestures.MultiDragGestureRecognizer Function(
  widgets.BuildContext context,
);

class OverlayedItem extends Item {
  OverlayedItem({
    required super.key,
    required super.builder,
    required Offset position,
    required BoxConstraints constraints,
    required this.index,
    bool interactive = true,
    this.outgoing = false,
    int zIndex = defaultZIndex,
    this.recognizerFactory,
  })  : _position = position,
        _constraints = constraints,
        _interactive = interactive,
        _zIndex = zIndex;

  int index;
  widgets.Offset _position;
  widgets.BoxConstraints _constraints;
  bool _interactive;
  bool outgoing;
  int _zIndex = 0;
  RecognizerFactory? recognizerFactory;
  gestures.MultiDragGestureRecognizer? _recognizer;
  _OverlayedItemSwipe? _swipe;
  widgets.Offset? _globalPointerPosition;
  OffsetAnimation? _motionAnimation;
  widgets.Widget? _widget;
  AnimatedItemDecoratorAdapter? _decorator;

  widgets.Offset get position => _position;
  widgets.Offset get anchorPosition =>
      _motionAnimation != null ? _motionAnimation!.end : position;
  widgets.AnimationStatus? get motionAnimationStatus =>
      _motionAnimation?.controller.status;

  void setPosition(widgets.Offset value, {bool notify = true}) {
    if (_position == value) return;
    _position = value;
    if (notify) notifyListeners();
  }

  widgets.BoxConstraints get constraints => _constraints;

  void setConstraints(widgets.BoxConstraints value, {bool notify = true}) {
    if (_constraints == value) return;
    _constraints = value;
    if (notify) notifyListeners();
  }

  bool get interactive => _interactive;

  void setInteractive(bool value, {bool notify = true}) {
    if (interactive == value) return;
    _interactive = value;
    if (notify) notifyListeners();
  }

  Offset? get globalPointerPosition => _globalPointerPosition;

  widgets.Widget? get widget => _widget;

  bool get swiped => _swipe != null;

  widgets.AxisDirection? get swipeToRemoveDirection => _swipe?.swipeDirection;

  Offset get swipeOffset => _swipe?.swipeOffset ?? Offset.zero;

  double get swipeExtent => _swipe?.swipeExtent ?? 0.0;

  widgets.Velocity get swipeVelocity =>
      _swipe?.velocity ?? widgets.Velocity.zero;

  widgets.Widget? build(widgets.BuildContext context) {
    _widget = builder.build(context, index);
    return _decorator?.decorate(_widget, index) ?? _widget;
  }

  void shift(Offset delta, {bool notify = true}) {
    _motionAnimation?.shift(delta);
    setPosition(position + delta, notify: notify);
  }

  void scale(double scaleFactor, {bool notify = true}) {
    _motionAnimation?.scale(scaleFactor);
    if (scaleFactor == 1) return;
    setPosition(position * scaleFactor, notify: false);
    setConstraints(constraints * scaleFactor, notify: notify);
  }

  int get zIndex => _zIndex;
  void setZIndex(int value, {bool notify = true}) {
    if (_zIndex == value) return;
    _zIndex = value;
    if (notify) notifyListeners();
  }

  void recognizeDrag(
    widgets.PointerDownEvent event, {
    required widgets.BuildContext context,
    OverlayedItemDragStartCallback? onDragStart,
    OverlayedItemDragUpdateCallback? onDragUpdate,
    OverlayedItemDragEndCallback? onDragEnd,
  }) {
    _recognizer?.dispose();
    _swipe = null;

    if (!interactive) return;
    if (recognizerFactory == null) return;

    _recognizer = recognizerFactory!.call(context)
      ..onStart = (globalPosition) {
        _globalPointerPosition = globalPosition;
        onDragStart?.call(
          DragStartDetails(
            sourceTimeStamp: event.timeStamp,
            globalPosition: globalPosition,
            localPosition: event.localPosition,
            kind: event.kind,
          ),
          this,
        );

        return _OverlayedItemDrag(
          item: this,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        );
      }
      ..addPointer(event);
  }

  void recognizeSwipe(
    widgets.PointerDownEvent event, {
    required widgets.BuildContext context,
    required widgets.AxisDirection swipeDirection,
    OverlayedItemDragStartCallback? onSwipeStart,
    OverlayedItemDragUpdateCallback? onSwipeUpdate,
    OverlayedItemDragEndCallback? onSwipeEnd,
  }) {
    _recognizer?.dispose();

    if (!interactive) return;
    if (recognizerFactory == null) return;

    _recognizer = recognizerFactory!.call(context)
      ..onStart = (globalPosition) {
        _globalPointerPosition = globalPosition;
        onSwipeStart?.call(
          DragStartDetails(
            sourceTimeStamp: event.timeStamp,
            globalPosition: globalPosition,
            localPosition: event.localPosition,
            kind: event.kind,
          ),
          this,
        );

        return _swipe = _OverlayedItemSwipe(
          item: this,
          swipeDirection: swipeDirection,
          onSwipeUpdate: onSwipeUpdate,
          onSwipeEnd: onSwipeEnd,
        );
      }
      ..addPointer(event);
  }

  Future animateTo(
    Offset position, {
    required TickerProvider vsync,
    required Duration duration,
    required Curve curve,
  }) {
    if (position == this.position) return Future.value();

    _motionAnimation ??= OffsetAnimation(
      controller: AnimationController(
        vsync: vsync,
        duration: duration,
      )..addListener(
          () => setPosition(_motionAnimation!.value),
        ),
    );
    _motionAnimation!.controller.duration = duration;
    _motionAnimation!.begin = this.position;
    _motionAnimation!.end = position;
    _motionAnimation!.curve = curve;

    return _motionAnimation!.controller.forward(from: 0.0);
  }

  Future animateFlingTo(
    Offset position, {
    required widgets.Velocity velocity,
    required Size screenSize,
    SpringDescription springDescription = defaultFlingSpringDescription,
    required TickerProvider vsync,
  }) {
    if (position == this.position) return Future.value();

    _motionAnimation ??= OffsetAnimation(
      controller: AnimationController(vsync: vsync)
        ..addListener(
          () => setPosition(_motionAnimation!.value),
        ),
    );
    _motionAnimation!.begin = this.position;
    _motionAnimation!.end = position;
    _motionAnimation!.curve = Curves.linear;

    final pixelsPerSecond = velocity.pixelsPerSecond;
    final unitsPerSecondX = pixelsPerSecond.dx / screenSize.width;
    final unitsPerSecondY = pixelsPerSecond.dy / screenSize.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;
    final simulation = SpringSimulation(springDescription, 0, 1, -unitVelocity);

    return _motionAnimation!.controller.animateWith(simulation);
  }

  void stopMotion() => _motionAnimation?.controller.stop();

  Future animateDecoration({
    AnimatedItemDecorator? decorator,
    required Duration duration,
    required TickerProvider vsync,
  }) {
    if (decorator == null) return Future.value();

    if (_decorator != null) {
      _decorator!.decorator = decorator;
    } else {
      _decorator = AnimatedItemDecoratorAdapter(
        decorator,
        controller: AnimationController(
          duration: duration,
          vsync: vsync,
        ),
      );
    }

    return _decorator!.forwardAnimation();
  }

  Future animateUndecoration() => switch (_decorator) {
        (AnimatedItemDecoratorAdapter d) => d.reverseAnimation(),
        _ => Future.value(),
      };

  double stopDecorationAnimation() => switch (_decorator) {
        (AnimatedItemDecoratorAdapter d) => d.stopDecoration(),
        _ => 0.0,
      };

  @override
  void dispose() {
    _recognizer?.dispose();
    _recognizer = null;
    _swipe = null;
    _motionAnimation?.dispose();
    _motionAnimation = null;
    super.dispose();
  }

  @override
  String toString() => 'OverlayedItem(id: $key, index: $index)';
}

class _OverlayedItemDrag implements gestures.Drag {
  _OverlayedItemDrag({
    required this.item,
    this.onDragUpdate,
    this.onDragEnd,
  });

  final OverlayedItem item;
  OverlayedItemDragUpdateCallback? onDragUpdate;
  OverlayedItemDragEndCallback? onDragEnd;

  @override
  void update(widgets.DragUpdateDetails details) {
    item._globalPointerPosition = details.globalPosition;
    onDragUpdate?.call(details, item);
  }

  @override
  void end(widgets.DragEndDetails details) {
    item._globalPointerPosition = null;
    onDragEnd?.call(details, item);
  }

  @override
  void cancel() {}
}

class _OverlayedItemSwipe implements gestures.Drag {
  _OverlayedItemSwipe({
    required this.item,
    required this.swipeDirection,
    this.onSwipeUpdate,
    this.onSwipeEnd,
  });

  final OverlayedItem item;
  final widgets.AxisDirection swipeDirection;
  OverlayedItemDragUpdateCallback? onSwipeUpdate;
  OverlayedItemDragEndCallback? onSwipeEnd;
  widgets.Offset _swipeOffset = widgets.Offset.zero;
  widgets.Velocity _velocity = widgets.Velocity.zero;

  widgets.Velocity get velocity => _velocity;

  widgets.Offset get swipeOffset => _swipeOffset;

  double get swipeExtent => _swipeOffset.dx != 0
      ? _swipeOffset.dx / item.constraints.maxWidth
      : _swipeOffset.dy / item.constraints.maxHeight;

  @override
  void update(widgets.DragUpdateDetails details) {
    final delta = _restrictDirection(_restrictAxis(details.delta));
    _swipeOffset += delta;
    item._globalPointerPosition = details.globalPosition;
    onSwipeUpdate?.call(
      widgets.DragUpdateDetails(
        sourceTimeStamp: details.sourceTimeStamp,
        delta: delta,
        primaryDelta: delta.dx != 0.0 ? delta.dx : delta.dy,
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
      item,
    );
  }

  widgets.Offset _restrictAxis(widgets.Offset delta) =>
      switch (swipeDirection) {
        widgets.AxisDirection.left ||
        widgets.AxisDirection.right =>
          widgets.Offset(delta.dx, 0),
        widgets.AxisDirection.down ||
        widgets.AxisDirection.up =>
          widgets.Offset(0, delta.dy),
      };

  widgets.Offset _restrictDirection(widgets.Offset delta) =>
      switch (swipeDirection) {
        widgets.AxisDirection.left when delta.dx > 0 && _swipeOffset.dx > 0 =>
          widgets.Offset(delta.dx / 3, 0),
        widgets.AxisDirection.right when delta.dx < 0 && _swipeOffset.dx < 0 =>
          widgets.Offset(delta.dx / 3, 0),
        widgets.AxisDirection.down when delta.dy < 0 && _swipeOffset.dy < 0 =>
          widgets.Offset(0, delta.dy / 3),
        widgets.AxisDirection.up when delta.dy > 0 && _swipeOffset.dy > 0 =>
          widgets.Offset(0, delta.dy / 3),
        _ => delta,
      };

  @override
  void end(widgets.DragEndDetails details) {
    _velocity = details.velocity;
    item._globalPointerPosition = null;
    onSwipeEnd?.call(details, item);
  }

  @override
  void cancel() {
    // noop
  }
}
