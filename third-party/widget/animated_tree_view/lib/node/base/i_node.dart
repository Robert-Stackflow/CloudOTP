/// Base class for Node that defines the required interfaces
abstract class INode {
  static const PATH_SEPARATOR = ".";
  static const ROOT_KEY = "/";

  /// This is the uniqueKey that every node needs to implement
  String get key;

  /// This is the parent [INode]. Only the root node has a null [parent]
  covariant INode? parent;

  /// These are the children of the node. It is a collection that can be
  /// any appropriate data-structure like [List] or [Map]
  Object? get children;

  /// This returns the [children] as an iterable list.
  /// Since [children] can be implemented using any suitable data-structure,
  /// therefore by having an iterable list as children ensures that the children
  /// can always be iterated when required.
  List<INode> get childrenAsList;

  /// Any related data that needs to be accessible from the node can be added to
  /// [meta] without needing to extend or implement the [INode]
  Map<String, dynamic>? meta;

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
  INode elementAt(String path);

  /// Overloaded operator for [elementAt]
  INode operator [](String path);

  /// Getter to check if the node is a root.
  /// Root is always the first node in a Tree. A Root-Node never has a parent.
  ///
  /// A Root-Node with no children, will also be a Leaf-Node.
  bool get isRoot => parent == null;

  /// Getter to check if the node is a Leaf.
  /// A Leaf-Node does have any children.
  ///
  /// A Root-Node with no children, will also be a Leaf-Node.
  bool get isLeaf => childrenAsList.isEmpty;

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  INode get root => isRoot ? this : this.parent!.root;

  /// Getter to get the level i.e. how many iterations it will take to get to the
  /// [root].
  /// ** Note: starting index is 0.
  int get level => parent == null ? 0 : parent!.level + 1;

  /// Getter to get the total number of [children]
  int get length => childrenAsList.length;

  /// Path of the node in the tree. It provides information about the node
  /// hierarchy by listing all the ancestors of the node.
  ///
  /// A typical path starts with a [ROOT_KEY] (/) and separates each ancestor key
  /// using [PATH_SEPARATOR] (.). For example for a node with [key] <#key123>
  /// and ancestors <#parent_1>, <#grand_parent_2>, the [path] will be
  ///     /.#grand_parent_2.#parent_1
  String get path =>
      parent == null ? key : "${parent!.path}${INode.PATH_SEPARATOR}$key";

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is INode && other.key == key;

  @override
  int get hashCode => 0;
}

extension StringUtils on String {
  List<String> get splitToNodes {
    final nodes = this.split(INode.PATH_SEPARATOR);
    if (nodes.isNotEmpty && nodes.first.isEmpty) {
      nodes.removeAt(0);
    }
    return nodes;
  }
}
