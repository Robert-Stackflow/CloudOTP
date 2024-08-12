import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void addPostFrame(VoidCallback cb) =>
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => cb());

extension AnimationStatusExtension on AnimationStatus {
  bool get idle => !animating;
  bool get animating =>
      this == AnimationStatus.forward || this == AnimationStatus.reverse;
}

extension StateExtension on State {
  bool contains(Offset point) =>
      findRenderBox()?.getGeometry().contains(point) ?? false;
  RenderBox? findRenderBox() => mounted ? context.findRenderBox() : null;
  Rect? computeGeometry([Offset offset = Offset.zero]) =>
      findRenderBox()?.getGeometry(offset);
  EdgeInsets mediaQueryScrollablePaddingOf(Axis scrollDirection) =>
      scrollDirection == Axis.vertical
          ? MediaQuery.paddingOf(context).copyWith(left: 0.0, right: 0.0)
          : MediaQuery.paddingOf(context).copyWith(top: 0.0, bottom: 0.0);
  void rebuild([VoidCallback? cb]) {
    if (!mounted) return;
    // ignore: invalid_use_of_protected_member
    setState(() => cb?.call());
  }
}

extension BuildContextExtension on BuildContext {
  RenderBox? findRenderBox() => findRenderObject() as RenderBox?;
  Rect? computeGeometry([Offset offset = Offset.zero]) =>
      findRenderBox()?.getGeometry(offset);
}

extension RenderBoxExtension on RenderBox {
  Rect getGeometry([Offset offset = Offset.zero]) =>
      localToGlobal(offset) & size;
}

extension ScrollPositionExtension on ScrollPosition {
  bool get reverse => axisDirection.reverse;
  bool get vertical => axisDirection.vertical;
  Axis get axis => axisDirection.axis;
  double get relativePixels => reverse ? -pixels : pixels;
  Offset toRelativeOffset() =>
      vertical ? Offset(0, relativePixels) : Offset(relativePixels, 0);
}

extension AxisDirectionExtension on AxisDirection {
  Axis get axis => axisDirectionToAxis(this);
  bool get vertical => axis == Axis.vertical;
  bool get reverse => this == AxisDirection.up || this == AxisDirection.left;
}

extension ScrollControllerExtension on ScrollController {
  ScrollableState? get scrollableState =>
      hasClients ? position.context as ScrollableState : null;
  RenderBox? findScrollableRenderBox() => scrollableState?.findRenderBox();
  Offset? get scrollablePosition =>
      findScrollableRenderBox()?.localToGlobal(Offset.zero);
  Offset? get scrollOffset => position.toRelativeOffset();
  bool get reverse => position.reverse;
  bool get vertical => position.vertical;
  AxisDirection get axisDirection => position.axisDirection;
  Axis get axis => position.axis;
  void scaleScrollPosition(double scaleFactor) =>
      jumpTo(position.pixels * scaleFactor);
}

extension RectExtension on Rect {
  Offset get position => topLeft;
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension SliverGridGeometryExtension on SliverGridGeometry {
  Size toSize(Axis axis) => axis == Axis.vertical
      ? Size(crossAxisExtent, mainAxisExtent)
      : Size(mainAxisExtent, crossAxisExtent);
}

extension SliverGridLayoutExtension on SliverGridLayout {
  Size getChildSize(int index, Axis axis) =>
      getGeometryForChildIndex(index).toSize(axis);
}

Widget defaultDraggedItemDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) =>
    ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ).drive(Tween(begin: 1, end: 1.05)),
      child: FadeTransition(
        opacity: animation.drive(Tween(begin: 1, end: 0.7)),
        child: child,
      ),
    );

MultiDragGestureRecognizer createReoderGestureRecognizer(
        BuildContext context) =>
    DelayedMultiDragGestureRecognizer()
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);

MultiDragGestureRecognizer createHorizontalSwipeToRemoveGestureRecognizer(
        BuildContext context) =>
    HorizontalMultiDragGestureRecognizer()
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);

MultiDragGestureRecognizer createVerticalSwipeToRemoveGestureRecognizer(
        BuildContext context) =>
    VerticalMultiDragGestureRecognizer()
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);

MultiDragGestureRecognizer createImmediateGestureRecognizer(
        BuildContext context) =>
    ImmediateMultiDragGestureRecognizer()
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
