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

import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'reorderable_grid.dart';
import 'sliver_waterfall_flow.dart';

typedef IndexedValueGetter<T> = T Function(int index);

/// A scrollable, reorderable, 2D array of widgets.
///
/// The main axis direction of a grid is the direction in which it scrolls (the
/// [scrollDirection]).
///
/// The most commonly used grid layouts are [ReorderableGridView.count], which creates a
/// layout with a fixed number of tiles in the cross axis, and
/// [ReorderableGridView.extent], which creates a layout with tiles that have a maximum
/// cross-axis extent. A custom [SliverWaterfallFlowDelegate] can produce an arbitrary 2D
/// arrangement of children, including arrangements that are unaligned or
/// overlapping.
///
/// To create a grid with a large (or infinite) number of children, use the
/// [ReorderableGridView.builder] constructor with either a
/// [SliverWaterfallFlowDelegateWithFixedCrossAxisCount] or a
/// [SliverWaterfallFlowDelegateWithMaxCrossAxisExtent] for the [gridDelegate].
///
/// To create a linear array of reorderable children, use a [ReorderableList].
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// ## Transitioning to [CustomScrollView]
///
/// A [ReorderableGridView] is basically a [CustomScrollView] with a single [SliverReorderableGrid] in
/// its [CustomScrollView.slivers] property.
///
/// If [ReorderableGridView] is no longer sufficient, for example because the scroll view
/// is to have both a grid and a list, or because the grid is to be combined
/// with a [SliverAppBar], etc, it is straight-forward to port code from using
/// [ReorderableGridView] to using [CustomScrollView] directly.
///
/// The [key], [scrollDirection], [reverse], [controller], [primary], [physics],
/// and [shrinkWrap] properties on [ReorderableGridView] map directly to the identically
/// named properties on [CustomScrollView].
///
/// The [CustomScrollView.slivers] property should be a list containing just a
/// [SliverGrid].
///
/// the [gridDelegate] property on the
/// [ReorderableGridView] corresponds to the [SliverGrid.gridDelegate] property.
///
/// The [ReorderableGridView], [ReorderableGridView.count], and [ReorderableGridView.extent]
/// constructors' `children` arguments correspond to the [childrenDelegate]
/// being a [SliverChildListDelegate] with that same argument. The
/// [ReorderableGridView.builder] constructor's `itemBuilder` and `childCount` arguments
/// correspond to the [childrenDelegate] being a [SliverChildBuilderDelegate]
/// with the matching arguments.
///
/// The [ReorderableGridView.count] and [ReorderableGridView.extent] constructors create
/// custom grid delegates, and have equivalently named constructors on
/// [SliverGrid] to ease the transition: [SliverGrid.count] and
/// [SliverGrid.extent] respectively.
///
/// The [padding] property corresponds to having a [SliverPadding] in the
/// [CustomScrollView.slivers] property instead of the grid itself, and having
/// the [SliverGrid] instead be a child of the [SliverPadding].
///
/// Once code has been ported to use [CustomScrollView], other slivers, such as
/// [SliverList] or [SliverAppBar], can be put in the [CustomScrollView.slivers]
/// list.
///
/// {@tool snippet}
/// This example demonstrates how to create a [ReorderableGridView] with two columns. The
/// children are spaced apart using the `crossAxisSpacing` and `mainAxisSpacing`
/// properties.
///
/// ```dart
/// ReorderableGridView.count(
///   primary: false,
///   padding: const EdgeInsets.all(20),
///   crossAxisSpacing: 10,
///   mainAxisSpacing: 10,
///   crossAxisCount: 2,
///   onReorder: (int oldIndex, int newIndex) {
///   },
///   children: <Widget>[
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text("He'd have you all unravel at the"),
///       color: Colors.teal[100],
///     ),
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text('Heed not the rabble'),
///       color: Colors.teal[200],
///     ),
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text('Sound of screams but the'),
///       color: Colors.teal[300],
///     ),
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text('Who scream'),
///       color: Colors.teal[400],
///     ),
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text('Revolution is coming...'),
///       color: Colors.teal[500],
///     ),
///     Container(
///       padding: const EdgeInsets.all(8),
///       child: const Text('Revolution, they...'),
///       color: Colors.teal[600],
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to create the same grid as the previous example
/// using a [CustomScrollView] and a [SliverGrid].
///
/// ![The CustomScrollView contains a SliverGrid that displays six children with different background colors arranged in two columns](https://flutter.github.io/assets-for-api-docs/assets/widgets/grid_view_custom_scroll.png)
///
/// ```dart
/// CustomScrollView(
///   primary: false,
///   slivers: <Widget>[
///     SliverPadding(
///       padding: const EdgeInsets.all(20),
///       sliver: SliverReorderableGrid.count(
///         crossAxisSpacing: 10,
///         mainAxisSpacing: 10,
///         crossAxisCount: 2,
///         onReorder: (int oldIndex, int newIndex) {
///         },
///         children: <Widget>[
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text("He'd have you all unravel at the"),
///             color: Colors.green[100],
///           ),
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text('Heed not the rabble'),
///             color: Colors.green[200],
///           ),
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text('Sound of screams but the'),
///             color: Colors.green[300],
///           ),
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text('Who scream'),
///             color: Colors.green[400],
///           ),
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text('Revolution is coming...'),
///             color: Colors.green[500],
///           ),
///           Container(
///             padding: const EdgeInsets.all(8),
///             child: const Text('Revolution, they...'),
///             color: Colors.green[600],
///           ),
///         ],
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// By default, [ReorderableGridView] will automatically pad the limits of the
/// grids's scrollable to avoid partial obstructions indicated by
/// [MediaQuery]'s padding. To avoid this behavior, override with a
/// zero [padding] property.
///
/// {@tool snippet}
/// The following example demonstrates how to override the default top padding
/// using [MediaQuery.removePadding].
///
/// ```dart
/// Widget myWidget(BuildContext context) {
///   return MediaQuery.removePadding(
///     context: context,
///     removeTop: true,
///     child: ReorderableGridView.builder(
///       gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
///         crossAxisCount: 3,
///       ),
///       itemCount: 300,
///       itemBuilder: (BuildContext context, int index) {
///         return Card(
///           color: Colors.amber,
///           child: Center(child: Text('$index')),
///         );
///       }
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [ReorderableList], which is scrollable, reorderable, linear list of widgets.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [SliverWaterfallFlowDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverWaterfallFlowDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class ReorderableGridView extends StatefulWidget {
  /// Creates a scrollable, 2D array of widgets with a custom
  /// [SliverWaterfallFlowDelegate].
  ///
  /// The [gridDelegate] argument must not be null.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ReorderableGridView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.gridItemsNotifier,
    this.reverse = false,
    this.controller,
    this.primary,
    this.dragToReorder = false,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required this.gridDelegate,
    required this.onReorder,
    this.onReorderEnd,
    this.itemDragEnable = _defaultItemDragEnable,
    this.cacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.anchor = 0.0,
    this.proxyDecorator,
    this.autoScroll,
    this.onReorderStart,
  })  : assert(
          children.every((Widget w) => w.key != null),
          'All children of this widget must have a key.',
        ),
        itemBuilder = ((BuildContext context, int index) => children[index]),
        itemCount = children.length,
        childrenDelegate = SliverChildListDelegate(children);

  /// Creates a scrollable, 2D array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for grid views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [ReorderableGridView] to
  /// estimate the maximum scroll extent.
  ///
  /// `itemBuilder` will be called only with indices greater than or equal to
  /// zero and less than `itemCount`.
  ///
  /// The [gridDelegate] argument must not be null.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. Both must not
  /// be null.
  ReorderableGridView.builder({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.gridItemsNotifier,
    this.reverse = false,
    this.controller,
    this.primary,
    this.dragToReorder = false,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.onReorderEnd,
    this.itemDragEnable = _defaultItemDragEnable,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.anchor = 0.0,
    this.proxyDecorator,
    this.autoScroll,
    this.onReorderStart,
  })  : childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
        assert(itemCount >= 0);

  /// Creates a scrollable, 2D array of widgets with a fixed number of tiles in
  /// the cross axis.
  ///
  /// Uses a [SliverWaterfallFlowDelegateWithFixedCrossAxisCount] as the [gridDelegate].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [SliverGrid.count], the equivalent constructor for [SliverGrid].
  ReorderableGridView.count({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.gridItemsNotifier,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.dragToReorder = false,
    this.padding,
    required int crossAxisCount,
    required this.onReorder,
    this.onReorderEnd,
    this.itemDragEnable = _defaultItemDragEnable,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    this.cacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.anchor = 0.0,
    this.proxyDecorator,
    this.autoScroll,
    this.onReorderStart,
  })  : gridDelegate = SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
        ),
        childrenDelegate = SliverChildListDelegate(children),
        assert(
          children.every((Widget w) => w.key != null),
          'All children of this widget must have a key.',
        ),
        itemBuilder = ((BuildContext context, int index) => children[index]),
        itemCount = children.length;

  /// Creates a scrollable, 2D array of widgets with tiles that each have a
  /// maximum cross-axis extent.
  ///
  /// Uses a [SliverWaterfallFlowDelegateWithMaxCrossAxisExtent] as the [gridDelegate].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [SliverGrid.extent], the equivalent constructor for [SliverGrid].
  ReorderableGridView.extent({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.gridItemsNotifier,
    this.controller,
    this.primary,
    this.dragToReorder = false,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    required double maxCrossAxisExtent,
    required this.onReorder,
    this.onReorderEnd,
    this.itemDragEnable = _defaultItemDragEnable,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    this.cacheExtent,
    List<Widget> children = const <Widget>[],
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.anchor = 0.0,
    this.proxyDecorator,
    this.autoScroll,
    this.onReorderStart,
  })  : gridDelegate = SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
        ),
        childrenDelegate = SliverChildListDelegate(children),
        assert(
          children.every((Widget w) => w.key != null),
          'All children of this widget must have a key.',
        ),
        itemBuilder = ((BuildContext context, int index) => children[index]),
        itemCount = children.length;

  /// A delegate that controls the layout of the children within the [ReorderableGridView].
  ///
  /// The [ReorderableGridView], [ReorderableGridView.builder], and [ReorderableGridView.custom] constructors let you specify this
  /// delegate explicitly. The other constructors create a [gridDelegate]
  /// implicitly.
  final SliverWaterfallFlowDelegate gridDelegate;

  final SliverChildDelegate childrenDelegate;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  final GridItemsNotifier? gridItemsNotifier;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  /// {@macro flutter.widgets.scroll_view.primary}

  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [scrollController] is null.
  final bool? primary;

  /// {@macro flutter.widgets.scroll_view.physics}
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.shrinkWrap}
  final bool shrinkWrap;

  ///When true, drag to reorder immediately; otherwise, press and hold to reorder after dragging",
  final bool dragToReorder;

  /// {@macro flutter.widgets.scroll_view.anchor}
  final double anchor;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  ///
  /// The default is [ScrollViewKeyboardDismissBehavior.manual]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final int? semanticChildCount;

  /// {@macro flutter.widgets.reorderable_list.itemBuilder}
  final IndexedWidgetBuilder itemBuilder;

  /// Allows you to manually overwrite which items can be dragged or not
  final IndexedValueGetter<bool> itemDragEnable;

  /// {@macro flutter.widgets.reorderable_list.itemCount}
  final int itemCount;

  /// {@macro flutter.widgets.reorderable_list.onReorder}
  final ReorderCallback onReorder;

  final ReorderCallback? onReorderEnd;

  /// {@macro flutter.widgets.reorderable_list.onReorderStart}
  final void Function(int index)? onReorderStart;

  /// {@macro flutter.widgets.reorderable_list.proxyDecorator}
  final ReorderItemProxyDecorator? proxyDecorator;

  /// Overrides if autoscrolling is enabled. Defaults to false if `physics` is
  /// [NeverScrollableScrollPhysics]
  final bool? autoScroll;

  @override
  ReorderableGridViewState createState() => ReorderableGridViewState();

  static bool _defaultItemDragEnable(int index) => true;
}

class ReorderableGridViewState extends State<ReorderableGridView> {
  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
        <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.itemCount);
    void moveBefore() => reorder(index, index - 1);
    // To move after, we go to index+2 because we are moving it to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);

    // If the item can move to before its current position in the grid.
    if (index > 0) {
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToStart)] =
          moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemLeft
            : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
          moveBefore;
    }

    // If the item can move to after its current position in the grid.
    if (index < widget.itemCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemRight
            : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] =
          moveAfter;
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToEnd)] =
          moveToEnd;
    }

    // We pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // We also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the grid.
    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: semanticsActions,
        child: child,
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of ReorderableListView must have a key.',
        );
      }
      return true;
    }());

    final Widget itemWithSemantics = _wrapWithSemantics(item, index);
    final Key itemGlobalKey =
        _ReorderableGridViewChildGlobalKey(item.key!, this);
    final bool enable = widget.itemDragEnable(index);

    switch (Theme.of(context).platform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return widget.dragToReorder
            ? ReorderableGridDragStartListener(
                key: itemGlobalKey,
                index: index,
                enabled: enable,
                child: itemWithSemantics,
              )
            : ReorderableGridDelayedDragStartListener(
                key: itemGlobalKey,
                index: index,
                enabled: enable,
                child: itemWithSemantics,
              );
    }
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverReorderableGrid(
            itemBuilder: _itemBuilder,
            gridDelegate: widget.gridDelegate,
            itemCount: widget.itemCount,
            onReorderEnd: widget.onReorderEnd,
            gridItemsNotifier: widget.gridItemsNotifier,
            onReorder: widget.onReorder,
            onReorderStart: widget.onReorderStart,
            proxyDecorator: widget.proxyDecorator ?? _proxyDecorator,
            autoScroll: widget.autoScroll ??
                widget.physics is! NeverScrollableScrollPhysics,
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
          ),
        ),
      ],
    );
  }
}

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
@optionalTypeArgs
class _ReorderableGridViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableGridViewChildGlobalKey(this.subKey, this.state)
      : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableGridViewChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
