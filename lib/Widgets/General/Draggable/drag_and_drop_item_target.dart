/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../Utils/constant.dart';
import 'drag_and_drop_list_interface.dart';
import 'drag_and_drop_lists.dart';

class DragAndDropItemTarget extends StatefulWidget {
  final Widget child;
  final DragAndDropListInterface? parent;
  final DragAndDropBuilderParameters parameters;
  final OnItemDropOnLastTarget onReorderOrAdd;

  const DragAndDropItemTarget(
      {required this.child,
      required this.onReorderOrAdd,
      required this.parameters,
      this.parent,
      super.key});

  @override
  State<StatefulWidget> createState() => _DragAndDropItemTarget();
}

class _DragAndDropItemTarget extends State<DragAndDropItemTarget>
    with TickerProviderStateMixin {
  DragAndDropItem? _hoveredDraggable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: widget.parameters.verticalAlignment,
          children: <Widget>[
            AnimatedSize(
              duration: Duration(
                  milliseconds: widget.parameters.itemSizeAnimationDuration),
              alignment: Alignment.bottomCenter,
              child: _hoveredDraggable != null
                  ? Opacity(
                      opacity: widget.parameters.itemGhostOpacity,
                      child: widget.parameters.itemGhost ??
                          _hoveredDraggable!.child,
                    )
                  : emptyWidget,
            ),
            widget.child,
          ],
        ),
        Positioned.fill(
          child: DragTarget<DragAndDropItem>(
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {}
              return emptyWidget;
            },
            onWillAccept: (incoming) {
              bool accept = true;
              if (widget.parameters.itemTargetOnWillAccept != null) {
                accept =
                    widget.parameters.itemTargetOnWillAccept!(incoming, widget);
              }
              if (accept && mounted) {
                setState(() {
                  _hoveredDraggable = incoming;
                });
              }
              return accept;
            },
            onLeave: (incoming) {
              if (mounted) {
                setState(() {
                  _hoveredDraggable = null;
                });
              }
            },
            onAccept: (incoming) {
              if (mounted) {
                setState(() {
                  widget.onReorderOrAdd(incoming, widget.parent!, widget);
                  _hoveredDraggable = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
