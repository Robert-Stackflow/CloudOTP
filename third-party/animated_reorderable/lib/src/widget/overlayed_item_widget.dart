import 'package:flutter/widgets.dart';

import '../model/model.dart';

class OverlayedItemWidget extends StatelessWidget {
  const OverlayedItemWidget({
    super.key,
    required this.item,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onSwipeStart,
    this.onSwipeUpdate,
    this.onSwipeEnd,
  });

  final OverlayedItem item;
  final OverlayedItemDragStartCallback? onDragStart;
  final OverlayedItemDragUpdateCallback? onDragUpdate;
  final OverlayedItemDragEndCallback? onDragEnd;
  final OverlayedItemDragStartCallback? onSwipeStart;
  final OverlayedItemDragUpdateCallback? onSwipeUpdate;
  final OverlayedItemDragEndCallback? onSwipeEnd;

  @override
  Widget build(BuildContext context) => Positioned(
        left: item.position.dx,
        top: item.position.dy,
        child: IgnorePointer(
          ignoring: !item.interactive,
          child: Listener(
            onPointerDown: (event) => item.swiped
                ? item.recognizeSwipe(
                    event,
                    context: context,
                    swipeDirection: item.swipeToRemoveDirection!,
                    onSwipeStart: onSwipeStart,
                    onSwipeUpdate: onSwipeUpdate,
                    onSwipeEnd: onSwipeEnd,
                  )
                : item.recognizeDrag(
                    event,
                    context: context,
                    onDragStart: onDragStart,
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                  ),
            child: ConstrainedBox(
              constraints: item.constraints,
              child: item.build(context),
            ),
          ),
        ),
      );
}
