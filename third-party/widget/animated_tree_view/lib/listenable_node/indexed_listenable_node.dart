import 'dart:async';

import 'package:animated_tree_view/helpers/event_stream_controller.dart';
import 'package:animated_tree_view/helpers/exceptions.dart';
import 'package:animated_tree_view/node/base/i_node.dart';
import 'package:animated_tree_view/node/indexed_node.dart';
import 'package:flutter/foundation.dart';

import 'base/i_listenable_node.dart';

class IndexedListenableNode extends IndexedNode
    with ChangeNotifier
    implements IListenableNode {
  /// A listenable implementation the [Node].
  /// The mutations to the [Node] can be listened to using the [ValueListenable]
  /// interface or the [addedNodes] and [removedNodes] streams.
  ///
  /// The [IndexedListenableNode] can also be used with a [ValueListenableBuilder]
  /// for updating the UI whenever the [Node] is mutated.
  ///
  /// Default constructor that takes an optional [key] and a parent.
  /// Make sure that the provided [key] is unique to among the siblings of the node.
  /// If a [key] is not provided, then a [UniqueKey] will automatically be
  /// assigned to the [Node].
  IndexedListenableNode({String? key, IndexedNode? parent})
      : super(key: key, parent: parent);

  /// Alternate factory constructor for [IndexedListenableNode] that should be used for
  /// the [root] nodes.
  factory IndexedListenableNode.root() =>
      IndexedListenableNode(key: INode.ROOT_KEY);

  /// This is the parent [ListenableNode]. Only the root node has a null [parent]
  IndexedListenableNode? parent;

  /// Getter to get the [value] of the [ValueListenable]. It returns the [root]
  IndexedListenableNode get value => root;

  /// This returns the [children] as an iterable list.
  List<IndexedListenableNode> get childrenAsList =>
      List<IndexedListenableNode>.from(super.childrenAsList);

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  IndexedListenableNode get root => super.root as IndexedListenableNode;

  /// Get the [first] child in the list
  IndexedListenableNode get first => super.first as IndexedListenableNode;

  /// Set the [last] child in the list to [value]
  IndexedListenableNode get last => super.last as IndexedListenableNode;

  /// Set the [first] child in the list to [value]
  set first(IndexedNode value) {
    this.first = value;
    _notifyListeners();
  }

  /// Set the [last] child in the list to [value]
  set last(IndexedNode value) {
    this.last = value;
    _notifyListeners();
  }

  /// Get the first child node that matches the criterion in the [test].
  /// An optional [orElse] function can be provided to handle the [test] is not
  /// able to find any node that matches the provided criterion.
  IndexedListenableNode firstWhere(bool Function(IndexedNode element) test,
      {IndexedNode orElse()?}) {
    return super.firstWhere(test, orElse: orElse) as IndexedListenableNode;
  }

  /// Get the index of the first child node that matches the criterion in the
  /// [test].
  /// An optional [start] index can be provided to ignore any nodes before the
  /// index [start]
  int indexWhere(bool Function(IndexedNode element) test, [int start = 0]) {
    return super.indexWhere(test, start);
  }

  /// Get the last child node that matches the criterion in the [test].
  /// An optional [orElse] function can be provided to handle the [test] is not
  /// able to find any node that matches the provided criterion.
  IndexedListenableNode lastWhere(bool Function(IndexedNode element) test,
      {IndexedNode orElse()?}) {
    return super.lastWhere(test, orElse: orElse) as IndexedListenableNode;
  }

  final EventStreamController<NodeAddEvent<INode>> _addedNodes =
      EventStreamController();

  final EventStreamController<NodeInsertEvent<INode>> _insertedNodes =
      EventStreamController();

  final EventStreamController<NodeRemoveEvent<INode>> _removedNodes =
      EventStreamController();

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is added to the current node.
  ///
  /// The stream should only be listened to on the [root] node.
  /// [ActionNotAllowedException] if a non-root tries to listen the [addedNodes]
  Stream<NodeAddEvent<INode>> get addedNodes {
    if (!isRoot) throw ActionNotAllowedException.listener(this);
    return _addedNodes.stream;
  }

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is removed from the current node.
  ///
  /// The stream should only be listened to on the [root] node.
  /// [ActionNotAllowedException] if a non-root tries to listen the [removedNodes]
  Stream<NodeRemoveEvent<INode>> get removedNodes {
    if (!isRoot) throw ActionNotAllowedException.listener(this);
    return _removedNodes.stream;
  }

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is inserted in the current node.
  ///
  /// The stream should only be listened to on the [root] node.
  /// [ActionNotAllowedException] if a non-root tries to listen the [insertedNodes]
  Stream<NodeInsertEvent<INode>> get insertedNodes {
    if (!isRoot) throw ActionNotAllowedException.listener(this);
    return _insertedNodes.stream;
  }

  /// Add a child [value] node to the [children]. The [value] will be inserted
  /// after the last child in the list
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  void add(IndexedNode value) {
    super.add(value);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List.from([value])));
  }

  /// Add a collection of [Iterable] nodes to [children]. The [iterable] will be
  /// inserted after the last child in the list
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  void addAll(Iterable<IndexedNode> iterable) {
    super.addAll(iterable);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List.from(iterable)));
  }

  /// Insert an [element] in the children list at [index]
  ///
  /// The [ValueListenable] and [insertedNodes] listeners will also be notified
  /// on this operation
  void insert(int index, IndexedNode element) {
    super.insert(index, element);
    _notifyListeners();
    _notifyNodesInserted(NodeInsertEvent(List.from([element]), index));
  }

  /// Insert an [element] in the children list after the node [after]
  ///
  /// The [ValueListenable] and [insertedNodes] listeners will also be notified
  /// on this operation
  int insertAfter(IndexedNode after, IndexedNode element) {
    final index = super.insertAfter(after, element);
    return index;
  }

  /// Insert an [element] in the children list before the node [before]
  ///
  /// The [ValueListenable] and [insertedNodes] listeners will also be notified
  /// on this operation
  int insertBefore(IndexedNode before, IndexedNode element) {
    final index = super.insertBefore(before, element);
    return index;
  }

  /// Insert a collection of [Iterable] nodes in the children list at [index]
  ///
  /// The [ValueListenable] and [insertedNodes] listeners will also be notified
  /// on this operation
  void insertAll(int index, Iterable<IndexedNode> iterable) {
    super.insertAll(index, iterable);
    _notifyListeners();
    _notifyNodesInserted(NodeInsertEvent(List.from(iterable), index));
  }

  /// Delete [this] node
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void delete() {
    final nodeToRemove = this;
    super.delete();
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from([nodeToRemove])));
  }

  /// Remove a child [value] node from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void remove(IndexedNode value) {
    super.remove(value);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from([value])));
  }

  /// Remove the child node at the [index]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  IndexedListenableNode removeAt(int index) {
    final removedNode = super.removeAt(index);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from([removedNode])));
    return removedNode as IndexedListenableNode;
  }

  /// Remove all the [Iterable] nodes from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void removeAll(Iterable<IndexedNode> iterable) {
    for (final value in iterable) {
      final index = children.indexWhere((node) => node.key == value.key);
      if (index < 0) throw NodeNotFoundException(key: key);
      children.removeAt(index);
    }

    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from(iterable)));
  }

  /// Remove all the child nodes from the [children] that match the criterion
  /// in the given [test]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void removeWhere(bool test(IndexedNode element)) {
    final allChildren = childrenAsList.toSet();
    super.removeWhere(test);
    _notifyListeners();
    final remainingChildren = childrenAsList.toSet();
    allChildren.removeAll(remainingChildren);

    if (allChildren.isNotEmpty) {
      _notifyNodesRemoved(NodeRemoveEvent(List.from(allChildren)));
    }
  }

  /// Clear all the child nodes from [children]. The [children] will be empty
  /// after this operation.
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void clear() {
    final clearedNodes = childrenAsList;
    super.clear();
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from(clearedNodes)));
  }

  /// * Utility method to get a child node at the [path].
  /// Get any item at [path] from the [root]
  /// The keys of the items to be traversed should be provided in the [path]
  ///
  /// For example in a TreeView like this
  ///
  /// ```dart
  /// Node get mockNode1 => Node.root()
  ///   ..addAll([
  ///     Node(key: "0A")..add(Node(key: "0A1A")),
  ///     Node(key: "0B"),
  ///     Node(key: "0C")
  ///       ..addAll([
  ///         Node(key: "0C1A"),
  ///         Node(key: "0C1B"),
  ///         Node(key: "0C1C")
  ///           ..addAll([
  ///             Node(key: "0C1C2A")
  ///               ..addAll([
  ///                 Node(key: "0C1C2A3A"),
  ///                 Node(key: "0C1C2A3B"),
  ///                 Node(key: "0C1C2A3C"),
  ///               ]),
  ///           ]),
  ///       ]),
  ///   ]);
  ///```
  ///
  /// In order to access the Node with key "0C1C", the path would be
  ///   0C.0C1C
  ///
  /// Note: The root node [ROOT_KEY] does not need to be in the path
  IndexedListenableNode elementAt(String path) =>
      super.elementAt(path) as IndexedListenableNode;

  IndexedListenableNode at(int index) =>
      super.at(index) as IndexedListenableNode;

  IndexedListenableNode operator [](String path) => elementAt(path);

  void dispose() {
    _addedNodes.close();
    _removedNodes.close();
    _insertedNodes.close();
    super.dispose();
  }

  void _notifyListeners() {
    notifyListeners();
    if (!isRoot) parent!._notifyListeners();
  }

  void _notifyNodesAdded(NodeAddEvent<INode> event) {
    if (isRoot) {
      _addedNodes.emit(event);
    } else {
      root._notifyNodesAdded(event);
    }
  }

  void _notifyNodesInserted(NodeInsertEvent<INode> event) {
    if (isRoot) {
      _insertedNodes.emit(event);
    } else {
      root._notifyNodesInserted(event);
    }
  }

  void _notifyNodesRemoved(NodeRemoveEvent<INode> event) {
    if (isRoot) {
      _removedNodes.emit(event);
    } else {
      root._notifyNodesRemoved(event);
    }
  }
}
