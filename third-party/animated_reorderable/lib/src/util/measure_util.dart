import 'misc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// TODO: find a more optimized way to measure widgets

// The code is copied from
// https://api.flutter.dev/flutter/widgets/BuildOwner-class.html
class MeasureUtil {
  static Size measureWidget({
    required BuildContext context,
    required WidgetBuilder builder,
    BoxConstraints? constraints,
  }) {
    final renderBox = context.findRenderBox();
    if (renderBox == null) return Size.zero;

    final PipelineOwner pipelineOwner = PipelineOwner();
    final _MeasurementView rootView = pipelineOwner.rootNode =
        _MeasurementView(constraints ?? renderBox.constraints);
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    final RenderObjectToWidgetElement<RenderBox> element =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: rootView,
      child: Directionality(
        textDirection: Directionality.of(context),
        child: builder(context),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      rootView.scheduleInitialLayout();
      pipelineOwner.flushLayout();
      return rootView.size;
    } finally {
      element.update(
        RenderObjectToWidgetAdapter<RenderBox>(
          container: rootView,
        ),
      );
      buildOwner.finalizeTree();
    }
  }
}

class _MeasurementView extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  final BoxConstraints boxConstraints;
  _MeasurementView(this.boxConstraints);

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(boxConstraints, parentUsesSize: true);
    size = child!.size;
  }

  @override
  void debugAssertDoesMeetConstraints() => true;
}
