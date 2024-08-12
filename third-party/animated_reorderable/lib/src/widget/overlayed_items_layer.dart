import 'package:flutter/widgets.dart';

import '../animated_reorderable_controller.dart';
import '../util/misc.dart';
import 'overlayed_item_widget.dart';

class OverlayedItemsLayer extends StatefulWidget {
  const OverlayedItemsLayer({
    super.key,
    required this.controller,
    required this.clipBehavior,
  });

  final AnimatedReorderableController controller;
  final Clip clipBehavior;

  @override
  State<OverlayedItemsLayer> createState() => OverlayedItemsLayerState();
}

class OverlayedItemsLayerState extends State<OverlayedItemsLayer> {
  final canvasKey = GlobalKey();

  AnimatedReorderableController get controller => widget.controller;

  Offset? globalToLocal(Offset point) =>
      canvasKey.currentContext?.findRenderBox()?.globalToLocal(point);

  Offset? localToGlobal(Offset point) =>
      canvasKey.currentContext?.findRenderBox()?.localToGlobal(point);

  Rect? computeCanvasGeometry([Offset offset = Offset.zero]) =>
      canvasKey.currentContext?.computeGeometry(offset);

  @override
  Widget build(BuildContext context) => Stack(
        key: canvasKey,
        clipBehavior: widget.clipBehavior,
        children: [
          for (var item in controller.overlayedItemsOrderedByZIndex)
            OverlayedItemWidget(
              key: ValueKey(item.key),
              item: item,
              onDragStart: controller.handleItemDragStart,
              onDragUpdate: controller.handleItemDragUpdate,
              onDragEnd: controller.handleItemDragEnd,
              onSwipeStart: controller.handleItemSwipeStart,
              onSwipeUpdate: controller.handleItemSwipeUpdate,
              onSwipeEnd: controller.handleItemSwipeEnd,
            ),
        ],
      );
}
