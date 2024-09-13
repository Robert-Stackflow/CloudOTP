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

import 'package:flutter/widgets.dart' hide ViewportBuilder;

import 'sliver_waterfall_flow.dart';
import 'typedef.dart';

/// A sliver that places multiple box children in a two dimensional arrangement
/// and masonry layout.
///
/// [SliverWaterfallFlow] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// The main axis direction of a grid is the direction in which it scrolls; the
/// cross axis direction is the orthogonal direction.
///
///
/// This example, which would be inserted into a [CustomScrollView.slivers]
/// list, shows twenty boxes in a pretty teal grid with masonry layout:
///
/// ```dart
/// SliverWaterfallFlow(
///   gridDelegate: SliverWaterfallFlowDelegate(
///     crossAxisCount: 2,
///     mainAxisSpacing: 10.0,
///     crossAxisSpacing: 10.0,
///   ),
///   delegate: SliverChildBuilderDelegate(
///     (BuildContext context, int index) {
///       return Container(
///         alignment: Alignment.center,
///         color: Colors.teal[100 * (index % 9)],
///         child: Text('grid item $index'),
///         height: 50.0 + 100.0 * (index % 9)
///       );
///     },
///     childCount: 20,
///   ),
/// )
/// ```
///
/// {@macro flutter.widgets.sliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverList], which places its children in a linear array.
///  * [SliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverGrid], which places its children in arbitrary positions.
class SliverWaterfallFlow extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement and masonry layout.
  const SliverWaterfallFlow({
    super.key,
    required super.delegate,
    required this.gridDelegate,
  });

  /// Creates a sliver that places multiple box children in a two dimensional
  /// arrangement and masonry layout with a fixed number of tiles in the cross axis.
  ///
  /// Uses a [SliverWaterfallFlowDelegate] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [WaterfallFlow.count], the equivalent constructor for [WaterfallFlow] widgets.
  SliverWaterfallFlow.count({
    super.key,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    List<Widget> children = const <Widget>[],
    LastChildLayoutTypeBuilder? lastChildLayoutTypeBuilder,
    CollectGarbage? collectGarbage,
    ViewportBuilder? viewportBuilder,
    bool closeToTrailing = false,
  })  : gridDelegate = SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          lastChildLayoutTypeBuilder: lastChildLayoutTypeBuilder,
          collectGarbage: collectGarbage,
          viewportBuilder: viewportBuilder,
          closeToTrailing: closeToTrailing,
        ),
        super(delegate: SliverChildListDelegate(children));

  /// Creates a sliver that places multiple box children in masonry layout
  /// with tiles that each have a maximum cross-axis extent.
  ///
  /// Uses a [SliverMasonryGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate],
  /// and a [SliverChildListDelegate] as the [delegate].
  ///
  /// See also:
  ///
  ///  * [MasonryGridView.extent], the equivalent constructor for [MasonryGridView] widgets.
  SliverWaterfallFlow.extent({
    super.key,
    required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    List<Widget> children = const <Widget>[],
    LastChildLayoutTypeBuilder? lastChildLayoutTypeBuilder,
    CollectGarbage? collectGarbage,
    ViewportBuilder? viewportBuilder,
    bool closeToTrailing = false,
  })  : gridDelegate = SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          lastChildLayoutTypeBuilder: lastChildLayoutTypeBuilder,
          collectGarbage: collectGarbage,
          viewportBuilder: viewportBuilder,
          closeToTrailing: closeToTrailing,
        ),
        super(delegate: SliverChildListDelegate(children));

  /// The delegate that controls the size and position of the children.
  final SliverWaterfallFlowDelegate gridDelegate;

  @override
  RenderSliverWaterfallFlow createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return RenderSliverWaterfallFlow(
        childManager: element, gridDelegate: gridDelegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverWaterfallFlow renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }
}
