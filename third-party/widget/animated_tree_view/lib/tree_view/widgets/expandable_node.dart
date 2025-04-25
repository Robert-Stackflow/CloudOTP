import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:animated_tree_view/tree_view/tree_view_state_helper.dart';
import 'package:flutter/material.dart';

enum ExpansionTriggerMode {
  singleTap,
  doubleTap,
  singleAndDoubleTap;

  bool get isSingleTap =>
      this == ExpansionTriggerMode.singleTap ||
      this == ExpansionTriggerMode.singleAndDoubleTap;

  bool get isDoubleTap =>
      this == ExpansionTriggerMode.doubleTap ||
      this == ExpansionTriggerMode.singleAndDoubleTap;
}

class ExpandableNodeItem<Data, Tree extends ITreeNode<Data>>
    extends StatelessWidget {
  final TreeNodeWidgetBuilder<Tree> builder;
  final AutoScrollController scrollController;
  final Tree node;
  final Animation<double> animation;
  final Indentation indentation;
  final ExpansionIndicatorBuilder<Data>? expansionIndicatorBuilder;
  final bool remove;
  final int? index;
  final ValueSetter<Tree>? onItemTap;
  final ValueSetter<Tree>? onItemDoubleTap;
  final ValueSetter<Tree> onToggleExpansion;
  final ExpansionTriggerMode expansionTriggerMode;
  final bool showRootNode;
  final LastChildCacheManager lastChildCacheManager;

  static Widget insertedNode<Data, Tree extends ITreeNode<Data>>({
    required int index,
    required Tree node,
    required TreeNodeWidgetBuilder<Tree> builder,
    required AutoScrollController scrollController,
    required Animation<double> animation,
    required ExpansionIndicatorBuilder<Data>? expansionIndicator,
    required ValueSetter<Tree>? onItemTap,
    required ValueSetter<Tree> onToggleExpansion,
    required bool showRootNode,
    required Indentation indentation,
    required LastChildCacheManager lastChildCacheManager,
    required ExpansionTriggerMode expansionTriggerMode,
  }) {
    return ValueListenableBuilder<INode>(
      key: ValueKey(node.key + index.toString()),
      valueListenable: node,
      builder: (context, treeNode, _) => ValueListenableBuilder(
        valueListenable: (treeNode as Tree).listenableData,
        builder: (context, data, _) => ExpandableNodeItem<Data, Tree>(
          builder: builder,
          scrollController: scrollController,
          node: node,
          index: index,
          animation: animation,
          indentation: indentation,
          expansionIndicatorBuilder: expansionIndicator,
          onToggleExpansion: onToggleExpansion,
          onItemTap: onItemTap,
          showRootNode: showRootNode,
          lastChildCacheManager: lastChildCacheManager,
          expansionTriggerMode: expansionTriggerMode,
        ),
      ),
    );
  }

  static Widget removedNode<Data, Tree extends ITreeNode<Data>>({
    required Tree node,
    required TreeNodeWidgetBuilder<Tree> builder,
    required AutoScrollController scrollController,
    required Animation<double> animation,
    required ExpansionIndicatorBuilder<Data>? expansionIndicator,
    required ValueSetter<Tree>? onItemTap,
    required ValueSetter<Tree> onToggleExpansion,
    required bool showRootNode,
    required Indentation indentation,
    required LastChildCacheManager lastChildCacheManager,
    required ExpansionTriggerMode expansionTriggerMode,
  }) {
    return ExpandableNodeItem<Data, Tree>(
      key: ValueKey(node.key),
      builder: builder,
      scrollController: scrollController,
      node: node,
      remove: true,
      animation: animation,
      indentation: indentation,
      expansionIndicatorBuilder: expansionIndicator,
      onItemTap: onItemTap,
      onToggleExpansion: onToggleExpansion,
      showRootNode: showRootNode,
      lastChildCacheManager: lastChildCacheManager,
      expansionTriggerMode: expansionTriggerMode,
    );
  }

  const ExpandableNodeItem({
    super.key,
    required this.builder,
    required this.scrollController,
    required this.node,
    required this.animation,
    required this.onToggleExpansion,
    this.index,
    this.remove = false,
    this.expansionIndicatorBuilder,
    this.onItemTap,
    required this.showRootNode,
    required this.indentation,
    required this.lastChildCacheManager,
    this.expansionTriggerMode = ExpansionTriggerMode.singleAndDoubleTap,
    this.onItemDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemContainer = ExpandableNodeContainer(
      key: ValueKey("container#$key"),
      animation: animation,
      node: node,
      indentation: indentation,
      minLevelToIndent: showRootNode ? 0 : 1,
      lastChildCacheManager: lastChildCacheManager,
      onIndicatorTap: (item) => onToggleExpansion(item as Tree),
      expansionIndicator: node.childrenAsList.isEmpty
          ? null
          : expansionIndicatorBuilder?.call(context, node),
      onTap: remove || (!expansionTriggerMode.isSingleTap && onItemTap == null)
          ? null
          : (dynamic item) {
              if (expansionTriggerMode.isSingleTap) {
                onToggleExpansion(item);
              }
              if (onItemTap != null) onItemTap!(item);
            },
      onDoubleTap: remove ||
              (!expansionTriggerMode.isDoubleTap && onItemDoubleTap == null)
          ? null
          : (dynamic item) {
              if (expansionTriggerMode.isDoubleTap) {
                onToggleExpansion(item);
              }
              if (onItemDoubleTap != null) onItemDoubleTap!(item);
            },
      child: builder(context, node),
    );

    var widget = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: itemContainer,
    );

    if (index == null || remove) return widget;

    return AutoScrollTag(
      key: ValueKey("tag#${node.key}"),
      controller: scrollController,
      index: index!,
      child: widget,
    );
  }
}

class ExpandableNodeContainer<T> extends StatelessWidget {
  final Animation<double> animation;
  final ValueSetter<ITreeNode<T>>? onTap;
  final ValueSetter<ITreeNode<T>>? onDoubleTap;
  final ValueSetter<ITreeNode<T>>? onIndicatorTap;
  final ITreeNode<T> node;
  final ExpansionIndicator? expansionIndicator;
  final Indentation indentation;
  final Widget child;
  final int minLevelToIndent;
  final LastChildCacheManager lastChildCacheManager;

  const ExpandableNodeContainer({
    super.key,
    required this.animation,
    required this.onTap,
    required this.onDoubleTap,
    required this.onIndicatorTap,
    required this.child,
    required this.node,
    required this.indentation,
    required this.minLevelToIndent,
    required this.lastChildCacheManager,
    this.expansionIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap == null ? null : () => onTap!(node),
        onDoubleTap: onDoubleTap == null ? null : () => onDoubleTap!(node),
        child: Indent(
          indentation: indentation,
          node: node,
          minLevelToIndent: minLevelToIndent,
          lastChildCacheManager: lastChildCacheManager,
          child: expansionIndicator == null
              ? child
              : PositionedExpansionIndicator(
                  expansionIndicator: expansionIndicator!,
                  onIndicatorTap: () => onIndicatorTap!(node),
                  child: child,
                ),
        ),
      ),
    );
  }
}
