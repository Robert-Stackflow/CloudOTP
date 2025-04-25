import 'dart:collection';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:animated_tree_view/helpers/collection_utils.dart';
import 'package:animated_tree_view/tree_diff/tree_diff_change.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/widgets.dart';

List<TreeDiffNodeChange> calculateTreeDiff<T extends ITreeNode>(
    T oldTree, T newTree) {
  final updates = <TreeDiffNodeChange>[];

  final queue = ListQueue<(INode, INode)>();
  queue.add((oldTree, newTree));

  while (queue.isNotEmpty) {
    final (oldTree, newTree) = queue.removeFirst();

    if (oldTree.childrenAsList.isEmpty && newTree.childrenAsList.isEmpty)
      continue;

    final localUpdates = TreeDiff(
      oldTree: oldTree as ITreeNode,
      newTree: newTree as ITreeNode,
    );

    updates.addAll(localUpdates.allUpdates);
    queue.addAll(localUpdates.nodesUnchanged);
  }

  return updates;
}

class TreeDiff {
  final Iterable<TreeDiffNodeAdd> nodesAdded;
  final Iterable<TreeDiffNodeRemove> nodesRemoved;
  final Iterable<TreeDiffNodeInsert> nodesInserted;
  final Iterable<(INode, INode)> nodesUnchanged;
  final Iterable<TreeDiffNodeUpdate> nodesUpdated;

  final ITreeNode oldTree;
  final ITreeNode newTree;

  Iterable<TreeDiffNodeChange> get allUpdates => [
        ...nodesAdded,
        ...nodesInserted,
        ...nodesRemoved,
        ...nodesUpdated,
      ];

  const TreeDiff._({
    required this.oldTree,
    required this.newTree,
    this.nodesAdded = const [],
    this.nodesRemoved = const [],
    this.nodesInserted = const [],
    this.nodesUnchanged = const [],
    this.nodesUpdated = const [],
  });

  factory TreeDiff({required ITreeNode oldTree, required ITreeNode newTree}) {
    if (oldTree is TreeNode && newTree is TreeNode)
      return forTree(oldTree: oldTree, newTree: newTree);

    if (oldTree is IndexedTreeNode && newTree is IndexedTreeNode)
      return forIndexedTree(oldTree: oldTree, newTree: newTree);

    return TreeDiff._(oldTree: oldTree, newTree: newTree);
  }

  @visibleForTesting
  static TreeDiff forTree(
      {required TreeNode oldTree, required TreeNode newTree}) {
    final oldKeys = oldTree.children.keys.toSet();
    final newKeys = newTree.children.keys.toSet();

    final nodesAdded = newKeys.difference(oldKeys).map((nodeKey) {
      final node = newTree.children[nodeKey];
      return node == null ? null : TreeDiffNodeAdd(node);
    }).filterNotNull();

    final nodesRemoved = oldKeys.difference(newKeys).map((nodeKey) {
      final node = oldTree.children[nodeKey];
      return node == null ? null : TreeDiffNodeRemove(data: node);
    }).filterNotNull();

    final nodesUnchanged = <(TreeNode, TreeNode)>[];
    final nodesUpdated = <TreeDiffNodeUpdate>[];

    for (final nodeKey in oldKeys.intersection(newKeys)) {
      if ((oldTree.children[nodeKey]! as TreeNode).data !=
          (newTree.children[nodeKey]! as TreeNode).data) {
        nodesUpdated.add(TreeDiffNodeUpdate(newTree.children[nodeKey]!));
      }

      nodesUnchanged.add(
        (
          oldTree.children[nodeKey]! as TreeNode,
          newTree.children[nodeKey]! as TreeNode,
        ),
      );
    }

    return TreeDiff._(
      oldTree: oldTree,
      newTree: newTree,
      nodesAdded: nodesAdded,
      nodesRemoved: nodesRemoved,
      nodesUnchanged: nodesUnchanged,
      nodesUpdated: nodesUpdated,
    );
  }

  @visibleForTesting
  static TreeDiff forIndexedTree(
      {required IndexedTreeNode oldTree, required IndexedTreeNode newTree}) {
    final localUpdates = calculateListDiff<IndexedTreeNode>(
      List.from(oldTree.children),
      List.from(newTree.children),
      equalityChecker: (n1, n2) => n1.key == n2.key,
      detectMoves: false,
    ).getUpdatesWithData();

    final nodesInserted = <TreeDiffNodeInsert>[];
    final nodesRemoved = <TreeDiffNodeRemove>[];

    for (final update in localUpdates) {
      update.when(
        insert: (pos, data) {
          nodesInserted.add(TreeDiffNodeInsert(position: pos, data: data));
        },
        remove: (pos, data) {
          nodesRemoved.add(TreeDiffNodeRemove(data: data, position: pos));
        },
        change: (_, __, ___) {},
        move: (_, __, ___) {},
      );
    }

    final oldTreeMap = <String, IndexedNode>{
      for (final node in oldTree.children) node.key: node
    };

    final newTreeMap = <String, IndexedNode>{
      for (final node in newTree.children) node.key: node
    };

    final nodesUnchanged = <(IndexedTreeNode, IndexedTreeNode)>[];
    final nodesUpdated = <TreeDiffNodeUpdate>[];

    for (final nodeKey
        in oldTreeMap.keys.toSet().intersection(newTreeMap.keys.toSet())) {
      if ((oldTreeMap[nodeKey] as IndexedTreeNode).data !=
          (newTreeMap[nodeKey] as IndexedTreeNode).data) {
        nodesUpdated.add(TreeDiffNodeUpdate(newTreeMap[nodeKey]!));
      }

      nodesUnchanged.add(
        (
          oldTreeMap[nodeKey]! as IndexedTreeNode,
          newTreeMap[nodeKey]! as IndexedTreeNode,
        ),
      );
    }

    return TreeDiff._(
      oldTree: oldTree,
      newTree: newTree,
      nodesInserted: nodesInserted,
      nodesRemoved: nodesRemoved,
      nodesUnchanged: nodesUnchanged,
      nodesUpdated: nodesUpdated,
    );
  }
}
