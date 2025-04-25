import 'dart:async';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:animated_tree_view/helpers/event_stream_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'base/i_listenable_node.dart';

class ListenableNode extends Node
    with ChangeNotifier
    implements IListenableNode {
  /// A listenable implementation the [Node].
  /// The mutations to the [Node] can be listened to using the [ValueListenable]
  /// interface or the [addedNodes] and [removedNodes] streams.
  ///
  /// The [ListenableNode] can also be used with a [ValueListenableBuilder]
  /// for updating the UI whenever the [Node] is mutated.
  ///
  /// Default constructor that takes an optional [key] and a parent.
  /// Make sure that the provided [key] is unique to among the siblings of the node.
  /// If a [key] is not provided, then a [UniqueKey] will automatically be
  /// assigned to the [Node].
  ListenableNode({String? key, Node? parent}) : super(key: key, parent: parent);

  /// Alternate factory constructor for [ListenableNode] that should be used for
  /// the [root] nodes.
  factory ListenableNode.root() => ListenableNode(key: INode.ROOT_KEY);

  /// This is the parent [ListenableNode]. Only the root node has a null [parent]
  ListenableNode? parent;

  /// Getter to get the [value] of the [ValueListenable]. It returns the [root]
  ListenableNode get value => root;

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  ListenableNode get root => super.root as ListenableNode;

  /// This returns the [children] as an iterable list.
  List<ListenableNode> get childrenAsList =>
      List<ListenableNode>.from(super.childrenAsList);

  final EventStreamController<NodeAddEvent<INode>> _addedNodes =
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

  /// The insertNodes stream is not allowed for the ListenableNode.
  /// The index based operations like 'insert' are not implemented in ListenableNode
  Stream<
      NodeInsertEvent<
          INode>> get insertedNodes => throw ActionNotAllowedException(
      this,
      "The insertNodes stream is not allowed"
      "for the ListenableNode. The index based operations like 'insert' are "
      "not implemented in ListenableNode");

  /// Add a [value] node to the [children]
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  void add(Node value) {
    super.add(value);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List.from([value])));
  }

  /// Add a collection of [Iterable] nodes to [this] node
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  void addAll(Iterable<Node> iterable) {
    super.addAll(iterable);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List.from(iterable)));
  }

  /// Remove a child [value] node from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void remove(Node value) {
    super.remove(value);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from([value])));
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

  /// Remove all the [Iterable] nodes from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void removeAll(Iterable<Node> iterable) {
    super.removeAll(iterable);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List.from(iterable)));
  }

  /// Remove all the child nodes from the [children] that match the criterion in
  /// the provided [test]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  void removeWhere(bool test(Node element)) {
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
  ListenableNode elementAt(String path) =>
      super.elementAt(path) as ListenableNode;

  /// Overloaded operator for [elementAt]
  ListenableNode operator [](String path) => elementAt(path);

  /// Disposer to clear the listeners and [StreamSubscription]s
  void dispose() {
    _addedNodes.close();
    _removedNodes.close();
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

  void _notifyNodesRemoved(NodeRemoveEvent<INode> event) {
    if (isRoot) {
      _removedNodes.emit(event);
    } else {
      root._notifyNodesRemoved(event);
    }
  }
}
