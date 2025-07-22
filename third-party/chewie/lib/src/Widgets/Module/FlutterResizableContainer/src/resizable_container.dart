import 'package:flutter/material.dart';
import '../flutter_resizable_container.dart';
import 'extensions/box_constraints_ext.dart';
import 'extensions/iterable_ext.dart';
import 'extensions/num_ext.dart';
import 'layout/resizable_layout.dart';
import 'resizable_container_divider.dart';
import 'resizable_controller.dart';

class ResizableContainer extends StatefulWidget {
  const ResizableContainer({
    super.key,
    required this.children,
    required this.direction,
    this.controller,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
  });

  final List<ResizableChild> children;
  final ResizableController? controller;
  final Axis direction;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer>
    with SingleTickerProviderStateMixin {
  late final controller = widget.controller ?? ResizableController();
  late final isDefaultController = widget.controller == null;
  late final manager = ResizableControllerManager(controller);

  @override
  void initState() {
    super.initState();
    manager.initChildren(widget.children);
  }

  @override
  void didUpdateWidget(covariant ResizableContainer oldWidget) {
    final didChildrenChange =
        oldWidget.children.length != widget.children.length;
    final didDirectionChange = oldWidget.direction != widget.direction;

    if (didChildrenChange) {
      controller.setChildren(widget.children);
    }

    if (didChildrenChange || didDirectionChange) {
      manager.setNeedsLayout();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (isDefaultController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSpace = _getAvailableSpace(constraints);
        manager.setAvailableSpace(availableSpace);

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.needsLayout) {
              return ResizableLayout(
                direction: widget.direction,
                onComplete: (sizes) {
                  final childSizes = sizes.evenIndices().toList();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    manager.setRenderedSizes(childSizes);
                  });
                },
                sizes: controller.sizes,
                resizableChildren: widget.children,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    widget.children[i].child,
                    if (i < widget.children.length - 1) ...[
                      ResizableContainerDivider.placeholder(
                        config: widget.children[i].divider,
                        direction: widget.direction,
                      ),
                    ],
                  ],
                ],
              );
            } else {
              return Flex(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                direction: widget.direction,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final child = widget.children[i].child;

                        final height = _getChildSize(
                          index: i,
                          direction: Axis.vertical,
                          constraints: constraints,
                        );

                        final width = _getChildSize(
                          index: i,
                          direction: Axis.horizontal,
                          constraints: constraints,
                        );

                        return AnimatedContainer(
                          duration: widget.animationDuration,
                          curve: widget.animationCurve,
                          height: height,
                          width: width,
                          child: child,
                        );
                      },
                    ),
                    if (i < widget.children.length - 1) ...[
                      ResizableContainerDivider(
                        config: widget.children[i].divider,
                        direction: widget.direction,
                        onResizeUpdate: (delta) => manager.adjustChildSize(
                          index: i,
                          delta: delta,
                        ),
                      ),
                    ],
                  ],
                ],
              );
            }
          },
        );
      },
    );
  }

  double _getAvailableSpace(BoxConstraints constraints) {
    final totalSpace = constraints.maxForDirection(widget.direction);
    final dividerSpace = widget.children
        .take(widget.children.length - 1)
        .map((child) => child.divider)
        .map((divider) => divider.thickness + divider.padding)
        .sum();

    return totalSpace - dividerSpace;
  }

  double _getChildSize({
    required int index,
    required Axis direction,
    required BoxConstraints constraints,
  }) {
    if (direction != widget.direction) {
      return constraints.maxForDirection(direction);
    } else {
      return controller.pixels[index];
    }
  }
}
