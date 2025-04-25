import 'package:animated_tree_view/node/base/i_node.dart';

class DuplicateKeyException implements Exception {
  final String message;

  DuplicateKeyException(String key)
      : message = "Key: $key already exists. Please use unique strings as keys";

  @override
  String toString() {
    return 'DuplicateKeyException: $message}';
  }
}

class NodeNotFoundException implements Exception {
  final String message;

  NodeNotFoundException({required String key, String? parentKey})
      : message = "The node <$key> does not exist in the parent <$parentKey>";

  factory NodeNotFoundException.fromNode(INode node) =>
      NodeNotFoundException(key: node.key, parentKey: node.parent?.key);

  @override
  String toString() {
    return 'NodeNotFoundException: $message}';
  }
}

class ChildrenNotFoundException implements Exception {
  final String message;

  ChildrenNotFoundException(INode node)
      : message =
            "The node <${node.key}> of parent <${node.parent?.key}> does not have any children";

  @override
  String toString() {
    return 'ChildrenNotFoundException: $message}';
  }
}

class ActionNotAllowedException implements Exception {
  final String message;
  final INode node;

  ActionNotAllowedException(this.node, this.message);

  factory ActionNotAllowedException.listener(INode node) =>
      ActionNotAllowedException(
          node,
          "Listening to event stream is not allowed for non-root nodes. "
          "Event listeners can only be attached to the root nodes. "
          "Use the node.root getter to get the root node."
          "\n\nException occurred for node <${node.key}> with parent <${node.parent?.key}>");

  factory ActionNotAllowedException.deleteRoot(INode node) =>
      ActionNotAllowedException(
          node,
          "Deleting the root node is not allowed. Delete method should not be used on the root."
          "\nException occurred for node <${node.key}>");

  @override
  String toString() {
    return 'ActionNotAllowedException:\n$message}';
  }
}
