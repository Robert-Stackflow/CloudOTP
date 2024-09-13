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

import 'package:flutter/rendering.dart';

import 'typedef.dart';

enum LastChildLayoutType {
  /// as default child
  none,

  /// follow max child trailing layout offset and layout with full cross-axis extent
  /// last child as load more item/no more item in [ExtendedGridView] and [WaterfallFlow]
  /// with full cross axis extend
  fullCrossAxisExtent,

  /// as foot at trailing and layout with full cross axis extend
  /// show no more item at trailing when children are not full of viewport
  /// if children is full of viewport, it's the same as fullCrossAxisExtent
  foot,
}

/// A delegate that provides extensions within the [ExtendedGridView],[ExtendedList],[WaterfallFlow].
class ExtendedListDelegate {
  const ExtendedListDelegate({
    this.lastChildLayoutTypeBuilder,
    this.collectGarbage,
    this.viewportBuilder,
    this.closeToTrailing = false,
  });

  /// The builder to get layout type of last child
  /// Notice: it should only for last child
  final LastChildLayoutTypeBuilder? lastChildLayoutTypeBuilder;

  /// Call when collect garbage, return indexes of children which are disposed to collect
  final CollectGarbage? collectGarbage;

  /// The builder to get indexes in viewport
  final ViewportBuilder? viewportBuilder;

  /// when reverse property of List is true, layout is as following.
  /// it likes chat list, and new session will insert to zero index
  /// but it's not right when items are not full of viewport.
  ///
  ///      trailing
  /// -----------------
  /// |               |
  /// |               |
  /// |     item2     |
  /// |     item1     |
  /// |     item0     |
  /// -----------------
  ///      leading
  ///
  /// to solve it, you could set closeToTrailing to true, layout is as following.
  /// support [ExtendedGridView],[ExtendedList],[WaterfallFlow]
  /// it works not only reverse is true.
  ///
  ///      trailing
  /// -----------------
  /// |     item2     |
  /// |     item1     |
  /// |     item0     |
  /// |               |
  /// |               |
  /// -----------------
  ///      leading
  ///
  final bool closeToTrailing;
}

/// mixin of extended list render
/// if sliver is all out of viewport then return [-1,-1] or nothing
mixin ExtendedRenderObjectMixin on RenderSliverMultiBoxAdaptor {
  /// call ViewportBuilder if it's not null
  void callViewportBuilder({
    ViewportBuilder? viewportBuilder,
    //ExtentList and GridView can't use paintExtentOf
    PaintExtentOf? getPaintExtend,
    double mainAxisSpacing = 0,
  }) {
    if (viewportBuilder == null) {
      return;
    }

    /// it's not go into viewport
    if (firstChild == null ||
        //sometime, remainingPaintExtent is not zero though sliver is not go into viewport
        //maybe this is issue for viewport
        (constraints.precedingScrollExtent != 0.0 &&
            constraints.remainingPaintExtent == 0)) {
      return;
    }

    int viewportFirstIndex = -1;
    int viewportLastIndex = -1;
    RenderBox? viewportFirstChild = firstChild;
    while (true) {
      final double layoutOffset = childScrollOffset(viewportFirstChild!)!;
      final double trailingOffset = layoutOffset +
          (getPaintExtend != null
              ? getPaintExtend(viewportFirstChild)
              : paintExtentOf(viewportFirstChild));
      if (layoutOffset - (layoutOffset == 0 ? 0 : mainAxisSpacing) <=
              constraints.scrollOffset &&
          constraints.scrollOffset < trailingOffset) {
        viewportFirstIndex = indexOf(viewportFirstChild);
        break;
      }
      viewportFirstChild = childAfter(viewportFirstChild);
      if (viewportFirstChild == null) {
        break;
      }
    }

    RenderBox? viewportLastChild = lastChild;

    while (true) {
      final double layoutOffset = childScrollOffset(viewportLastChild!)!;
      final double trailingOffset = layoutOffset +
          (getPaintExtend != null
              ? getPaintExtend(viewportLastChild)
              : paintExtentOf(viewportLastChild));
      if (layoutOffset <
              constraints.scrollOffset + constraints.remainingPaintExtent &&
          trailingOffset >= constraints.scrollOffset) {
        viewportLastIndex = indexOf(viewportLastChild);
        break;
      }
      viewportLastChild = childBefore(viewportLastChild);
      if (viewportLastChild == null) {
        break;
      }
    }

    viewportBuilder(viewportFirstIndex, viewportLastIndex);
  }

  /// call CollectGarbage if it's not null
  void callCollectGarbage({
    CollectGarbage? collectGarbage,
    int? leadingGarbage,
    int? trailingGarbage,
    int? firstIndex,
    int? targetLastIndex,
  }) {
    if (collectGarbage == null) {
      return;
    }

    final List<int> garbages = <int>[];
    firstIndex ??= indexOf(firstChild!);
    targetLastIndex ??= indexOf(lastChild!);
    for (int i = leadingGarbage!; i > 0; i--) {
      garbages.add(firstIndex - i);
    }
    for (int i = 0; i < trailingGarbage!; i++) {
      garbages.add(targetLastIndex + i);
    }
    if (garbages.isNotEmpty) {
      //call collectGarbage
      collectGarbage.call(garbages);
    }
  }

  /// handle closeToTrailing at begin
  void handleCloseToTrailingBegin(bool closeToTrailing) {
    _closeToTrailingDistance = null;
    // if (closeToTrailing) {
    //   RenderBox child = firstChild;
    //   SliverMultiBoxAdaptorParentData childParentData =
    //       child.parentData as SliverMultiBoxAdaptorParentData;
    //   if (childParentData.index == 0 && childParentData.layoutOffset != 0) {
    //     final double distance = childParentData.layoutOffset;
    //     while (child != null) {
    //       childParentData = child.parentData as SliverMultiBoxAdaptorParentData;
    //       childParentData.layoutOffset -= distance;
    //       child = childAfter(child);
    //     }
    //   }
    // }
  }

  /// handle closeToTrailing at end
  double handleCloseToTrailingEnd(
      bool closeToTrailing, double endScrollOffset) {
    if (closeToTrailing && endScrollOffset < constraints.remainingPaintExtent) {
      //RenderBox child = firstChild;
      final double distance =
          constraints.remainingPaintExtent - endScrollOffset;
      _closeToTrailingDistance = distance;
      // while (child != null) {
      //   final SliverMultiBoxAdaptorParentData childParentData =
      //       child.parentData as SliverMultiBoxAdaptorParentData;
      //   childParentData.layoutOffset += distance;
      //   child = childAfter(child);
      // }
      return constraints.remainingPaintExtent;
    }
    return endScrollOffset;
  }

  double? _closeToTrailingDistance;

  double get closeToTrailingDistance => _closeToTrailingDistance ?? 0.0;

  bool get closeToTrailing => extendedListDelegate.closeToTrailing;

  ExtendedListDelegate get extendedListDelegate;

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData as SliverMultiBoxAdaptorParentData;
    return childParentData.layoutOffset! + closeToTrailingDistance;
  }
}
