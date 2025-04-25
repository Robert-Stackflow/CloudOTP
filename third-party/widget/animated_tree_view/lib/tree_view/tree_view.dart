import 'dart:async';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:animated_tree_view/constants/constants.dart';
import 'package:animated_tree_view/tree_diff/tree_diff_util.dart';
import 'package:flutter/material.dart';

import '../tree_diff/tree_diff_change.dart';
import 'tree_view_state_helper.dart';
import 'widgets/expandable_node.dart';

ExpansionIndicator _defExpansionIndicatorBuilder<Data>(
        BuildContext context, ITreeNode<Data> tree) =>
    ChevronIndicator.rightDown(
      tree: tree,
      padding: EdgeInsets.all(8),
    );

ExpansionIndicator noExpansionIndicatorBuilder<Data>(
        BuildContext context, ITreeNode<Data> tree) =>
    NoExpansionIndicator(tree: tree);

/// The builder function that allows to build any item of type [Tree].
/// The [level] has been removed from the builder in version 2.0.0. To get the
/// node level, use the [ITreeNode.level] instead.
typedef TreeNodeWidgetBuilder<Tree> = Widget Function(
  BuildContext context,
  Tree item,
);

/// Callback to get the [TreeViewController] when the [TreeView] is ready
typedef TreeReadyCallback<Data, Tree extends ITreeNode<Data>> = void Function(
    TreeViewController<Data, Tree> controller);

/// The [ExpansionBehavior] provides control over the behavior of the node
/// when it is expanded.
enum ExpansionBehavior {
  /// No additional action will be taken on node expansion.
  none,

  /// The list will be scrolled to the last child of the node if it is not
  /// already visible on screen. This ensures that the last child is always visible.
  scrollToLastChild,

  /// The expanded node will be snapped to the top of the list.This ensures that the
  /// expanded node is always visible with maximum number of children.
  snapToTop,

  /// Collapse all other nodes, only the current node will remain expanded. This ensures
  /// that only one node is expanded at one time.
  collapseOthers,

  /// Collapse all other nodes, only the current node will remain expanded,
  /// also snap the node to the top of the list. This ensures that only one node is expanded at one time.
  collapseOthersAndSnapToTop,
}

///Utility class to provide easy access to basic node operations.
///The [TreeViewController] also exposes basic scrolling methods that can be used
///for scrolling to an item or a list index.
final class TreeViewController<Data, Tree extends ITreeNode<Data>> {
  final TreeViewStateHelper<Data> _animatedListController;

  const TreeViewController(this._animatedListController);

  /// Method for programmatically scrolling to an [index] in the flat list of the [TreeView].
  Future scrollToIndex(int index,
          [Duration duration = scrollAnimationDuration]) async =>
      _animatedListController.expansionBehaviourController
          .scrollToIndex(index, duration);

  /// Method for programmatically scrolling to a [node] in the [TreeView].
  Future scrollToItem(Tree node,
          [Duration duration = scrollAnimationDuration]) async =>
      _animatedListController.expansionBehaviourController
          .scrollToItem(node, duration);

  /// Method for programmatically toggling the expansion state of a [TreeNode].
  /// If the [TreeNode] is in expanded state, then it will be collapsed.
  /// Else if the [TreeNode] is in collapsed state, then it will be expanded.
  void toggleExpansion(Tree node) =>
      _animatedListController.expansionBehaviourController
          .toggleExpansion(node);

  /// Method for programmatically expanding a [TreeNode].
  void expandNode(Tree node) =>
      _animatedListController.expansionBehaviourController.expandNode(node);

  /// Method for programmatically collapsing a [TreeNode].
  void collapseNode(Tree node) =>
      _animatedListController.expansionBehaviourController.collapseNode(node);

  /// Utility method for programmatically expanding all the child nodes. By default
  /// only the immediate children of the node will be expanded.
  /// Set [recursive] to true expanding all the child nodes until the leaf is
  /// reached.
  void expandAllChildren(Tree node, {bool recursive = false}) {
    expandNode(node);
    for (final child in node.childrenAsList) {
      expandNode(child as Tree);
      if (child.childrenAsList.isNotEmpty) {
        expandAllChildren(child, recursive: recursive);
      }
    }
  }

  /// Returns the [INode.ROOT_KEY] root of the [tree]
  Tree get tree => _animatedListController.tree as Tree;

  /// Returns the [ITreeNode] at the provided [path]
  Tree elementAt(String path) => tree.elementAt(path) as Tree;
}

abstract base class _TreeView<Data, Tree extends ITreeNode<Data>>
    extends StatefulWidget {
  /// The [builder] function that is provided to the item builder
  final TreeNodeWidgetBuilder<Tree> builder;

  /// The rootNode of the [tree]. If the [tree] is updated using setState or any
  /// other state management tool, then a [TreeDiff] is performed to get all the
  /// nodes that have been modified between the old and new trees. The [TreeDiffUpdate]
  /// result is then used to apply the changes in the new tree to the old tree.
  final ITreeNode<Data> tree;

  /// An optional [scrollController] that provides more granular control over
  /// scrolling behavior
  final AutoScrollController? scrollController;

  /// Builder function for building the expansion indicator.
  /// It takes a [Tree] and builds the expansion indicator based on whether the
  /// tree node is expanded or not.
  ///
  /// The built-in [ExpansionIndicator]s are:
  ///   * [ChevronIndicator.rightDown]
  ///   * [ChevronIndicator.upDown]
  ///   * [PlusMinusIndicator]
  ///   * [NoExpansionIndicator]
  ///
  /// To create your own [ExpansionIndicator], simply extend the [ExpansionIndicator]
  /// class.
  ///
  /// In order to not show any expansion indicator just pass [noExpansionIndicatorBuilder]
  /// ** By default [_defExpansionIndicatorBuilder] is used to build expansion indicator
  final ExpansionIndicatorBuilder expansionIndicatorBuilder;

  /// This is the indentation applied to the start of an item. [Indentation.width]
  /// will be multiplied by [INode.level] before being applied.
  /// ** e.g. if the node level is 2 and [Indentation.width] is 8, then the start
  /// padding applied to an item will be 2*8 = 16
  ///
  /// ** By default [IndentStyle.none] is used and indentation lines are not drawn.
  /// Only the [indentation.width] will be used to add padding to the start of
  /// the content.
  ///
  /// * To draw indents change the style to [IndentStyle.squareJoint] or [IndentStyle.roundJoint]
  /// * To draw only scoping lines, change the style to [IndentStyle.scopingLine]
  /// The [IndentStyle], width, color and thickness are fully customizable.
  final Indentation indentation;

  /// An optional callback that can be used to handle any action when an item is
  /// tapped or clicked
  final ValueSetter<Tree>? onItemTap;

  /// Flag to show the Root Node in the [TreeView]. Root Node is always the first
  /// item in the TreeView. If it is set to [false] then the Root Node will not
  /// be displayed, rather the first child of the RootNode will be the first item
  /// in the TreeList
  final bool showRootNode;

  /// The [ExpansionBehavior] provides control over the behavior of the node
  /// when it is expanded.
  ///
  /// For more detail see [ExpansionBehavior].
  /// The default [expansionBehavior] is [ExpansionBehavior.scrollToLastChild]
  final ExpansionBehavior expansionBehavior;

  /// The amount of space by which to inset the children.
  ///
  /// This is passed directly to the [AnimatedList]'s [padding] attribute
  /// For more information see the [AnimatedList.padding]
  final EdgeInsetsGeometry? padding;

  /// Callback to get the [TreeViewController] when the [TreeView] is ready
  final TreeReadyCallback<Data, Tree>? onTreeReady;

  /// Should the tree move the focus to a new (added or inserted) node.
  /// It is true by default.
  /// If false, the [TreeView] will not scroll to the new nodes when they are
  /// added or inserted to the tree.
  final bool focusToNewNode;

  /// An optional animation for AnimatedList. If no animation is provided, AnimatedList falls back on its default.
  final Animation<double>? animation;

  final ExpansionTriggerMode expansionTriggerMode;

  const _TreeView({
    super.key,
    this.expansionBehavior = ExpansionBehavior.none,
    required this.builder,
    required this.tree,
    Indentation? indentation,
    this.scrollController,
    this.expansionIndicatorBuilder = _defExpansionIndicatorBuilder,
    this.onItemTap,
    this.padding,
    this.showRootNode = false,
    this.onTreeReady,
    this.focusToNewNode = true,
    this.animation,
    this.expansionTriggerMode = ExpansionTriggerMode.singleAndDoubleTap,
  }) : indentation = indentation ?? const Indentation(style: IndentStyle.none);
}

mixin _TreeViewState<Data, Tree extends ITreeNode<Data>,
    S extends _TreeView<Data, Tree>> on State<S> implements ListState<Tree> {
  late final TreeViewController<Data, Tree> controller;
  late final TreeViewStateHelper<Data> _stateHelper;
  late final AutoScrollController _scrollController;
  late final LastChildCacheManager<Data> _lastChildCacheManager;

  ITreeNode<Data> get _tree => _stateHelper.tree;

  @override
  void initState() {
    super.initState();

    _scrollController =
        widget.scrollController ?? AutoScrollController(axis: Axis.vertical);

    _lastChildCacheManager = LastChildCacheManager(widget.tree);

    final animatedListController = AnimatedListStateController<Data>(
      listState: this,
      showRootNode: widget.showRootNode,
      tree: widget.tree,
    );

    _stateHelper = TreeViewStateHelper<Data>(
      animatedListStateController: animatedListController,
      tree: widget.tree,
      focusToNewNode: widget.focusToNewNode,
      expansionBehaviourController: TreeViewExpansionBehaviourController<Data>(
        scrollController: _scrollController,
        expansionBehavior: widget.expansionBehavior,
        animatedListStateController: animatedListController,
        onExpandNode: (node) => _lastChildCacheManager.indexChildren(node),
      ),
    );

    widget.tree.expansionNotifier.value = !widget.showRootNode;
    controller = TreeViewController(_stateHelper);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTreeReady?.call(controller);
    });
  }

  @override
  Future<void> dispose() async {
    Future.wait([
      _stateHelper.dispose(),
      _lastChildCacheManager.dispose(),
    ]);

    super.dispose();
  }

  Widget _insertedItemBuilder(
      BuildContext context, int index, Animation<double> animation) {
    final list = _stateHelper.animatedListStateController.list;
    final node = list[index] as Tree;
    return ExpandableNodeItem.insertedNode<Data, Tree>(
      node: node,
      lastChildCacheManager: _lastChildCacheManager,
      index: index,
      builder: widget.builder,
      scrollController: _scrollController,
      animation: animation,
      indentation: widget.indentation,
      expansionIndicator: widget.expansionIndicatorBuilder,
      onToggleExpansion: (item) =>
          _stateHelper.expansionBehaviourController.toggleExpansion(item),
      onItemTap: widget.onItemTap,
      showRootNode: widget.showRootNode,
      expansionTriggerMode: widget.expansionTriggerMode,
    );
  }

  Widget _removedItemBuilder(
    BuildContext context,
    Tree node,
    Animation<double> animation,
  ) =>
      ExpandableNodeItem.removedNode<Data, Tree>(
        node: node,
        builder: (context, node) => widget.builder(context, node),
        scrollController: _scrollController,
        animation: animation,
        indentation: widget.indentation,
        expansionIndicator: widget.expansionIndicatorBuilder,
        onToggleExpansion: (item) =>
            _stateHelper.expansionBehaviourController.toggleExpansion(item),
        onItemTap: widget.onItemTap,
        showRootNode: widget.showRootNode,
        lastChildCacheManager: _lastChildCacheManager,
        expansionTriggerMode: widget.expansionTriggerMode,
      );

  @override
  void didUpdateWidget(S oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.expansionBehavior != oldWidget.expansionBehavior) {
      _stateHelper.expansionBehaviourController.expansionBehavior =
          widget.expansionBehavior;
    }

    didUpdateTree();
  }

  @visibleForTesting
  void didUpdateTree() {
    final treeDiff = calculateTreeDiff<ITreeNode<Data>>(_tree, widget.tree);
    if (treeDiff.isEmpty) return;

    for (final update in treeDiff) {
      switch (update) {
        case TreeDiffNodeAdd tree:
          {
            final node = tree.data as Tree;
            final parentNode = _tree
                .elementAt(node.parent?.path ?? node.root.path) as INodeActions;
            parentNode.add(node);
          }
        case TreeDiffNodeInsert tree:
          {
            final node = tree.data as Tree;
            final parentNode =
                _tree.elementAt(node.parent?.path ?? node.root.path)
                    as IIndexedNodeActions;
            parentNode.insert(tree.position, node as IndexedNode);
          }
        case TreeDiffNodeRemove tree:
          {
            final node = tree.data as Tree;
            final parentNode = _tree
                .elementAt(node.parent?.path ?? node.root.path) as INodeActions;

            parentNode.remove(node);
          }
        case TreeDiffNodeUpdate tree:
          {
            final node = tree.data as Tree;
            final oldNode = _tree.elementAt(node.path) as Tree;
            oldNode.data = node.data;
          }
      }
    }
  }
}

/// The [TreeView] allows to visually display a tree data structure in a linear
/// list which animates the node addition, removal, changes and expansion/collapse
/// of the node.
///
/// The [TreeView] is based on the [AnimatedList], so it can be used as a replacement
/// of [AnimatedList].
///
/// The default [TreeView.simple] uses a [TreeNode] internally, which is based on the
/// [Map] data structure for maintaining the children states.
/// The [TreeNode] does not allow insertion and removal of
/// items at index positions. This allows for more efficient insertion and
/// retrieval of items at child nodes, as child items can be readily accessed
/// using the map keys.
///
/// The complexity for accessing child nodes in [TreeView] is simply O(node_level).
/// e.g. for path './.level1/level2', complexity is simply O(2).
///
/// See also:
///   For a TreeView that supports Slivers, that can used with a [CustomScrollView]
///   look into the [SliverTreeView].
final class TreeView<Data, Tree extends ITreeNode<Data>>
    extends _TreeView<Data, Tree> {
  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// This is passed directly to the [AnimatedList]'s [primary] attribute
  /// For more information see the [AnimatedList.primary]
  final bool? primary;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// This is passed directly to the [AnimatedList]'s [physics] attribute
  /// For more information see the [AnimatedList.physics]
  final ScrollPhysics? physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  /// This is passed directly to the [AnimatedList]'s [shrinkWrap] attribute
  /// For more information see the [AnimatedList.shrinkWrap]
  final bool shrinkWrap;

  const TreeView._({
    super.key,
    super.expansionBehavior,
    required super.builder,
    required super.tree,
    super.indentation,
    super.scrollController,
    super.expansionIndicatorBuilder,
    super.onItemTap,
    this.primary,
    this.physics,
    super.padding,
    this.shrinkWrap = false,
    super.showRootNode,
    super.onTreeReady,
    super.animation,
    super.focusToNewNode,
    super.expansionTriggerMode,
  });

  /// The default implementation of [TreeView] that uses a [TreeNode] internally,
  /// which is based on the
  /// [Map] data structure for maintaining the children states.
  /// The [TreeNode] does not allow insertion and removal of
  /// items at index positions. This allows for more efficient insertion and
  /// retrieval of items at child nodes, as child items can be readily accessed
  /// using the map keys.
  ///
  /// The complexity for accessing child nodes in [TreeView.simple] is simply O(node_level).
  /// e.g. for path './.level1/level2', complexity is simply O(2).
  ///
  /// ** See code in example/lib/samples/treeview/treeview_modification_sample.dart **
  ///
  /// See also:
  ///   * For a [TreeView] that allows for insertion and removal of
  ///   items at index positions, use the alternate [TreeView.indexed].
  ///   * For using an object that extends the [TreeNode] instead of using [TreeNode]
  ///   directly, used the [TreeView.simpleTyped] which allows for typed objects
  ///   to be returned in the [builder]
  static TreeView<Data, TreeNode<Data>> simple<Data>({
    Key? key,
    required TreeNodeWidgetBuilder<TreeNode<Data>> builder,
    required final TreeNode<Data> tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<TreeNode<Data>>? onItemTap,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, TreeNode<Data>>? onTreeReady,
    Animation<double>? animation,
    ExpansionTriggerMode expansionTriggerMode =
        ExpansionTriggerMode.singleAndDoubleTap,
  }) =>
      TreeView._(
        key: key,
        builder: builder,
        tree: tree,
        expansionBehavior: expansionBehavior,
        indentation: indentation,
        expansionIndicatorBuilder:
            expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
        scrollController: scrollController,
        onItemTap: onItemTap,
        primary: primary,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        showRootNode: showRootNode,
        onTreeReady: onTreeReady,
        focusToNewNode: focusToNewNode,
        animation: animation,
        expansionTriggerMode: expansionTriggerMode,
      );

  /// Use the typed constructor if you are extending the [TreeNode] instead of
  /// directly wrapping the data in the [TreeNode]. Using the [TreeView.simpleTyped]
  /// allows the [builder] to return the correctly typed [Tree] object.
  ///
  /// The default implementation of [TreeView] that uses a [TreeNode] internally,
  /// which is based on the [Map] data structure for maintaining the children states.
  /// The [TreeNode] does not allow insertion and removal of
  /// items at index positions. This allows for more efficient insertion and
  /// retrieval of items at child nodes, as child items can be readily accessed
  /// using the map keys.
  ///
  /// The complexity for accessing child nodes in [TreeView.simple] is simply O(node_level).
  /// e.g. for path './.level1/level2', complexity is simply O(2).
  ///
  /// ** See code in example/lib/samples/treeview/treeview_custom_object_sample.dart **
  ///
  /// See also:
  ///   * For a [TreeView] that allows for insertion and removal of
  ///   items at index positions, use the alternate [TreeView.indexTyped].
  ///   * If you are wrapping the data directly in the [TreeNode] instead of
  ///   extending the [TreeNode], then you can also use the simpler [TreeView.simple].
  static TreeView<Data, Tree> simpleTyped<Data, Tree extends TreeNode<Data>>({
    Key? key,
    required TreeNodeWidgetBuilder<Tree> builder,
    required final Tree tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<Tree>? onItemTap,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, Tree>? onTreeReady,
    Animation<double>? animation,
  }) =>
      TreeView._(
        key: key,
        builder: builder,
        tree: tree,
        expansionBehavior: expansionBehavior,
        indentation: indentation,
        expansionIndicatorBuilder:
            expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
        scrollController: scrollController,
        onItemTap: onItemTap,
        primary: primary,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        showRootNode: showRootNode,
        onTreeReady: onTreeReady,
        focusToNewNode: focusToNewNode,
        animation: animation,
      );

  /// The alternate implementation of [TreeView] uses an [IndexedNode] internally,
  /// which is based on the [List] data structure for maintaining the children states.
  /// The [IndexedNode] allows indexed based operations like insertion and removal of
  /// items at index positions. This allows for movement, addition and removal of
  /// child nodes based on indices.
  ///
  /// The complexity for accessing child nodes in [TreeView.indexed] is simply
  /// O(node_level ^ children).
  ///
  /// ** See code in example/lib/samples/treeview/treeview_indexed_modification_sample.dart **
  ///
  /// See also:
  ///   * If you do not require index based operations, then use the more performant
  ///   and efficient [TreeView.simple] instead.
  ///   * For using an object that extends the [IndexedTreeNode] instead of using
  ///   [IndexedTreeNode] directly, used the [TreeView.indexTyped] which allows
  ///   for typed objects to be returned in the [builder]
  static TreeView<Data, IndexedTreeNode<Data>> indexed<Data>({
    Key? key,
    required TreeNodeWidgetBuilder<IndexedTreeNode<Data>> builder,
    required final IndexedTreeNode<Data> tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<IndexedTreeNode<Data>>? onItemTap,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, IndexedTreeNode<Data>>? onTreeReady,
    Animation<double>? animation,
  }) =>
      TreeView._(
        key: key,
        builder: builder,
        tree: tree,
        expansionBehavior: expansionBehavior,
        indentation: indentation,
        expansionIndicatorBuilder:
            expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
        scrollController: scrollController,
        onItemTap: onItemTap,
        primary: primary,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        showRootNode: showRootNode,
        onTreeReady: onTreeReady,
        focusToNewNode: focusToNewNode,
        animation: animation,
      );

  /// Use the typed constructor if you are extending the [IndexedTreeNode] instead
  /// of directly wrapping the data in the [IndexedTreeNode].
  /// Using the [TreeView.indexTyped] allows the [builder] to return the correctly
  /// typed [Tree] object.
  ///
  /// This alternate implementation of [TreeView] uses an [IndexedNode] internally,
  /// which is based on the [List] data structure for maintaining the children states.
  /// The [IndexedNode] allows indexed based operations like insertion and removal of
  /// items at index positions. This allows for movement, addition and removal of
  /// child nodes based on indices.
  ///
  /// The complexity for accessing child nodes in [TreeView.indexed] is simply
  /// O(node_level ^ children).
  ///
  /// See also:
  ///   * If you do not require index based operations, then use the more performant
  ///   and efficient [TreeView.simpleTyped] instead.
  ///   * If you are wrapping the data directly in the [IndexedTreeNode] instead of
  ///     extending the [IndexedTreeNode], then you can also use the simpler [TreeView.indexed].
  static TreeView<Data, Tree>
      indexTyped<Data, Tree extends IndexedTreeNode<Data>>({
    Key? key,
    required TreeNodeWidgetBuilder<Tree> builder,
    required final Tree tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<Tree>? onItemTap,
    bool? primary,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, Tree>? onTreeReady,
    Animation<double>? animation,
  }) =>
          TreeView._(
            key: key,
            builder: builder,
            tree: tree,
            expansionBehavior: expansionBehavior,
            indentation: indentation,
            expansionIndicatorBuilder:
                expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
            scrollController: scrollController,
            onItemTap: onItemTap,
            primary: primary,
            physics: physics,
            padding: padding,
            shrinkWrap: shrinkWrap,
            showRootNode: showRootNode,
            onTreeReady: onTreeReady,
            focusToNewNode: focusToNewNode,
            animation: animation,
          );

  @override
  State<StatefulWidget> createState() => TreeViewState<Data, Tree>(animation);
}

class TreeViewState<Data, Tree extends ITreeNode<Data>>
    extends State<TreeView<Data, Tree>>
    with _TreeViewState<Data, Tree, TreeView<Data, Tree>> {
  TreeViewState(Animation<double>? animation) : _animation = animation;

  static const _errorMsg =
      "Animated list state not found from GlobalKey<AnimatedListState>";

  late final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();

  final Animation<double>? _animation;

  @override
  void insertItem(int index, {Duration duration = animationDuration}) {
    if (_listKey.currentState == null) throw Exception(_errorMsg);
    _listKey.currentState!.insertItem(index, duration: duration);
  }

  @override
  void removeItem(int index, Tree item,
      {Duration duration = animationDuration}) {
    if (_listKey.currentState == null) throw Exception(_errorMsg);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) =>
          _removedItemBuilder(context, item, _animation ?? animation),
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _stateHelper.animatedListStateController.list.length,
      controller: _scrollController,
      primary: widget.primary,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemBuilder: (context, index, animation) =>
          _insertedItemBuilder(context, index, _animation ?? animation),
    );
  }
}

/// The [SliverTreeView] allows to visually display a tree data structure in a
/// linear list which animates the node addition, removal, changes and
/// expansion/collapse of the node.
///
/// The [SliverTreeView] is based on the [SliverAnimatedList], so it can be used
/// as a replacement of [SliverAnimatedList].
///
/// The main advantage of using a [SliverTreeView] over the [TreeView] is that
/// it can be easily used with others slivers in a [CustomScrollView], which means
/// that you can easily implement a fancy animated list. The slivers
/// are lazy loaded by default, so it can be easily mixed with other widgets
/// without any loss of performance.
///
/// The default [SliverTreeView.simple] uses a [TreeNode] internally, which is
/// based on the [Map] data structure for maintaining the children states.
/// The [TreeNode] does not allow insertion and removal of
/// items at index positions. This allows for more efficient insertion and
/// retrieval of items at child nodes, as child items can be readily accessed
/// using the map keys.
///
/// The complexity for accessing child nodes in [SliverTreeView] is simply O(node_level).
/// e.g. for path './.level1/level2', complexity is simply O(2).
final class SliverTreeView<Data, Tree extends ITreeNode<Data>>
    extends _TreeView<Data, Tree> {
  const SliverTreeView._({
    super.key,
    required super.builder,
    required super.tree,
    super.expansionBehavior,
    super.expansionIndicatorBuilder,
    super.indentation,
    super.onItemTap,
    super.padding,
    super.scrollController,
    super.showRootNode,
    super.onTreeReady,
    super.focusToNewNode,
    super.animation,
  }) : assert(
            expansionBehavior == ExpansionBehavior.none ||
                scrollController != null,
            "\n\nTo apply an ExpansionBehaviour, please also provide an AutoScrollController as well.\n\n"
            "The same instance of the scroll controller needs to be applied to the SliverTreeView and the CustomScrollView holding the SliverTreeView.\n\n"
            "For more info see example/lib/samples/sliver_treeview/sliver_treeview_sample.dart\n\n");

  @override
  State<StatefulWidget> createState() =>
      SliverTreeViewState<Data, Tree>(animation);

  /// The default implementation of [SliverTreeView] that uses a [TreeNode] internally,
  /// which is based on the [Map] data structure for maintaining the children states.
  /// The [TreeNode] does not allow insertion and removal of
  /// items at index positions. This allows for more efficient insertion and
  /// retrieval of items at child nodes, as child items can be readily accessed
  /// using the map keys.
  ///
  /// The main advantage of using a [SliverTreeView] over the [TreeView] is that
  /// it can be easily used with others slivers in a [CustomScrollView], which means
  /// that you can easily implement a fancy animated list. The slivers
  /// are lazy loaded by default, so it can be easily mixed with other widgets
  /// without any loss of performance.
  ///
  /// The complexity for accessing child nodes in [SliverTreeView.simple] is simply O(node_level).
  /// e.g. for path './.level1/level2', complexity is simply O(2).
  ///
  /// ** See code in example/lib/samples/sliver_treeview/sliver_treeview_sample.dart **
  ///
  /// See also:
  ///   * For a [SliverTreeView] that allows for insertion and removal of
  ///   items at index positions, use the alternate [SliverTreeView.indexed].
  ///   * For using an object that extends the [TreeNode] instead of using [TreeNode]
  ///   directly, used the [SliverTreeView.simpleTyped] which allows for typed objects
  ///   to be returned in the [builder]
  static SliverTreeView<Data, TreeNode<Data>> simple<Data>({
    Key? key,
    required TreeNodeWidgetBuilder<TreeNode<Data>> builder,
    required final TreeNode<Data> tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<TreeNode<Data>>? onItemTap,
    EdgeInsetsGeometry? padding,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, TreeNode<Data>>? onTreeReady,
    Animation<double>? animation,
  }) =>
      SliverTreeView._(
        key: key,
        builder: builder,
        tree: tree,
        expansionBehavior: expansionBehavior,
        indentation: indentation,
        expansionIndicatorBuilder:
            expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
        scrollController: scrollController,
        onItemTap: onItemTap,
        padding: padding,
        showRootNode: showRootNode,
        onTreeReady: onTreeReady,
        focusToNewNode: focusToNewNode,
        animation: animation,
      );

  /// Use the typed constructor if you are extending the [TreeNode] instead of
  /// directly wrapping the data in the [TreeNode]. Using the [SliverTreeView.simpleTyped]
  /// allows the [builder] to return the correctly typed [Tree] object.
  ///
  /// The default implementation of [SliverTreeView] that uses a [TreeNode] internally,
  /// which is based on the [Map] data structure for maintaining the children states.
  /// The [TreeNode] does not allow insertion and removal of
  /// items at index positions. This allows for more efficient insertion and
  /// retrieval of items at child nodes, as child items can be readily accessed
  /// using the map keys.
  ///
  /// The main advantage of using a [SliverTreeView] over the [TreeView] is that
  /// it can be easily used with others slivers in a [CustomScrollView], which means
  /// that you can easily implement a fancy animated list. The slivers
  /// are lazy loaded by default, so it can be easily mixed with other widgets
  /// without any loss of performance.
  /// The complexity for accessing child nodes in [SliverTreeView.simple] is simply O(node_level).
  /// e.g. for path './.level1/level2', complexity is simply O(2).
  ///
  /// ** See code in example/lib/samples/sliver_treeview/sliver_treeview_custom_object_sample.dart **
  ///
  /// See also:
  ///   * For a [SliverTreeView] that allows for insertion and removal of
  ///   items at index positions, use the alternate [SliverTreeView.indexTyped].
  ///   * If you are wrapping the data directly in the [TreeNode] instead of
  ///   extending the [TreeNode], then you can also use the simpler [SliverTreeView.simple].
  static SliverTreeView<Data, Tree>
      simpleTyped<Data, Tree extends TreeNode<Data>>({
    Key? key,
    required TreeNodeWidgetBuilder<Tree> builder,
    required final Tree tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<Tree>? onItemTap,
    EdgeInsetsGeometry? padding,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, Tree>? onTreeReady,
    Animation<double>? animation,
  }) =>
          SliverTreeView._(
            key: key,
            builder: builder,
            tree: tree,
            expansionBehavior: expansionBehavior,
            indentation: indentation,
            expansionIndicatorBuilder:
                expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
            scrollController: scrollController,
            onItemTap: onItemTap,
            padding: padding,
            showRootNode: showRootNode,
            onTreeReady: onTreeReady,
            focusToNewNode: focusToNewNode,
            animation: animation,
          );

  /// The alternate implementation of [SliverTreeView] uses an [IndexedNode]
  /// internally, which is based on the [List] data structure for maintaining the
  /// children states. The [IndexedNode] allows indexed based operations like
  /// insertion and removal of items at index positions. This allows for movement,
  /// addition and removal of child nodes based on indices.
  ///
  /// The complexity for accessing child nodes in [SliverTreeView.indexed] is simply
  /// O(node_level ^ children).
  /// The main advantage of using a [SliverTreeView] over the [TreeView] is that
  /// it can be easily used with others slivers in a [CustomScrollView], which means
  /// that you can easily implement a fancy animated list. The slivers
  /// are lazy loaded by default, so it can be easily mixed with other widgets
  /// without any loss of performance.
  ///
  /// ** See code in example/lib/samples/sliver_treeview/sliver_treeview_sample.dart **
  ///
  /// See also:
  ///   * If you do not require index based operations, then use the more performant
  ///   and efficient [SliverTreeView.simple] instead.
  ///   * For using an object that extends the [IndexedTreeNode] instead of using
  ///   [IndexedTreeNode] directly, used the [SliverTreeView.indexTyped] which allows
  ///   for typed objects to be returned in the [builder]
  static SliverTreeView<Data, IndexedTreeNode<Data>> indexed<Data>({
    Key? key,
    required TreeNodeWidgetBuilder<IndexedTreeNode<Data>> builder,
    required final IndexedTreeNode<Data> tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<IndexedTreeNode<Data>>? onItemTap,
    EdgeInsetsGeometry? padding,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, IndexedTreeNode<Data>>? onTreeReady,
    Animation<double>? animation,
  }) =>
      SliverTreeView._(
        key: key,
        builder: builder,
        tree: tree,
        expansionBehavior: expansionBehavior,
        indentation: indentation,
        expansionIndicatorBuilder:
            expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
        scrollController: scrollController,
        onItemTap: onItemTap,
        padding: padding,
        showRootNode: showRootNode,
        onTreeReady: onTreeReady,
        focusToNewNode: focusToNewNode,
        animation: animation,
      );

  /// Use the typed constructor if you are extending the [IndexedTreeNode] instead
  /// of directly wrapping the data in the [IndexedTreeNode].
  /// Using the [SliverTreeView.indexTyped] allows the [builder] to return the correctly
  /// typed [Tree] object.
  ///
  /// This alternate implementation of [SliverTreeView] uses an [IndexedNode] internally,
  /// which is based on the [List] data structure for maintaining the children states.
  /// The [IndexedNode] allows indexed based operations like insertion and removal of
  /// items at index positions. This allows for movement, addition and removal of
  /// child nodes based on indices.
  /// The complexity for accessing child nodes in [SliverTreeView.indexed] is simply
  /// O(node_level ^ children).
  ///
  /// The main advantage of using a [SliverTreeView] over the [TreeView] is that
  /// it can be easily used with others slivers in a [CustomScrollView], which means
  /// that you can easily implement a fancy animated list. The slivers
  /// are lazy loaded by default, so it can be easily mixed with other widgets
  /// without any loss of performance.
  ///
  /// The complexity for accessing child nodes in [SliverTreeView.indexed] is simply
  /// O(node_level ^ children).
  ///
  /// ** See code in example/lib/samples/sliver_treeview/sliver_treeview_custom_object_sample.dart **
  ///
  /// See also:
  ///   * If you do not require index based operations, the more performant and
  ///     efficient [SliverTreeView.simpleTyped] instead.
  ///   * If you are wrapping the data directly in the [IndexedTreeNode] instead of
  ///     extending the [IndexedTreeNode], then you can also use the simpler [TreeView.indexed].
  static SliverTreeView<Data, Tree>
      indexTyped<Data, Tree extends IndexedTreeNode<Data>>({
    Key? key,
    required TreeNodeWidgetBuilder<Tree> builder,
    required final Tree tree,
    ExpansionBehavior expansionBehavior = ExpansionBehavior.none,
    Indentation? indentation,
    AutoScrollController? scrollController,
    ExpansionIndicatorBuilder? expansionIndicatorBuilder,
    ValueSetter<Tree>? onItemTap,
    EdgeInsetsGeometry? padding,
    bool showRootNode = true,
    bool focusToNewNode = true,
    TreeReadyCallback<Data, Tree>? onTreeReady,
    Animation<double>? animation,
  }) =>
          SliverTreeView._(
            key: key,
            builder: builder,
            tree: tree,
            expansionBehavior: expansionBehavior,
            indentation: indentation,
            expansionIndicatorBuilder:
                expansionIndicatorBuilder ?? _defExpansionIndicatorBuilder,
            scrollController: scrollController,
            onItemTap: onItemTap,
            padding: padding,
            showRootNode: showRootNode,
            onTreeReady: onTreeReady,
            focusToNewNode: focusToNewNode,
            animation: animation,
          );
}

class SliverTreeViewState<Data, Tree extends ITreeNode<Data>>
    extends State<SliverTreeView<Data, Tree>>
    with _TreeViewState<Data, Tree, SliverTreeView<Data, Tree>> {
  SliverTreeViewState(Animation<double>? animation) : _animation = animation;
  static const _errorMsg =
      "Sliver Animated list state not found from GlobalKey<SliverAnimatedListState>";

  late final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  final Animation<double>? _animation;

  @override
  void insertItem(int index, {Duration duration = animationDuration}) {
    if (_listKey.currentState == null) throw Exception(_errorMsg);
    _listKey.currentState!.insertItem(index, duration: duration);
  }

  @override
  void removeItem(int index, Tree item,
      {Duration duration = animationDuration}) {
    if (_listKey.currentState == null) throw Exception(_errorMsg);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) =>
          _removedItemBuilder(context, item, _animation ?? animation),
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _stateHelper.animatedListStateController.list.length,
      itemBuilder: (context, index, animation) =>
          _insertedItemBuilder(context, index, _animation ?? animation),
    );
  }
}
