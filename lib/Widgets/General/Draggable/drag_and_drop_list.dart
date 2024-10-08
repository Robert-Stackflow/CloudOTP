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

import 'drag_and_drop_builder_parameters.dart';
import 'drag_and_drop_item.dart';
import 'drag_and_drop_item_target.dart';
import 'drag_and_drop_item_wrapper.dart';
import 'drag_and_drop_list_interface.dart';

class DragAndDropList implements DragAndDropListInterface {
  /// The widget that is displayed at the top of the list.
  Widget? header;

  /// The widget that is displayed at the bottom of the list.
  Widget? footer;

  /// The widget that is displayed to the left of the list.
  final Widget? leftSide;

  /// The widget that is displayed to the right of the list.
  final Widget? rightSide;

  /// The widget to be displayed when a list is empty.
  /// If this is not null, it will override that set in [DragAndDropLists.contentsWhenEmpty].
  final Widget? contentsWhenEmpty;

  /// The widget to be displayed as the last element in the list that will accept
  /// a dragged item.
  Widget? lastTarget;

  /// The decoration displayed around a list.
  /// If this is not null, it will override that set in [DragAndDropLists.listDecoration].
  final Decoration? decoration;

  /// The vertical alignment of the contents in this list.
  /// If this is not null, it will override that set in [DragAndDropLists.verticalAlignment].
  final CrossAxisAlignment verticalAlignment;

  /// The horizontal alignment of the contents in this list.
  /// If this is not null, it will override that set in [DragAndDropLists.horizontalAlignment].
  final MainAxisAlignment horizontalAlignment;

  /// The child elements that will be contained in this list.
  /// It is possible to not provide any children when an empty list is desired.
  @override
  final List<DragAndDropItem> children;

  /// Whether or not this item can be dragged.
  /// Set to true if it can be reordered.
  /// Set to false if it must remain fixed.
  @override
  final bool canDrag;

  DragAndDropList({
    required this.children,
    this.header,
    this.footer,
    this.leftSide,
    this.rightSide,
    this.contentsWhenEmpty,
    this.lastTarget,
    this.decoration,
    this.horizontalAlignment = MainAxisAlignment.start,
    this.verticalAlignment = CrossAxisAlignment.start,
    this.canDrag = true,
  });

  @override
  Widget generateWidget(DragAndDropBuilderParameters params) {
    var contents = <Widget>[];
    if (header != null) {
      contents.add(Flexible(child: header!));
    }
    Widget intrinsicHeight = IntrinsicHeight(
      child: Row(
        mainAxisAlignment: horizontalAlignment,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _generateDragAndDropListInnerContents(params),
      ),
    );
    if (params.axis == Axis.horizontal) {
      intrinsicHeight = SizedBox(
        width: params.listWidth,
        child: intrinsicHeight,
      );
    }
    if (params.listInnerDecoration != null) {
      intrinsicHeight = Container(
        decoration: params.listInnerDecoration,
        child: intrinsicHeight,
      );
    }
    contents.add(intrinsicHeight);

    if (footer != null) {
      contents.add(Flexible(child: footer!));
    }

    return Container(
      width: params.axis == Axis.vertical
          ? double.infinity
          : params.listWidth - params.listPadding!.horizontal,
      decoration: decoration ?? params.listDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: verticalAlignment,
        children: contents,
      ),
    );
  }

  List<Widget> _generateDragAndDropListInnerContents(
      DragAndDropBuilderParameters parameters) {
    var contents = <Widget>[];
    if (leftSide != null) {
      contents.add(leftSide!);
    }
    if (children.isNotEmpty) {
      List<Widget> allChildren = <Widget>[];
      if (parameters.addLastItemTargetHeightToTop) {
        allChildren.add(Padding(
          padding: EdgeInsets.only(top: parameters.lastItemTargetHeight),
        ));
      }
      for (int i = 0; i < children.length; i++) {
        allChildren.add(DragAndDropItemWrapper(
          child: children[i],
          parameters: parameters,
        ));
        if (parameters.itemDivider != null && i < children.length - 1) {
          allChildren.add(parameters.itemDivider!);
        }
      }
      allChildren.add(
        DragAndDropItemTarget(
          parent: this,
          parameters: parameters,
          onReorderOrAdd: parameters.onItemDropOnLastTarget!,
          child: lastTarget ??
              Container(
                height: parameters.lastItemTargetHeight,
              ),
        ),
      );
      contents.add(
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: verticalAlignment,
              mainAxisSize: MainAxisSize.max,
              children: allChildren,
            ),
          ),
        ),
      );
    } else {
      contents.add(
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                contentsWhenEmpty ??
                    const Text(
                      'Empty list',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                DragAndDropItemTarget(
                  parent: this,
                  parameters: parameters,
                  onReorderOrAdd: parameters.onItemDropOnLastTarget!,
                  child: lastTarget ??
                      Container(
                        height: parameters.lastItemTargetHeight,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (rightSide != null) {
      contents.add(rightSide!);
    }
    return contents;
  }
}
