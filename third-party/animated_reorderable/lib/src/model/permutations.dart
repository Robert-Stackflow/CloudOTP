import 'package:flutter/widgets.dart';

/// A class representing permutations of items in a list.
///
/// This class is used to track and apply permutations of items, typically
/// in the context of reordering elements within a list or grid.
///
/// Permutations are created by specifying the original and destination indices
/// of an item, and they can be applied to a list to reflect the new order.
///
/// Example:
/// ```dart
/// // Creating a Permutations instance
/// final permutations = Permutations();
///
/// // Adding a permutation to reorder an item from index 2 to index 5
/// permutations.addPermutation(
///   itemKey: myItemKey,
///   srcIndex: 2,
///   destIndex: 5,
/// );
///
/// // Applying the permutations to a list
/// final myList = ['A', 'B', 'C', 'D', 'E'];
/// permutations.apply(myList);
/// ```
///
/// In this example, the `myList` will be reordered based on the specified permutations.
///
/// The `Permutations` class keeps track of the mappings between original and new indices.
class Permutations {
  final _permutations = <_Permuration>[];
  final _indexByItemKey = <Key, int>{};
  final _itemKeyByIndex = <int, Key>{};

  /// Adds a permutation to the list.
  ///
  /// The permutation specifies the original and destination indices of an item
  /// to be reordered within the list.
  ///
  /// Parameters:
  /// - `itemKey`: The unique key of the item being reordered.
  /// - `srcIndex`: The original index of the item.
  /// - `destIndex`: The new index to which the item will be moved.
  void addPermutation({
    required Key itemKey,
    required int srcIndex,
    required int destIndex,
  }) =>
      _add(_Permuration(
        itemKey: itemKey,
        from: srcIndex,
        to: destIndex,
      ));

  void _add(_Permuration p) {
    final curIndexOfElement = indexOf(p.itemKey);
    _itemKeyByIndex.remove(curIndexOfElement);

    final unorderedElementId = itemKeyAt(p.to);
    _indexByItemKey.remove(unorderedElementId);

    _indexByItemKey[p.itemKey] = p.to;
    _itemKeyByIndex[p.to] = p.itemKey;

    _permutations.add(p);
  }

  /// Returns the index of an item based on its key.
  ///
  /// Returns `null` if the item key is not found in the permutations.
  int? indexOf(Key itemKey) => _indexByItemKey[itemKey];

  /// Returns the item key at a specified index.
  ///
  /// Returns `null` if the index is not found in the permutations.
  Key? itemKeyAt(int index) => _itemKeyByIndex[index];

  /// Applies the permutations to a provided list.
  ///
  /// This method rearranges the elements in the list based on the recorded permutations.
  /// The original order is modified to reflect the new order specified by the permutations.
  ///
  /// Parameters:
  /// - `list`: The list to which the permutations should be applied.
  void apply<T>(List<T> list) {
    final unordered = <int, T>{};
    final emptySlots = <int>{};
    for (final p in _permutations) {
      if (!emptySlots.contains(p.to)) {
        unordered[p.to] = list[p.to];
      }
      if (unordered.containsKey(p.from)) {
        list[p.to] = unordered.remove(p.from) as T;
      } else {
        list[p.to] = list[p.from];
        emptySlots.add(p.from);
      }
      emptySlots.remove(p.to);
    }
  }

  /// Returns `true` if there are no recorded permutations, indicating an empty state.
  bool get isEmpty => _permutations.isEmpty;
}

class _Permuration {
  final Key itemKey;
  final int from;
  final int to;

  _Permuration({
    required this.itemKey,
    required this.from,
    required this.to,
  });
}
