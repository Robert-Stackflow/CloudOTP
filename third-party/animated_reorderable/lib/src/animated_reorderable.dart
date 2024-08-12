import 'package:flutter/widgets.dart';

import 'animated_reorderable_controller.dart';
import 'const.dart';
import 'model/model.dart' as model;
import 'model/permutations.dart';
import 'util/overrided_sliver_child_builder_delegate.dart';
import 'util/sliver_grid_delegate_decorator.dart';
import 'util/misc.dart';
import 'widget/items_layer.dart';
import 'widget/overlayed_items_layer.dart';

/// A function utilized by [AnimatedReorderable] to obtain the unique key
/// for the item at the specified [index] within the list or grid.
typedef KeyGetter = Key Function(int index);

/// A function signature to get the bool property
/// of the item at the specified [index].
typedef BoolGetter = bool Function(int index);

/// A function that determines the axis direction
/// associated with an item at a given [index].
typedef AxisDirectionGetter = AxisDirection? Function(int index);

/// A callback function that is called when the items are reordered.
///
/// Implementations should apply the [permutations] to the collection of items.
///
/// ```dart
/// final List<MyDataObject> items = <MyDataObject>[/* ... */];
///
/// void handleReorder(Permutations permutations) =>
///   permutations.apply(items);
/// ```
typedef ReorderCallback = void Function(Permutations permutations);

/// A callback function that is called when an item is swiped for removal.
///
/// Implementations should remove the corresponding collection item at [index].
///
/// ```dart
/// final List<MyDataObject> items = <MyDataObject>[/* ... */];
///
/// void onSwipedToRemove(int index) =>
///   items.removeAt(index);
/// ```
typedef SwipeToRemoveCallback = void Function(int index);

/// A callback function that is called when dragging of an item starts.
///
/// The [index] parameter of the callback is the index of the dragged item.
typedef ItemDragStartCallback = void Function(
    DragStartDetails details, int index);

/// A callback function that is called when dragging of an item is updated.
///
/// The [index] parameter of the callback is the index of the dragged item.
typedef ItemDragUpdateCallback = void Function(
    DragUpdateDetails details, int index);

/// A callback function that is called when dragging of an item ends.
///
/// The [index] parameter of the callback is the index of the dragged item.
typedef ItemDragEndCallback = void Function(DragEndDetails details, int index);

/// The [AnimatedReorderable] wrapper makes [ListView] or [GridView] animated,
/// adds reordering and swiping capabilities.
///
/// - It animates item insertions, removals, and reordering with customizable animations.
/// - It allows users to interactively reorder items with drag-and-drop gestures.
/// - It supports swiping to remove items with customizable swipe actions.
///
/// This widget's [AnimatedReorderableState] can be used to dynamically insert,
/// remove or reorder items. To refer to the [AnimatedReorderableState] either provide a
/// [GlobalKey] or use the static [of] method from an item's input callback.
abstract class AnimatedReorderable extends StatefulWidget {
  /// Creates an [AnimatedReorderable] for a [ListView].
  factory AnimatedReorderable.list({
    Key? key,
    required KeyGetter keyGetter,
    Duration motionAnimationDuration = defaultMotionAnimationDuration,
    Curve motionAnimationCurve = defaultMotionAnimationCurve,
    double autoScrollerVelocityScalar = defaultAutoScrollVelocityScalar,
    BoolGetter? draggableGetter,
    BoolGetter? reorderableGetter,
    ReorderCallback? onReorder,
    AxisDirectionGetter? swipeToRemoveDirectionGetter,
    double swipeToRemoveExtent = defaultSwipeToRemoveExtent,
    double swipeToRemoveVelocity = defaultSwipeToRemoveVelocity,
    SpringDescription swipeToRemoveSpringDescription =
        defaultFlingSpringDescription,
    SwipeToRemoveCallback? onSwipeToRemove,
    model.AnimatedItemDecorator? draggedItemDecorator =
        defaultDraggedItemDecorator,
    Duration draggedItemDecorationAnimationDuration =
        defaultDraggedItemDecorationAnimationDuration,
    model.AnimatedItemDecorator? swipedItemDecorator =
        defaultDraggedItemDecorator,
    Duration swipedItemDecorationAnimationDuration =
        defaultSwipedItemDecorationAnimationDuration,
    ItemDragStartCallback? onItemDragStart,
    ItemDragUpdateCallback? onItemDragUpdate,
    ItemDragEndCallback? onItemDragEnd,
    ItemDragStartCallback? onItemSwipeStart,
    ItemDragUpdateCallback? onItemSwipeUpdate,
    ItemDragEndCallback? onItemSwipeEnd,
    required ListView listView,
  }) =>
      _ListView(
        key: key,
        keyGetter: keyGetter,
        motionAnimationDuration: motionAnimationDuration,
        motionAnimationCurve: motionAnimationCurve,
        autoScrollerVelocityScalar: autoScrollerVelocityScalar,
        draggableGetter: draggableGetter,
        reorderableGetter: reorderableGetter,
        onReorder: onReorder,
        swipeToRemoveDirectionGetter: swipeToRemoveDirectionGetter,
        swipeToRemoveExtent: swipeToRemoveExtent,
        swipeToRemoveVelocity: swipeToRemoveVelocity,
        swipeToRemoveSpringDescription: swipeToRemoveSpringDescription,
        onSwipeToRemove: onSwipeToRemove,
        draggedItemDecorator: draggedItemDecorator,
        draggedItemDecorationAnimationDuration:
            draggedItemDecorationAnimationDuration,
        swipedItemDecorator: swipedItemDecorator,
        swipedItemDecorationAnimationDuration:
            swipedItemDecorationAnimationDuration,
        onItemDragStart: onItemDragStart,
        onItemDragUpdate: onItemDragUpdate,
        onItemDragEnd: onItemDragEnd,
        onItemSwipeStart: onItemSwipeStart,
        onItemSwipeUpdate: onItemSwipeUpdate,
        onItemSwipeEnd: onItemSwipeEnd,
        listView: listView,
      );

  /// Creates an [AnimatedReorderable] for a [GridView].
  factory AnimatedReorderable.grid({
    Key? key,
    required KeyGetter keyGetter,
    Duration motionAnimationDuration = defaultMotionAnimationDuration,
    Curve motionAnimationCurve = defaultMotionAnimationCurve,
    double autoScrollerVelocityScalar = defaultAutoScrollVelocityScalar,
    BoolGetter? draggableGetter,
    BoolGetter? reorderableGetter,
    ReorderCallback? onReorder,
    AxisDirectionGetter? swipeToRemoveDirectionGetter,
    double swipeToRemoveExtent = defaultSwipeToRemoveExtent,
    double swipeToRemoveVelocity = defaultSwipeToRemoveVelocity,
    SpringDescription swipeToRemoveSpringDescription =
        defaultFlingSpringDescription,
    SwipeToRemoveCallback? onSwipeToRemove,
    model.AnimatedItemDecorator? draggedItemDecorator =
        defaultDraggedItemDecorator,
    Duration draggedItemDecorationAnimationDuration =
        defaultDraggedItemDecorationAnimationDuration,
    model.AnimatedItemDecorator? swipedItemDecorator =
        defaultDraggedItemDecorator,
    Duration swipedItemDecorationAnimationDuration =
        defaultSwipedItemDecorationAnimationDuration,
    ItemDragStartCallback? onItemDragStart,
    ItemDragUpdateCallback? onItemDragUpdate,
    ItemDragEndCallback? onItemDragEnd,
    ItemDragStartCallback? onItemSwipeStart,
    ItemDragUpdateCallback? onItemSwipeUpdate,
    ItemDragEndCallback? onItemSwipeEnd,
    required GridView gridView,
  }) =>
      _GridView(
        key: key,
        keyGetter: keyGetter,
        motionAnimationDuration: motionAnimationDuration,
        motionAnimationCurve: motionAnimationCurve,
        autoScrollerVelocityScalar: autoScrollerVelocityScalar,
        draggableGetter: draggableGetter,
        reorderableGetter: reorderableGetter,
        onReorder: onReorder,
        swipeToRemoveDirectionGetter: swipeToRemoveDirectionGetter,
        swipeToRemoveExtent: swipeToRemoveExtent,
        swipeToRemoveVelocity: swipeToRemoveVelocity,
        swipeToRemoveSpringDescription: swipeToRemoveSpringDescription,
        onSwipeToRemove: onSwipeToRemove,
        draggedItemDecorator: draggedItemDecorator,
        draggedItemDecorationAnimationDuration:
            draggedItemDecorationAnimationDuration,
        swipedItemDecorator: swipedItemDecorator,
        swipedItemDecorationAnimationDuration:
            swipedItemDecorationAnimationDuration,
        onItemDragStart: onItemDragStart,
        onItemDragUpdate: onItemDragUpdate,
        onItemDragEnd: onItemDragEnd,
        onItemSwipeStart: onItemSwipeStart,
        onItemSwipeUpdate: onItemSwipeUpdate,
        onItemSwipeEnd: onItemSwipeEnd,
        gridView: gridView,
      );

  /// Creates an [AnimatedReorderable] for a [GridView].
  factory AnimatedReorderable.reorderableGrid({
    Key? key,
    required KeyGetter keyGetter,
    Duration motionAnimationDuration = defaultMotionAnimationDuration,
    Curve motionAnimationCurve = defaultMotionAnimationCurve,
    double autoScrollerVelocityScalar = defaultAutoScrollVelocityScalar,
    BoolGetter? draggableGetter,
    BoolGetter? reorderableGetter,
    ReorderCallback? onReorder,
    AxisDirectionGetter? swipeToRemoveDirectionGetter,
    double swipeToRemoveExtent = defaultSwipeToRemoveExtent,
    double swipeToRemoveVelocity = defaultSwipeToRemoveVelocity,
    SpringDescription swipeToRemoveSpringDescription =
        defaultFlingSpringDescription,
    SwipeToRemoveCallback? onSwipeToRemove,
    model.AnimatedItemDecorator? draggedItemDecorator =
        defaultDraggedItemDecorator,
    Duration draggedItemDecorationAnimationDuration =
        defaultDraggedItemDecorationAnimationDuration,
    model.AnimatedItemDecorator? swipedItemDecorator =
        defaultDraggedItemDecorator,
    Duration swipedItemDecorationAnimationDuration =
        defaultSwipedItemDecorationAnimationDuration,
    ItemDragStartCallback? onItemDragStart,
    ItemDragUpdateCallback? onItemDragUpdate,
    ItemDragEndCallback? onItemDragEnd,
    ItemDragStartCallback? onItemSwipeStart,
    ItemDragUpdateCallback? onItemSwipeUpdate,
    ItemDragEndCallback? onItemSwipeEnd,
    required GridView gridView,
  }) =>
      _GridView(
        key: key,
        keyGetter: keyGetter,
        motionAnimationDuration: motionAnimationDuration,
        motionAnimationCurve: motionAnimationCurve,
        autoScrollerVelocityScalar: autoScrollerVelocityScalar,
        draggableGetter: draggableGetter,
        reorderableGetter: reorderableGetter,
        onReorder: onReorder,
        swipeToRemoveDirectionGetter: swipeToRemoveDirectionGetter,
        swipeToRemoveExtent: swipeToRemoveExtent,
        swipeToRemoveVelocity: swipeToRemoveVelocity,
        swipeToRemoveSpringDescription: swipeToRemoveSpringDescription,
        onSwipeToRemove: onSwipeToRemove,
        draggedItemDecorator: draggedItemDecorator,
        draggedItemDecorationAnimationDuration:
        draggedItemDecorationAnimationDuration,
        swipedItemDecorator: swipedItemDecorator,
        swipedItemDecorationAnimationDuration:
        swipedItemDecorationAnimationDuration,
        onItemDragStart: onItemDragStart,
        onItemDragUpdate: onItemDragUpdate,
        onItemDragEnd: onItemDragEnd,
        onItemSwipeStart: onItemSwipeStart,
        onItemSwipeUpdate: onItemSwipeUpdate,
        onItemSwipeEnd: onItemSwipeEnd,
        gridView: gridView,
      );

  const AnimatedReorderable({
    super.key,
    required this.keyGetter,
    this.draggableGetter,
    this.reorderableGetter,
    this.onReorder,
    this.swipeToRemoveDirectionGetter,
    this.swipeToRemoveSpringDescription = defaultFlingSpringDescription,
    this.swipeToRemoveExtent = defaultSwipeToRemoveExtent,
    this.swipeToRemoveVelocity = defaultSwipeToRemoveVelocity,
    this.onSwipeToRemove,
    this.draggedItemDecorator,
    this.draggedItemDecorationAnimationDuration =
        defaultDraggedItemDecorationAnimationDuration,
    this.swipedItemDecorator,
    this.swipedItemDecorationAnimationDuration =
        defaultSwipedItemDecorationAnimationDuration,
    this.motionAnimationDuration = defaultMotionAnimationDuration,
    this.motionAnimationCurve = defaultMotionAnimationCurve,
    this.autoScrollerVelocityScalar = defaultAutoScrollVelocityScalar,
    this.onItemDragStart,
    this.onItemDragUpdate,
    this.onItemDragEnd,
    this.onItemSwipeStart,
    this.onItemSwipeUpdate,
    this.onItemSwipeEnd,
  });

  /// A function that provides the unique key for each item in the list or grid.
  final KeyGetter keyGetter;

  /// A function that determines whether an item at a given index is draggable.
  ///
  /// If not provided all items are draggable by default.
  final BoolGetter? draggableGetter;

  /// A function that determines whether an item at a given index is reorderable.
  ///
  /// If not provided all items are reorderable by default.
  final BoolGetter? reorderableGetter;

  /// A callback function called when items are reordered.
  final ReorderCallback? onReorder;

  /// The duration of the motion animation for item reordering.
  ///
  /// This [Duration] defines the time it takes for the motion animation to complete
  /// when items are being reordered within the [AnimatedReorderable] widget.
  final Duration motionAnimationDuration;

  /// The curve of the motion animation for item reordering.
  final Curve motionAnimationCurve;

  /// {@macro flutter.widgets.EdgeDraggingAutoScroller.velocityScalar}
  ///
  /// {@macro flutter.widgets.SliverReorderableList.autoScrollerVelocityScalar.default}
  final double autoScrollerVelocityScalar;

  /// A callback that allows to add an animated decoration around
  /// an item when it is being dragged.
  final model.AnimatedItemDecorator? draggedItemDecorator;

  /// The duration of the animation for decorating the dragged item.
  final Duration draggedItemDecorationAnimationDuration;

  /// A callback that allows to add an animated decoration around
  /// an item when it is being swiped.
  final model.AnimatedItemDecorator? swipedItemDecorator;

  /// The duration of the animation for decorating the swiped item.
  final Duration swipedItemDecorationAnimationDuration;

  /// Callback function invoked when dragging a list or grid item starts.
  final ItemDragStartCallback? onItemDragStart;

  /// Callback function invoked when dragging a list or grid item is updated.
  final ItemDragUpdateCallback? onItemDragUpdate;

  /// Callback function invoked when dragging a list or grid item ends.
  final ItemDragEndCallback? onItemDragEnd;

  /// Callback function invoked when swiping a list or grid item starts.
  final ItemDragStartCallback? onItemSwipeStart;

  /// Callback function invoked when swiping a list or grid item is updated.
  final ItemDragUpdateCallback? onItemSwipeUpdate;

  /// Callback function invoked when swiping a list or grid item ends.
  final ItemDragEndCallback? onItemSwipeEnd;

  /// A callback function called when an item is swiped for removal.
  ///
  ///  It occurs if at least one of the following two cases happens:
  /// * Swiped in the remove direction, and the extent is greater than or equal to [swipeToRemoveExtent].
  /// * Swiped in the remove direction, and the velocity is greater than or equal to [swipeToRemoveVelocity].
  final SwipeToRemoveCallback? onSwipeToRemove;

  /// The spring description used for the swipe-to-remove animation.
  ///
  /// This [SpringDescription] defines the animation characteristics,
  /// including the mass, stiffness and damping, used in the
  /// swipe-to-remove animation within the [AnimatedReorderable] widget.
  final SpringDescription swipeToRemoveSpringDescription;

  /// The minimal extent, as a ratio of item movement, to trigger swipe-to-remove.
  ///
  /// This property represents the minimum ratio of the item's movement along
  /// the swipe direction required to initiate the swipe-to-remove action.
  /// When a user swipes an item to an extent greater than or equal to this
  /// ratio, the swipe-to-remove action will be initiated for the corresponding
  /// item within the [AnimatedReorderable] widget.
  final double swipeToRemoveExtent;

  /// The minimum swiping velocity required to trigger the swipe-to-remove action.
  ///
  /// If the swiping velocity of an item exceeds this value, the swipe-to-remove
  /// action will be triggered for the corresponding item within the
  /// [AnimatedReorderable] widget.
  final double swipeToRemoveVelocity;

  /// A function that determines the swipe-to-remove direction for an item at a given index.
  final AxisDirectionGetter? swipeToRemoveDirectionGetter;

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [AnimatedReorderable] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedReorderable] surrounds the context given, then this function will
  /// assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// This method does not create a dependency, and so will not cause rebuilding
  /// when the state changes.
  ///
  /// See also:
  ///
  ///  * [maybeOf], a similar function that will return null if no
  ///    [AnimatedReorderable] ancestor is found.
  static AnimatedReorderableState of(BuildContext context) {
    final AnimatedReorderableState? result =
        AnimatedReorderable.maybeOf(context);
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'AnimatedReorderable.of() called with a context that does not contain an AnimatedReorderable.'),
          ErrorDescription(
            'No AnimatedReorderable ancestor could be found starting from the context that was passed to AnimatedReorderable.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the AnimatedReorderable. Please see the AnimatedReorderable documentation for examples '
            'of how to refer to an AnimatedReorderableState object:\n'
            '  https://pub.dev/packages/animated_reorderable',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  /// The [AnimatedReorderableState] from the closest instance of [AnimatedReorderable] that encloses the given
  /// context.
  ///
  /// This method is typically used by [AnimatedReorderable] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [AnimatedReorderable] surrounds the context given, then this function will
  /// return null.
  ///
  /// This method can be expensive (it walks the element tree).
  ///
  /// This method does not create a dependency, and so will not cause rebuilding
  /// when the state changes.
  ///
  /// See also:
  ///
  ///  * [of], a similar function that will throw if no [AnimatedReorderable] ancestor
  ///    is found.
  static AnimatedReorderableState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AnimatedReorderableState>();
  }
}

/// The [AnimatedReorderableState] for [AnimatedReorderable], a wrapper for list or grid that
/// animates items when they are inserted, removed or reordered.
///
/// When an item is inserted with [insertItem] an animation begins running. The
/// animation is passed to the [insertItem] `builder` parameter.
///
/// When an item is removed with [removeItem] its animation is reversed.
/// The removed item's animation is passed to the [removeItem] `builder`
/// parameter.
///
/// When an item is reordered with [reorderItem] its motion animation is handled
/// by the underlying controller.
///
/// An app that needs to insert, remove or reorder items in response to an event
/// can refer to the [AnimatedReorderable]'s state with a global key:
///
/// ```dart
/// // (e.g. in a stateful widget)
/// GlobalKey<AnimatedReorderableState> animatedReorderableKey = GlobalKey<AnimatedReorderableState>();
///
/// // ...
///
/// @override
/// Widget build(BuildContext context) {
///   return AnimatedReorderable(
///     key: animatedReorderableKey,
///     keyGetter: (index) => ValueKey(_items[index]),
///     listView: ListView.builder(
///     //  ...
///     ),
///   );
/// }
///
/// // ...
///
/// void _updateList() {
///   _items.insert(123, newItem);
///   animatedReorderableKey.currentState!.insertItem(123, builder:  (context, index, animation) {
///   //  ...
///   });
/// }
/// ```
///
/// [AnimatedReorderable] item input handlers can also refer to their [AnimatedReorderableState]
/// with the static [AnimatedReorderable.of] method.
abstract class AnimatedReorderableState<T extends AnimatedReorderable>
    extends State<T> with TickerProviderStateMixin {
  late final AnimatedReorderableController _controller;

  ScrollController? get _scrollController;

  SliverChildDelegate get _childrenDelegate;

  Clip get _clipBehavior;

  Axis get _scrollDirection;

  @override
  void initState() {
    super.initState();

    _controller = AnimatedReorderableController(
      keyGetter: widget.keyGetter,
      scrollDirection: _scrollDirection,
      itemCount: getChildCount(_childrenDelegate),
      reorderableGetter: widget.reorderableGetter,
      draggableGetter: widget.draggableGetter,
      swipeToRemoveDirectionGetter: widget.swipeToRemoveDirectionGetter,
      onReorder: widget.onReorder,
      onSwipeToRemove: widget.onSwipeToRemove,
      motionAnimationDuration: widget.motionAnimationDuration,
      motionAnimationCurve: widget.motionAnimationCurve,
      draggedItemDecorator: widget.draggedItemDecorator,
      draggedItemDecorationAnimationDuration:
          widget.draggedItemDecorationAnimationDuration,
      swipedItemDecorator: widget.swipedItemDecorator,
      swipedItemDecorationAnimationDuration:
          widget.swipedItemDecorationAnimationDuration,
      autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
      swipeToRemoveExtent: widget.swipeToRemoveExtent,
      swipeToRemoveVelocity: widget.swipeToRemoveVelocity,
      swipeToRemoveSpringDescription: widget.swipeToRemoveSpringDescription,
      onItemDragStart: widget.onItemDragStart,
      onItemDragUpdate: widget.onItemDragUpdate,
      onItemDragEnd: widget.onItemDragEnd,
      onItemSwipeStart: widget.onItemSwipeStart,
      onItemSwipeUpdate: widget.onItemSwipeUpdate,
      onItemSwipeEnd: widget.onItemSwipeEnd,
      vsync: this,
    );

    _controller.scrollController = _scrollController ?? ScrollController();
  }

  /// Insert an item at `index` and start an animation that will be passed
  /// to `builder`.
  ///
  /// This method's semantics are the same as Dart's [List.insert] method: it
  /// increases the length of the list of items by one and shifts
  /// all items at or after `index` towards the end of the list of items.
  void insertItem(
    int index,
    AnimatedItemBuilder builder, {
    Duration duration = defaultInsertItemAnimationDuration,
  }) =>
      _controller.insertItem(index, builder, duration);

  /// Remove the item at `index` and start an animation that will be passed to
  /// `builder` when the item is visible.
  ///
  /// Items are removed immediately. After an item has been removed, its index
  /// will no longer be passed to the `itemBuilder`. However, the
  /// item will still appear for `duration` and during that time
  /// `builder` must construct its widget as needed.
  ///
  /// This method's semantics are the same as Dart's [List.remove] method: it
  /// decreases the length of items by one and shifts all items at or before
  /// `index` towards the beginning of the list of items.
  ///
  /// See also:
  ///
  ///   * [AnimatedRemovedItemBuilder], which describes the arguments to the
  ///     `builder` argument.
  void removeItem(
    int index,
    AnimatedRemovedItemBuilder builder, {
    Duration duration = defaultRemoveItemAnimationDuration,
    int? zIndex,
  }) =>
      _controller.removeItem(index, builder, duration, zIndex: zIndex);

  /// Reorders the item at the specified [index] to a new position in the list or grid.
  ///
  /// This method triggers the reordering animation to smoothly move the item
  /// from its current position to the [destIndex] within the [AnimatedReorderable] widget.
  ///
  /// If `onReorder` callback is not specified, then this function will throw an exception.
  ///
  /// The [index] parameter represents the original position of the item.
  /// The [destIndex] parameter represents the new position to which the item will be moved.
  ///
  /// Note: The reordering animation is handled by the underlying controller.
  ///
  /// Parameters:
  /// - `index`: The original position of the item to be reordered.
  /// - `destIndex`: The new position to which the item will be moved.
  void reorderItem(
    int index, {
    required int destIndex,
  }) =>
      _controller.reorderItem(index, destIndex: destIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _controller.handleConstraintsChange(constraints);
          return Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: ItemsLayer(
                  key: _controller.itemsLayerKey,
                  controller: _controller,
                  collectionViewBuilder: buildCollectionView,
                  didBuild: _controller.handleDidBuildItemsLayer,
                ),
              ),
              OverlayedItemsLayer(
                key: _controller.overlayedItemsLayerKey,
                controller: _controller,
                clipBehavior: _clipBehavior,
              ),
            ],
          );
        },
      );

  Widget buildCollectionView(BuildContext context);
}

class _ListView extends AnimatedReorderable {
  const _ListView({
    super.key,
    required super.keyGetter,
    super.motionAnimationDuration,
    super.motionAnimationCurve,
    super.autoScrollerVelocityScalar,
    super.draggableGetter,
    super.reorderableGetter,
    super.onReorder,
    super.swipeToRemoveDirectionGetter,
    super.swipeToRemoveExtent,
    super.swipeToRemoveVelocity,
    super.swipeToRemoveSpringDescription,
    super.onSwipeToRemove,
    super.draggedItemDecorator,
    super.draggedItemDecorationAnimationDuration,
    super.swipedItemDecorator,
    super.swipedItemDecorationAnimationDuration,
    super.onItemDragStart,
    super.onItemDragUpdate,
    super.onItemDragEnd,
    super.onItemSwipeStart,
    super.onItemSwipeUpdate,
    super.onItemSwipeEnd,
    required this.listView,
  });

  final ListView listView;

  @override
  State<AnimatedReorderable> createState() => _ListViewState();
}

class _ListViewState extends AnimatedReorderableState<_ListView> {
  @override
  ScrollController? get _scrollController => widget.listView.controller;

  @override
  SliverChildDelegate get _childrenDelegate => widget.listView.childrenDelegate;

  @override
  Clip get _clipBehavior => widget.listView.clipBehavior;

  @override
  Axis get _scrollDirection => widget.listView.scrollDirection;

  @override
  Widget buildCollectionView(BuildContext context) => ListView.custom(
        key: widget.listView.key,
        scrollDirection: _scrollDirection,
        reverse: widget.listView.reverse,
        controller: _controller.scrollController,
        primary: widget.listView.primary,
        physics: widget.listView.physics,
        shrinkWrap: widget.listView.shrinkWrap,
        padding: widget.listView.padding,
        itemExtent: widget.listView.itemExtent,
        prototypeItem: widget.listView.prototypeItem,
        childrenDelegate:
            _controller.overrideChildrenDelegate(_childrenDelegate),
        cacheExtent: widget.listView.cacheExtent,
        semanticChildCount: widget.listView.semanticChildCount,
        dragStartBehavior: widget.listView.dragStartBehavior,
        keyboardDismissBehavior: widget.listView.keyboardDismissBehavior,
        restorationId: widget.listView.restorationId,
        clipBehavior: _clipBehavior,
      );
}

class _GridView extends AnimatedReorderable {
  const _GridView({
    super.key,
    required super.keyGetter,
    super.motionAnimationDuration,
    super.motionAnimationCurve,
    super.autoScrollerVelocityScalar,
    super.draggableGetter,
    super.reorderableGetter,
    super.onReorder,
    super.swipeToRemoveDirectionGetter,
    super.swipeToRemoveExtent,
    super.swipeToRemoveVelocity,
    super.swipeToRemoveSpringDescription,
    super.onSwipeToRemove,
    super.draggedItemDecorator,
    super.draggedItemDecorationAnimationDuration,
    super.swipedItemDecorator,
    super.swipedItemDecorationAnimationDuration,
    super.onItemDragStart,
    super.onItemDragUpdate,
    super.onItemDragEnd,
    super.onItemSwipeStart,
    super.onItemSwipeUpdate,
    super.onItemSwipeEnd,
    required this.gridView,
  });

  final GridView gridView;

  @override
  State<AnimatedReorderable> createState() => _GridViewState();
}

class _GridViewState extends AnimatedReorderableState<_GridView> {
  @override
  ScrollController? get _scrollController => widget.gridView.controller;

  @override
  SliverChildDelegate get _childrenDelegate => widget.gridView.childrenDelegate;

  @override
  Clip get _clipBehavior => widget.gridView.clipBehavior;

  @override
  Axis get _scrollDirection => widget.gridView.scrollDirection;

  @override
  Widget buildCollectionView(BuildContext context) => GridView.custom(
        key: widget.gridView.key,
        scrollDirection: _scrollDirection,
        reverse: widget.gridView.reverse,
        controller: _controller.scrollController,
        primary: widget.gridView.primary,
        physics: widget.gridView.physics,
        shrinkWrap: widget.gridView.shrinkWrap,
        padding: widget.gridView.padding,
        gridDelegate: SliverGridLayoutNotifier(
          gridDelegate: widget.gridView.gridDelegate,
          onLayout: _controller.handleSliverGridLayoutChange,
        ),
        childrenDelegate:
            _controller.overrideChildrenDelegate(_childrenDelegate),
        cacheExtent: widget.gridView.cacheExtent,
        semanticChildCount: widget.gridView.semanticChildCount,
        dragStartBehavior: widget.gridView.dragStartBehavior,
        keyboardDismissBehavior: widget.gridView.keyboardDismissBehavior,
        restorationId: widget.gridView.restorationId,
        clipBehavior: _clipBehavior,
      );
}
