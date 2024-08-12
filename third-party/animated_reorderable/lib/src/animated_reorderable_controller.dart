import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as widgets;

import '../animated_reorderable.dart';
import 'const.dart';
import 'model/model.dart' as model;
import 'util/overrided_sliver_child_builder_delegate.dart';
import 'util/misc.dart';
import 'widget/item_widget.dart';
import 'widget/items_layer.dart';
import 'util/measure_util.dart';
import 'widget/overlayed_items_layer.dart';

class AnimatedReorderableController {
  AnimatedReorderableController({
    required this.keyGetter,
    required this.scrollDirection,
    int? itemCount,
    BoolGetter? reorderableGetter,
    BoolGetter? draggableGetter,
    AxisDirectionGetter? swipeToRemoveDirectionGetter,
    this.onReorder,
    this.onSwipeToRemove,
    required this.vsync,
    required this.motionAnimationDuration,
    required this.motionAnimationCurve,
    this.draggedItemDecorator,
    required this.draggedItemDecorationAnimationDuration,
    this.swipedItemDecorator,
    required this.swipedItemDecorationAnimationDuration,
    required this.autoScrollerVelocityScalar,
    required this.swipeToRemoveExtent,
    required this.swipeToRemoveVelocity,
    required this.swipeToRemoveSpringDescription,
    this.onItemDragStart,
    this.onItemDragUpdate,
    this.onItemDragEnd,
    this.onItemSwipeStart,
    this.onItemSwipeUpdate,
    this.onItemSwipeEnd,
  })  : reorderableGetter = reorderableGetter ?? ((_) => true),
        draggableGetter = draggableGetter ?? ((_) => true),
        swipeToRemoveDirectionGetter = onSwipeToRemove != null
            ? ((index) =>
                swipeToRemoveDirectionGetter?.call(index) ??
                (scrollDirection == Axis.vertical
                    ? AxisDirection.left
                    : AxisDirection.down))
            : ((_) => null),
        _state = model.ControllerState(itemCount: itemCount);

  widgets.ScrollController? _scrollController;
  widgets.EdgeDraggingAutoScroller? _autoScroller;
  late OverridedSliverChildBuilderDelegate _childrenDelegate;
  final model.ControllerState<ItemsLayerState, OverlayedItemsLayerState> _state;

  final KeyGetter keyGetter;
  final Axis scrollDirection;
  final BoolGetter reorderableGetter;
  final BoolGetter draggableGetter;
  final AxisDirectionGetter swipeToRemoveDirectionGetter;
  final double autoScrollerVelocityScalar;
  final double swipeToRemoveExtent;
  final double swipeToRemoveVelocity;
  final widgets.SpringDescription swipeToRemoveSpringDescription;
  final ReorderCallback? onReorder;
  final SwipeToRemoveCallback? onSwipeToRemove;
  final widgets.TickerProvider vsync;
  final Duration motionAnimationDuration;
  final widgets.Curve motionAnimationCurve;
  final model.AnimatedItemDecorator? draggedItemDecorator;
  final Duration draggedItemDecorationAnimationDuration;
  final model.AnimatedItemDecorator? swipedItemDecorator;
  final Duration swipedItemDecorationAnimationDuration;
  final ItemDragStartCallback? onItemDragStart;
  final ItemDragUpdateCallback? onItemDragUpdate;
  final ItemDragEndCallback? onItemDragEnd;
  final ItemDragStartCallback? onItemSwipeStart;
  final ItemDragUpdateCallback? onItemSwipeUpdate;
  final ItemDragEndCallback? onItemSwipeEnd;

  void insertItem(
      int index, widgets.AnimatedItemBuilder builder, Duration duration) {
    if (_state.itemCount == null) {
      throw ('$runtimeType must be connected with a ${widgets.ListView} or ${widgets.GridView}');
    }
    if (index < 0 || index > _state.itemCount!) {
      throw RangeError.value(index);
    }

    final insertedItem = _state.insertItem(
      index: index,
      itemFactory: createItem,
    );

    insertedItem.animateItemBuilder(
      builder: builder,
      duration: duration,
      vsync: vsync,
    );

    overlayedItemsLayer!.rebuild(() {
      for (var renderedItem in _state.renderedItems
          .where((x) => x.key != insertedItem.key)
          .where(isNotDragged)
          .where(isNotSwiped)) {
        _state.putOverlayedItemIfAbsent(
          key: renderedItem.key,
          ifAbsent: () => createOverlayedItem(renderedItem),
        )
          ..index = renderedItem.index >= index
              ? renderedItem.index + 1
              : renderedItem.index
          ..setInteractive(false, notify: false);
      }
    });

    itemsLayer!.rebuild();
  }

  void removeItem(
    int index,
    widgets.AnimatedRemovedItemBuilder builder,
    Duration duration, {
    int? zIndex,
  }) {
    if (_state.itemCount == null) {
      throw ('$runtimeType must be connected with a ${widgets.ListView} or ${widgets.GridView}');
    }
    if (index < 0 || index >= _state.itemCount!) {
      throw RangeError.value(index);
    }

    final removedItem = _state.removeItem(index: index);
    if (removedItem == null) return;

    final renderedItem = _state.renderedItemBy(key: removedItem.key);
    if (renderedItem == null) {
      removedItem.dispose();
    }

    overlayedItemsLayer!.rebuild(() {
      for (var renderedItem in _state.renderedItems
          .where((x) => x.key != removedItem.key)
          .where(isNotDragged)
          .where(isNotSwiped)) {
        _state.putOverlayedItemIfAbsent(
          key: renderedItem.key,
          ifAbsent: () => createOverlayedItem(renderedItem),
        )
          ..index = renderedItem.index > index
              ? renderedItem.index - 1
              : renderedItem.index
          ..setInteractive(false, notify: false);
      }

      if (renderedItem != null) {
        _state.putOverlayedItemIfAbsent(
          key: renderedItem.key,
          ifAbsent: () => createOverlayedItem(
            renderedItem,
            builder: removedItem.builder,
          ),
        )
          ..outgoing = true
          ..setInteractive(false, notify: false)
          ..setZIndex(zIndex ?? outgoingItemZIndex, notify: false)
          ..animateRemovedItemBuilder(
            builder: builder,
            duration: duration,
            vsync: vsync,
          ).whenComplete(
            () => overlayedItemsLayer!.rebuild(() {
              _state.removeOverlayedItem(key: removedItem.key)?.dispose();
              removedItem.dispose();
            }),
          );
      }
    });

    itemsLayer!.rebuild();
  }

  void reorderItem(
    int index, {
    required int destIndex,
  }) {
    if (onReorder == null) {
      throw ('onReorder parameter must be not null to reorder');
    }
    if (_state.itemCount == null) {
      throw ('$runtimeType must be connected with a ${widgets.ListView} or ${widgets.GridView}');
    }
    if (index < 0 || index >= _state.itemCount!) {
      throw RangeError.value(index);
    }
    if (!reorderableGetter(index)) {
      throw ('The item at index $index is not reorderable');
    }
    if (!reorderableGetter(destIndex)) {
      throw ('The item at index $destIndex is not reorderable');
    }
    if (index == destIndex) return;

    final itemAtIndex = ensureItemAt(index: index);
    final itemAtDestIndex = ensureItemAt(index: destIndex);

    final permutations = _state.moveItem(
      index: index,
      destIndex: destIndex,
      reorderableGetter: reorderableGetter,
      itemFactory: createItem,
    );

    overlayedItemsLayer!.rebuild(() {
      for (var renderedItem
          in _state.renderedItems.where(isNotDragged).where(isNotSwiped)) {
        _state.putOverlayedItemIfAbsent(
          key: renderedItem.key,
          ifAbsent: () => createOverlayedItem(renderedItem),
        )
          ..index = permutations.indexOf(renderedItem.key) ?? renderedItem.index
          ..setInteractive(false, notify: false);
      }

      if (!_state.isRendered(key: itemAtIndex.key)) {
        final fakeGeometry = getFakeAnchorGeometryOfNotRenderedItem(
          notRenderedItemIndex: index,
          anyRenderedItemIndex: _state.renderedItems.first.index,
        );

        _state
            .putOverlayedItem(
              model.OverlayedItem(
                index: permutations.indexOf(itemAtIndex.key)!,
                key: itemAtIndex.key,
                position: fakeGeometry.topLeft,
                constraints: widgets.BoxConstraints.tight(fakeGeometry.size),
                builder: model.ItemBuilder.adaptOtherItemBuilder(itemAtIndex),
                interactive: false,
              ),
            )
            .addListener(overlayedItemsLayer!.rebuild);
      }

      if (!_state.isRendered(key: itemAtDestIndex.key)) {
        final fakeGeometry = getFakeAnchorGeometryOfNotRenderedItem(
          notRenderedItemIndex: destIndex,
          anyRenderedItemIndex: _state.renderedItems.first.index,
        );

        _state
            .putOverlayedItem(
              model.OverlayedItem(
                index: permutations.indexOf(itemAtDestIndex.key)!,
                key: itemAtDestIndex.key,
                position: fakeGeometry.topLeft,
                constraints: widgets.BoxConstraints.tight(fakeGeometry.size),
                builder:
                    model.ItemBuilder.adaptOtherItemBuilder(itemAtDestIndex),
                interactive: false,
              ),
            )
            .addListener(overlayedItemsLayer!.rebuild);
      }
    });

    itemsLayer!.rebuild(() => onReorder!.call(permutations));
  }

  void dispose() => _state.dispose();

  Iterable<model.OverlayedItem> get overlayedItemsOrderedByZIndex =>
      _state.overlayedItems.toList()
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  bool isDragged(RenderedItem item) => _state.isDragged(key: item.key);

  bool isSwiped(RenderedItem item) => _state.isSwiped(key: item.key);

  bool isNotDragged(RenderedItem item) => !isDragged(item);

  bool isNotSwiped(RenderedItem item) => !isSwiped(item);

  bool isRendered(model.OverlayedItem item) => _state.isRendered(key: item.key);

  bool isNotRendered(model.OverlayedItem item) => !isRendered(item);

  widgets.GlobalKey<ItemsLayerState> get itemsLayerKey => _state.itemsLayerKey;

  widgets.GlobalKey<OverlayedItemsLayerState> get overlayedItemsLayerKey =>
      _state.overlayedItemsLayerKey;

  ItemsLayerState? get itemsLayer => _state.itemsLayerState;

  OverlayedItemsLayerState? get overlayedItemsLayer =>
      _state.overlayedItemsLayerState;

  bool didSwipeToRemove(
    model.OverlayedItem item, {
    required Velocity velocity,
  }) =>
      switch (item.swipeToRemoveDirection) {
        AxisDirection.left => item.swipeExtent < -swipeToRemoveExtent ||
            velocity.pixelsPerSecond.dx < -swipeToRemoveVelocity,
        AxisDirection.right => item.swipeExtent > swipeToRemoveExtent ||
            velocity.pixelsPerSecond.dx > swipeToRemoveVelocity,
        AxisDirection.up => item.swipeExtent < -swipeToRemoveExtent ||
            velocity.pixelsPerSecond.dy < -swipeToRemoveVelocity,
        AxisDirection.down => item.swipeExtent > swipeToRemoveExtent ||
            velocity.pixelsPerSecond.dy > swipeToRemoveVelocity,
        _ => false,
      };

  model.Item ensureItemAt({required int index}) =>
      _state.itemAt(index: index) ?? spawnItemAt(index: index);

  model.Item spawnItemAt({required int index}) {
    final item = createItem(index);
    _state.putItem(item);
    _state.setIndex(itemKey: item.key, index: index);
    return item;
  }

  model.Item createItem(int index) => model.Item(
        key: keyGetter(index),
        builder: model.ItemBuilder.adaptIndexedWidgetBuilder(
          childrenDelegate.originalBuilder,
        ),
      );

  model.OverlayedItem createOverlayedItem(
    RenderedItem renderedItem, {
    int? index,
    bool interactive = true,
    bool outgoing = false,
    int zIndex = defaultZIndex,
    model.RecognizerFactory? recognizerFactory,
    model.ItemBuilder? builder,
  }) =>
      model.OverlayedItem(
        index: index ?? renderedItem.index,
        key: renderedItem.key,
        position: overlayedItemsLayer!.globalToLocal(
          renderedItem.globalPosition!,
        )!,
        constraints: widgets.BoxConstraints.tight(renderedItem.size!),
        zIndex: zIndex,
        interactive: interactive,
        outgoing: outgoing,
        builder: builder ??
            model.ItemBuilder.adaptOtherItemBuilder(
              _state.itemBy(key: renderedItem.key)!,
            ),
        recognizerFactory: recognizerFactory,
      )..addListener(overlayedItemsLayer!.rebuild);

  void registerRenderedItem(RenderedItem item) => _state.putRenderedItem(item);

  void unregisterRenderedItem(RenderedItem item) {
    final registeredRenderedItem = _state.renderedItemBy(key: item.key);
    if (registeredRenderedItem == item) {
      _state.removeRenderedItemBy(key: item.key);
    }
  }

  void reorderAndAutoScrollIfNecessary() {
    reorderDraggedItemIfNecessary();
    autoScrollIfNecessary();
  }

  void reorderDraggedItemIfNecessary() {
    if (onReorder == null) return;
    if (_state.draggedItem == null) return;

    final item = _state.draggedItem!;

    if (!reorderableGetter(item.index)) return;

    final pointerPosition = item.globalPointerPosition!;
    final renderedItem = _state.renderedItemAt(position: pointerPosition);

    if (renderedItem?.key == _state.itemUnderThePointerKey) return;
    _state.itemUnderThePointerKey = renderedItem?.key;

    if (renderedItem == null) return;
    if (renderedItem.key == item.key) return;
    if (!renderedItem.reorderable) return;

    reorderItem(item.index, destIndex: renderedItem.index);

    addPostFrame(() => _state.itemUnderThePointerKey =
        _state.renderedItemAt(position: pointerPosition)?.key);
  }

  void unoverlay(model.OverlayedItem item) {
    if (!_state.isOverlayed(key: item.key)) return;
    overlayedItemsLayer
        ?.rebuild(() => _state.removeOverlayedItem(key: item.key));
    _state.renderedItemBy(key: item.key)?.rebuild();
  }

  widgets.Rect getFakeAnchorGeometryOfNotRenderedItem({
    required int notRenderedItemIndex,
    required int anyRenderedItemIndex,
    widgets.Size? itemSize,
  }) {
    itemSize ??= _state.gridLayout
            ?.getChildSize(notRenderedItemIndex, scrollDirection) ??
        measureItemWidgetAt(index: notRenderedItemIndex);

    final screenGeometry = Offset.zero & getScreenSize();
    final fakePosition = switch (scrollController!.axisDirection) {
      AxisDirection.down => notRenderedItemIndex < anyRenderedItemIndex
          ? screenGeometry.topCenter -
              Offset(itemSize.width / 2, itemSize.height)
          : screenGeometry.bottomCenter - Offset(itemSize.width / 2, 0),
      AxisDirection.right => notRenderedItemIndex < anyRenderedItemIndex
          ? screenGeometry.centerLeft -
              Offset(itemSize.width, itemSize.height / 2)
          : screenGeometry.centerRight - Offset(0, itemSize.height / 2),
      AxisDirection.up => notRenderedItemIndex < anyRenderedItemIndex
          ? screenGeometry.bottomCenter - Offset(itemSize.width / 2, 0)
          : screenGeometry.topCenter -
              Offset(itemSize.width / 2, itemSize.height),
      AxisDirection.left => notRenderedItemIndex < anyRenderedItemIndex
          ? screenGeometry.centerRight - Offset(0, itemSize.height / 2)
          : screenGeometry.centerLeft -
              Offset(itemSize.width, itemSize.height / 2),
    };

    return fakePosition & itemSize;
  }

  Size measureItemWidgetAt({required int index}) => MeasureUtil.measureWidget(
        context: _scrollController!.scrollableState!.context,
        builder: (context) =>
            _childrenDelegate.originalBuilder(context, index)!,
        constraints: scrollDirection == Axis.vertical
            ? BoxConstraints(maxWidth: _state.constraints!.maxWidth)
            : BoxConstraints(maxHeight: _state.constraints!.maxHeight),
      );

  Size getScreenSize() {
    final screenView =
        widgets.WidgetsBinding.instance.platformDispatcher.views.first;
    return screenView.physicalSize / screenView.devicePixelRatio;
  }
}

extension RenderedItemLifecycleHandlers on AnimatedReorderableController {
  void handleRenderedItemInit(RenderedItem item) => registerRenderedItem(item);

  void handleRenderedItemDidUpdate(RenderedItem item) {
    unregisterRenderedItem(item);
    registerRenderedItem(item);
  }

  void handleRenderedItemDispose(RenderedItem item) =>
      unregisterRenderedItem(item);

  void handleRenderedItemDeactivate(RenderedItem item) =>
      unregisterRenderedItem(item);

  void handleRenderedItemDidBuild(item) {
    if (isDragged(item)) return;
    if (isSwiped(item)) return;

    final globalPosition = item.globalPosition;
    if (globalPosition == null) return;

    final overlayedItem = _state.overlayedItemBy(key: item.key);
    if (overlayedItem == null) return;

    final anchorPosition = overlayedItemsLayer!.globalToLocal(globalPosition)!;

    if (overlayedItem.anchorPosition != anchorPosition) {
      overlayedItem
          .animateTo(
            anchorPosition,
            vsync: vsync,
            duration: motionAnimationDuration,
            curve: motionAnimationCurve,
          )
          .whenComplete(
            () => unoverlay(overlayedItem),
          );
    } else if (overlayedItem.motionAnimationStatus?.idle ?? true) {
      unoverlay(overlayedItem);
    }
  }
}

extension ItemsLayerLyfecycleHandlers on AnimatedReorderableController {
  void handleDidBuildItemsLayer() {
    for (var overlayedItem in _state.overlayedItems
        .where(isNotRendered)
        .where((x) => !x.outgoing)
        .toList()) {
      final fakeGeometry = getFakeAnchorGeometryOfNotRenderedItem(
        notRenderedItemIndex: overlayedItem.index,
        anyRenderedItemIndex: _state.renderedItems.first.index,
        itemSize: overlayedItem.constraints.biggest,
      );

      overlayedItem
          .animateTo(
            fakeGeometry.topLeft,
            vsync: vsync,
            duration: motionAnimationDuration,
            curve: motionAnimationCurve,
          )
          .whenComplete(
            () => unoverlay(overlayedItem),
          );
    }
  }
}

extension OverlayedItemDragHandlers on AnimatedReorderableController {
  void handleItemDragStart(
    widgets.DragStartDetails details,
    model.OverlayedItem item,
  ) {
    onItemDragStart?.call(details, item.index);

    item.stopMotion();

    _state.draggedItem = item;

    if (!_state.isOverlayed(key: item.key)) {
      overlayedItemsLayer?.rebuild(
        () => _state.putOverlayedItem(item)
          ..setZIndex(
            maxZIndex,
            notify: false,
          ),
      );
      _state.renderedItemBy(key: item.key)?.rebuild();
    } else {
      item.setZIndex(maxZIndex);
    }

    item.animateDecoration(
      decorator: draggedItemDecorator,
      duration: draggedItemDecorationAnimationDuration,
      vsync: vsync,
    );
  }

  void handleItemDragUpdate(
    widgets.DragUpdateDetails details,
    model.OverlayedItem item,
  ) {
    onItemDragUpdate?.call(details, item.index);

    item.shift(details.delta);

    reorderAndAutoScrollIfNecessary();
  }

  void handleItemDragEnd(
    widgets.DragEndDetails details,
    model.OverlayedItem item,
  ) {
    onItemDragEnd?.call(details, item.index);

    _state.draggedItem = null;

    stopAutoScroll(forceStopAnimation: true);

    Future.wait([
      item.animateUndecoration(),
      item.animateFlingTo(
        overlayedItemsLayer!.globalToLocal(
          _state.renderedItemBy(key: item.key)!.globalPosition!,
        )!,
        velocity: details.velocity,
        screenSize: getScreenSize(),
        vsync: vsync,
      ),
    ]).whenComplete(
      () => unoverlay(item),
    );
  }
}

extension OverlayedItemSwipeHandlers on AnimatedReorderableController {
  void handleItemSwipeStart(
    widgets.DragStartDetails details,
    model.OverlayedItem item,
  ) {
    onItemSwipeStart?.call(details, item.index);

    item.stopMotion();

    _state.swipedItem = item;

    if (!_state.isOverlayed(key: item.key)) {
      overlayedItemsLayer?.rebuild(
        () => _state.putOverlayedItem(item)
          ..setZIndex(
            maxZIndex,
            notify: false,
          ),
      );
      _state.renderedItemBy(key: item.key)?.rebuild();
    } else {
      item.setZIndex(maxZIndex);
    }

    item.animateDecoration(
      decorator: swipedItemDecorator,
      duration: swipedItemDecorationAnimationDuration,
      vsync: vsync,
    );
  }

  void handleItemSwipeUpdate(
    widgets.DragUpdateDetails details,
    model.OverlayedItem item,
  ) {
    onItemSwipeUpdate?.call(details, item.index);

    item.shift(details.delta);
  }

  void handleItemSwipeEnd(
    widgets.DragEndDetails details,
    model.OverlayedItem item,
  ) {
    onItemSwipeEnd?.call(details, item.index);

    _state.swipedItem = null;

    final undecorateFuture = item.animateUndecoration();
    final screenSize = getScreenSize();

    if (didSwipeToRemove(item, velocity: details.velocity)) {
      onSwipeToRemove!.call(item.index);

      item.animateFlingTo(
        switch (item.swipeToRemoveDirection!) {
          AxisDirection.left =>
            Offset(-item.constraints.maxWidth, item.position.dy),
          AxisDirection.right => Offset(screenSize.width, item.position.dy),
          AxisDirection.up =>
            Offset(item.position.dx, -item.constraints.maxHeight),
          AxisDirection.down => Offset(item.position.dx, screenSize.height),
        },
        velocity: details.velocity,
        screenSize: screenSize,
        vsync: vsync,
      );
    } else {
      Future.wait([
        undecorateFuture,
        item.animateFlingTo(
          overlayedItemsLayer!.globalToLocal(
            _state.renderedItemBy(key: item.key)!.globalPosition!,
          )!,
          velocity: details.velocity,
          screenSize: screenSize,
          vsync: vsync,
        )
      ]).whenComplete(
        () => unoverlay(item),
      );
    }
  }
}

extension ScrollHandler on AnimatedReorderableController {
  void handleScroll() {
    final delta = markScrollOffset(scrollOffset);

    if (_state.shiftItemsOnScroll) {
      for (var x in _state.overlayedItems
          .where((x) => !_state.isDragged(key: x.key))
          .where((x) => !_state.isSwiped(key: x.key))) {
        x.shift(-delta);
      }
    }
  }
}

extension ConstraintsChangeHandler on AnimatedReorderableController {
  void handleConstraintsChange(BoxConstraints constraints) {
    if (_state.constraints != null &&
        scrollController != null &&
        scrollController!.hasClients) {
      final scaleFactor = scrollDirection == Axis.vertical
          ? constraints.maxWidth / _state.constraints!.maxWidth
          : constraints.maxHeight / _state.constraints!.maxHeight;

      for (var x in _state.overlayedItems) {
        x.scale(scaleFactor);
      }

      _state.shiftItemsOnScroll = false;
      scrollController!.scaleScrollPosition(scaleFactor);
      _state.shiftItemsOnScroll = true;
    }

    _state.constraints = constraints;
  }
}

extension SliverGridLayoutChangeHandler on AnimatedReorderableController {
  void handleSliverGridLayoutChange(SliverGridLayout layout) =>
      _state.gridLayout = layout;
}

extension ChildrenDelegate on AnimatedReorderableController {
  OverridedSliverChildBuilderDelegate get childrenDelegate => _childrenDelegate;
  set childrenDelegate(OverridedSliverChildBuilderDelegate value) =>
      _childrenDelegate = value;

  widgets.SliverChildDelegate overrideChildrenDelegate(
          widgets.SliverChildDelegate delegate) =>
      childrenDelegate = OverridedSliverChildBuilderDelegate.override(
        delegate: delegate,
        overridedChildBuilder: buildItemWidget,
        overridedChildCountGetter: () => _state.itemCount,
      );

  widgets.Widget buildItemWidget(widgets.BuildContext context, int index) {
    final item = ensureItemAt(index: index);

    return ItemWidget(
      key: item.key,
      index: index,
      reorderableGetter: reorderableGetter,
      draggableGetter: draggableGetter,
      swipeToRemoveDirectionGetter: swipeToRemoveDirectionGetter,
      overlayedGetter: (key) => _state.isOverlayed(key: key),
      builder: item.builder.build,
      onInit: handleRenderedItemInit,
      didUpdate: handleRenderedItemDidUpdate,
      onDispose: handleRenderedItemDispose,
      onDeactivate: handleRenderedItemDeactivate,
      didBuild: handleRenderedItemDidBuild,
      recognizeDrag: (renderedItem, event) {
        createOverlayedItem(
          renderedItem,
          recognizerFactory: createReoderGestureRecognizer,
        ).recognizeDrag(
          event,
          context: context,
          onDragStart: (details, overlayedItem) {
            overlayedItem.recognizerFactory = createImmediateGestureRecognizer;
            handleItemDragStart(details, overlayedItem);
          },
          onDragUpdate: handleItemDragUpdate,
          onDragEnd: handleItemDragEnd,
        );
      },
      recognizeSwipe: (renderedItem, event) {
        createOverlayedItem(
          renderedItem,
          recognizerFactory: switch (renderedItem.swipeToRemoveDirection) {
            AxisDirection.up ||
            AxisDirection.down =>
              createVerticalSwipeToRemoveGestureRecognizer,
            AxisDirection.left ||
            AxisDirection.right =>
              createHorizontalSwipeToRemoveGestureRecognizer,
            _ => null,
          },
        ).recognizeSwipe(
          event,
          context: context,
          swipeDirection: swipeToRemoveDirectionGetter.call(index)!,
          onSwipeStart: handleItemSwipeStart,
          onSwipeUpdate: handleItemSwipeUpdate,
          onSwipeEnd: handleItemSwipeEnd,
        );
      },
    );
  }
}

extension Scrolling on AnimatedReorderableController {
  widgets.ScrollController? get scrollController => _scrollController;

  set scrollController(widgets.ScrollController? value) {
    if (_scrollController == value) return;
    addPostFrame(() {
      setupAutoscroller();
      markScrollOffset(scrollOffset);
    });
    _scrollController?.removeListener(handleScroll);
    (_scrollController = value)?.addListener(handleScroll);
  }

  Offset get scrollOffset => scrollController!.scrollOffset!;

  void setupAutoscroller() {
    if (_scrollController == null) return;
    if (!_scrollController!.hasClients) return;

    _autoScroller = widgets.EdgeDraggingAutoScroller(
      _scrollController!.position.context as widgets.ScrollableState,
      velocityScalar: autoScrollerVelocityScalar,
      onScrollViewScrolled: () => reorderAndAutoScrollIfNecessary(),
    );
  }

  void autoScrollIfNecessary() {
    if (_state.draggedItem == null) return;
    if (!_state.draggedItem!.constraints.isTight) return;

    final size = _state.draggedItem!.constraints.biggest;
    final position = overlayedItemsLayer!.localToGlobal(
      _state.draggedItem!.position,
    )!;

    _autoScroller?.startAutoScrollIfNecessary((position & size).deflate(alpha));
  }

  void stopAutoScroll({bool forceStopAnimation = false}) {
    _autoScroller?.stopAutoScroll();

    if (forceStopAnimation) {
      final pixels = scrollController!.position.pixels;
      scrollController!.position.jumpTo(pixels);
    }
  }

  Offset markScrollOffset(Offset scrollOffset) {
    if (_scrollController == null) return Offset.zero;
    if (!_scrollController!.hasClients) return Offset.zero;

    final delta = scrollOffset - _state.scrollOffset;
    _state.scrollOffset = scrollOffset;
    return delta;
  }
}
