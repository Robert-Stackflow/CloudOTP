import 'package:flutter/widgets.dart';

import '../../animated_reorderable.dart';
import '../util/misc.dart';

typedef RenderedItem = _ItemWidgetState;
typedef RenderedItemLifecycleCallback = void Function(RenderedItem item);
typedef ItemGestureRecognizer = void Function(
    RenderedItem item, PointerDownEvent event);

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    required super.key,
    required this.index,
    required this.reorderableGetter,
    required this.draggableGetter,
    required this.overlayedGetter,
    required this.swipeToRemoveDirectionGetter,
    required this.builder,
    this.onInit,
    this.didUpdate,
    this.onDispose,
    this.onDeactivate,
    this.didBuild,
    required this.recognizeDrag,
    required this.recognizeSwipe,
  });

  final int index;
  final NullableIndexedWidgetBuilder builder;
  final BoolGetter reorderableGetter;
  final BoolGetter draggableGetter;
  final bool Function(Key key) overlayedGetter;
  final AxisDirectionGetter? swipeToRemoveDirectionGetter;
  final RenderedItemLifecycleCallback? onInit;
  final RenderedItemLifecycleCallback? didUpdate;
  final RenderedItemLifecycleCallback? onDispose;
  final RenderedItemLifecycleCallback? onDeactivate;
  final RenderedItemLifecycleCallback? didBuild;
  final ItemGestureRecognizer recognizeDrag;
  final ItemGestureRecognizer recognizeSwipe;

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  int get index => widget.index;
  Key get key => widget.key!;
  NullableIndexedWidgetBuilder get builder => widget.builder;
  bool get reorderable => widget.reorderableGetter(index);
  bool get draggable => widget.draggableGetter(index);
  bool get isOverlayed => widget.overlayedGetter(key);
  AxisDirection? get swipeToRemoveDirection =>
      widget.swipeToRemoveDirectionGetter?.call(index);
  bool get swipeable => swipeToRemoveDirection != null;
  Offset? get globalPosition => findRenderBox()?.localToGlobal(Offset.zero);
  Size? get size => findRenderBox()?.size;

  @override
  void initState() {
    super.initState();
    widget.onInit?.call(this);
  }

  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      widget.didUpdate?.call(this);
    }
  }

  @override
  void dispose() {
    widget.onDispose?.call(this);
    super.dispose();
  }

  @override
  void deactivate() {
    widget.onDeactivate?.call(this);
    super.deactivate();
  }

  void rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    addPostFrame(() => widget.didBuild?.call(this));

    return Opacity(
      opacity: isOverlayed ? 0 : 1,
      child: Listener(
        onPointerDown: swipeable && !isOverlayed ? _recognizeSwipe : null,
        child: Listener(
          onPointerDown: draggable && !isOverlayed ? _recognizeDrag : null,
          child: widget.builder(context, index),
        ),
      ),
    );
  }

  void _recognizeSwipe(PointerDownEvent event) =>
      widget.recognizeSwipe(this, event);

  void _recognizeDrag(PointerDownEvent event) =>
      widget.recognizeDrag(this, event);
}
