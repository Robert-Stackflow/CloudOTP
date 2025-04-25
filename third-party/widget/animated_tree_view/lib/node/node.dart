import 'package:animated_tree_view/helpers/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:uuid/v4.dart';

import 'base/i_node.dart';
import 'base/i_node_actions.dart';

class Node extends INode implements INodeActions {
  /// These are the children of the node.
  final Map<String, Node> children;

  /// This is the uniqueKey of the [Node]
  final String key;

  /// This is the parent [Node]. Only the root node has a null [parent]
  Node? parent;

  /// Any related data that needs to be accessible from the node can be added to
  /// [meta] without needing to extend or implement the [INode]
  Map<String, dynamic>? meta;

  /// The simple Node that use a [Map] to store the [children].
  ///
  /// Default constructor that takes an optional [key] and a parent.
  /// Make sure that the provided [key] is unique to among the siblings of the node.
  /// If a [key] is not provided, then a [UniqueKey] will automatically be
  /// assigned to the [Node].
  Node({String? key, this.parent})
      : assert(key == null || !key.contains(INode.PATH_SEPARATOR),
            "Key should not contain the PATH_SEPARATOR '${INode.PATH_SEPARATOR}'"),
        this.children = <String, Node>{},
        this.key = key ?? UuidV4().generate();

  /// Alternate factory constructor that should be used for the [root] nodes.
  factory Node.root() => Node(key: INode.ROOT_KEY);

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  Node get root => super.root as Node;

  /// This returns the [children] as an iterable list.
  List<Node> get childrenAsList => children.values.toList(growable: false);

  /// Add a [value] node to the [children]
  void add(Node value) {
    if (children.containsKey(value.key)) throw DuplicateKeyException(value.key);
    value.parent = this;
    children[value.key] = value;
  }

  /// Add a collection of [Iterable] nodes to [children]
  void addAll(Iterable<Node> iterable) {
    for (final node in iterable) {
      if (children.containsKey(node.key)) throw DuplicateKeyException(node.key);
      node.parent = this;
      children[node.key] = node;
    }
  }

  /// Clear all the child nodes from [children]. The [children] will be empty
  /// after this operation.
  void clear() {
    children.clear();
  }

  /// Remove a child [value] node from the [children]
  void remove(Node value) {
    children.remove(value.key);
  }

  /// Delete [this] node
  void delete() {
    if (isRoot) throw ActionNotAllowedException.deleteRoot(this);
    (parent as Node).remove(this);
  }

  /// Remove all the [Iterable] nodes from the [children]
  void removeAll(Iterable<Node> iterable) {
    for (final node in iterable) {
      children.remove(node.key);
    }
  }

  /// Remove all the child nodes from the [children] that match the criterion in
  /// the provided [test]
  void removeWhere(bool Function(Node element) test) {
    children.removeWhere((key, value) => test(value));
  }

  /// Overloaded operator for [elementAt]
  Node operator [](String path) => elementAt(path);

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
  Node elementAt(String path) {
    Node currentNode = this;
    for (final nodeKey in path.splitToNodes) {
      if (nodeKey == currentNode.key) {
        continue;
      } else {
        final nextNode = currentNode.children[nodeKey];
        if (nextNode == null)
          throw NodeNotFoundException(parentKey: path, key: nodeKey);
        currentNode = nextNode;
      }
    }
    return currentNode;
  }

  String toString() => 'Node{children: $children, key: $key, parent: $parent}';
}
