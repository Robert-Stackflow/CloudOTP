import 'package:animated_tree_view/node/indexed_node.dart';

import 'i_node.dart';

/// Base class for Node that defines the actions that a Node can perform
abstract class INodeActions {
  /// Add a child [value] node to the [this] node
  void add(covariant INode value);

  /// Add a collection of [Iterable] nodes to [this] node
  void addAll(covariant Iterable<INode> iterable);

  /// Remove a child [value] node from the [this] node
  void remove(covariant INode value);

  /// Delete [this] node
  void delete();

  /// Remove all the [Iterable] nodes from [this] node
  void removeAll(covariant Iterable<INode> iterable);

  /// Remove all the child nodes from [this] node that match the criterion
  /// in the given [test]
  void removeWhere(bool test(INode element));

  /// Clear all the child nodes from [this] node. [this] node will not have
  /// children after this operation.
  void clear();
}

abstract class IIndexedNodeActions extends INodeActions {
  /// Returns the child node at the [index]
  IndexedNode at(int index);

  /// Set the [first] child in the list to [value]
  set first(IndexedNode value);

  /// Get the [first] child in the list
  IndexedNode get first;

  /// Set the [last] child in the list to [value]
  set last(IndexedNode value);

  /// Get the [last] child in the list
  IndexedNode get last;

  /// Insert an [element] in the children list at [index]
  void insert(int index, IndexedNode element);

  /// Insert a collection of [Iterable] nodes in the children list at [index]
  void insertAll(int index, Iterable<IndexedNode> iterable);

  /// Insert an [element] in the children list after the node [after]
  int insertAfter(IndexedNode after, IndexedNode element);

  /// Insert an [element] in the children list before the node [before]
  int insertBefore(IndexedNode before, IndexedNode element);

  /// Remove the child node at the [index]
  IndexedNode removeAt(int index);

  /// Get the first child node that matches the criterion in the [test].
  /// An optional [orElse] function can be provided to handle the [test] is not
  /// able to find any node that matches the provided criterion.
  IndexedNode firstWhere(bool Function(IndexedNode element) test,
      {IndexedNode orElse()?});

  /// Get the index of the first child node that matches the criterion in the
  /// [test].
  /// An optional [start] index can be provided to ignore any nodes before the
  /// index [start]
  int indexWhere(bool Function(IndexedNode element) test, [int start = 0]);

  /// Get the last child node that matches the criterion in the [test].
  /// An optional [orElse] function can be provided to handle the [test] is not
  /// able to find any node that matches the provided criterion.
  IndexedNode lastWhere(bool Function(IndexedNode element) test,
      {IndexedNode orElse()?});
}
