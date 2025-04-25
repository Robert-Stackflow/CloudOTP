import "dart:collection";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter_resizable_container/flutter_resizable_container.dart";
import "package:flutter_resizable_container/src/extensions/num_ext.dart";
import "package:flutter_resizable_container/src/resizable_size.dart";

/// A controller to provide a programmatic interface to a [ResizableContainer].
class ResizableController with ChangeNotifier {
  double _availableSpace = -1;
  List<double> _pixels = [];
  List<ResizableSize> _sizes = const [];
  List<ResizableChild> _children = const [];
  bool _needsLayout = false;

  /// Whether or not the container needs to (re)layout its children.
  bool get needsLayout => _needsLayout;

  /// The physical size, in pixels, of each child.
  UnmodifiableListView<double> get pixels => UnmodifiableListView(_pixels);

  /// The [ResizableSize] of each child.
  UnmodifiableListView<ResizableSize> get sizes => UnmodifiableListView(_sizes);

  /// A list of ratios (proportion of total available space taken) for each child.
  UnmodifiableListView<double> get ratios {
    return UnmodifiableListView([
      for (final size in pixels) ...[
        size / _availableSpace,
      ],
    ]);
  }

  /// Update the [ResizableSize] used to control each child.
  ///
  /// The list must contain a value for every child.
  ///
  /// The total pixels must be less than or equal to the available space.
  ///
  /// The total ratio must be less than or equal to 1.0.
  void setSizes(List<ResizableSize> sizes) {
    if (sizes.length != _children.length) {
      throw ArgumentError('Must contain a value for every child');
    }

    final totalPixels =
        sizes.whereType<ResizableSizePixels>().map((size) => size.pixels).sum();

    if (totalPixels > _availableSpace) {
      throw ArgumentError(
        'Total pixels must be less than or equal to available space',
      );
    }

    final totalRatio =
        sizes.whereType<ResizableSizeRatio>().map((size) => size.ratio).sum();

    if (totalRatio > 1.0) {
      throw ArgumentError('Total ratio must be less than or equal to 1.0');
    }

    _sizes = sizes;
    print("updateeeeeee");
    _needsLayout = true;
    notifyListeners();
  }

  void _adjustChildSize({
    required int index,
    required double delta,
  }) {
    final adjustedDelta = delta < 0
        ? _getAdjustedReducingDelta(index: index, delta: delta)
        : _getAdjustedIncreasingDelta(index: index, delta: delta);

    _pixels[index] += adjustedDelta;
    _pixels[index + 1] -= adjustedDelta;
    notifyListeners();
  }

  void setChildren(List<ResizableChild> children) {
    _setChildren(children, notify: true);
  }

  void _initChildren(List<ResizableChild> children) {
    _setChildren(children, notify: false);
  }

  void _setChildren(List<ResizableChild> children, {required bool notify}) {
    _children = children;
    _sizes = children.map((child) => child.size).toList();
    _pixels = List.filled(children.length, 0);
    _needsLayout = true;

    if (notify) {
      notifyListeners();
    }
  }

  void _setRenderedSizes(List<double> pixels) {
    _pixels = pixels;
    _needsLayout = false;
    notifyListeners();
  }

  void _setAvailableSpace(double availableSpace) {
    if (_availableSpace == -1) {
      _needsLayout = true;
      _availableSpace = availableSpace;
      return;
    }

    if (availableSpace == _availableSpace) {
      return;
    }

    // Adjust the sizes of all children based on the new available space.
    //
    // Prioritize adjusting "expand" children first. Any remaining change in
    // available space (if the "expand" children have reached 0 or a size
    // constraint) should be uniformly distributed among the remaining
    // non-shrink children, taking into account their minimum & maximum size
    // constraints.
    final delta = _getDelta(availableSpace);

    if (delta == 0.0) {
      _availableSpace = availableSpace;
      return;
    }

    final distributed = _distributeDelta(
      delta: delta,
      sizes: _pixels,
    );

    for (var i = 0; i < sizes.length; i++) {
      _pixels[i] += distributed[i];
    }

    _availableSpace = availableSpace;
  }

  double _getDelta(double availableSpace) {
    var delta = availableSpace - _availableSpace;

    if (delta == 0.0) {
      return 0.0;
    }

    if (delta > 0) {
      final minimumNecessarySize = _getMinimumNecessarySize();

      if (minimumNecessarySize >= availableSpace) {
        return 0.0;
      }

      delta = min(delta, availableSpace - minimumNecessarySize);
    }

    return delta;
  }

  double _getMinimumNecessarySize() {
    final minimums = _sizes.map((size) => size.min ?? 0.0).toList();
    return minimums.sum();
  }

  List<double> _distributeDelta({
    required double delta,
    required List<double> sizes,
  }) {
    final indices = List.generate(_children.length, (i) => i);
    final changeableIndices = _getChangeableIndices(delta < 0 ? -1 : 1, sizes);

    if (changeableIndices.isEmpty) {
      return List.filled(sizes.length, 0.0);
    }

    final changePerItem = delta / changeableIndices.length;

    final maximums = indices.map((i) {
      if (changeableIndices.contains(i)) {
        return _getAllowableChange(delta: delta, index: i, sizes: sizes);
      }

      return 0.0;
    }).toList();

    final changes = indices.map((index) {
      if (!changeableIndices.contains(index)) {
        return 0.0;
      }

      final max = maximums[index];

      if (max.abs() < changePerItem.abs()) {
        return max;
      }

      return changePerItem;
    }).toList();

    final changesSum = changes.sum();
    final remainingChange = delta - changesSum;

    if (remainingChange.abs() > 0) {
      final adjustedSizes = indices.map(
        (index) => sizes[index] + changes[index],
      );

      final redistributed = _distributeDelta(
        delta: remainingChange,
        sizes: adjustedSizes.toList(),
      );

      for (var i = 0; i < changes.length; i++) {
        changes[i] += redistributed[i];
      }
    }

    return changes;
  }

  double _getAllowableChange({
    required double delta,
    required int index,
    required List<double> sizes,
  }) {
    final targetSize = sizes[index] + delta;

    if (delta < 0) {
      final minimumSize = _sizes[index].min ?? 0;

      if (targetSize <= minimumSize) {
        return minimumSize - sizes[index];
      }

      return delta;
    }

    final maximumSize = _sizes[index].max ?? double.infinity;

    if (targetSize >= maximumSize) {
      return maximumSize - sizes[index];
    }

    return delta;
  }

  List<int> _getChangeableIndices(int direction, List<double> sizes) {
    final indices = List.generate(_children.length, (i) => i);
    final List<int> changeableIndices = [];

    bool shouldAdd(index) {
      final minSize = _sizes[index].min ?? 0.0;
      final maxSize = _sizes[index].max ?? double.infinity;

      if (direction < 0 && sizes[index] > minSize) {
        return true;
      } else if (direction > 0 && sizes[index] < maxSize) {
        return true;
      } else {
        return false;
      }
    }

    for (final index in indices) {
      if (_children[index].size is! ResizableSizeExpand) {
        continue;
      }

      if (shouldAdd(index)) {
        changeableIndices.add(index);
      }
    }

    if (changeableIndices.isNotEmpty) {
      return changeableIndices;
    }

    for (final index in indices) {
      if (shouldAdd(index)) {
        changeableIndices.add(index);
      }
    }

    return changeableIndices;
  }

  double _getAdjustedReducingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = pixels[index];
    final minCurrentSize = _sizes[index].min ?? 0;
    final adjacentSize = pixels[index + 1];
    final maxAdjacentSize = _sizes[index + 1].max ?? double.infinity;
    final maxCurrentDelta = currentSize - minCurrentSize;
    final maxAdjacentDelta = maxAdjacentSize - adjacentSize;
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta.abs() > maxDelta) {
      delta = -maxDelta;
    }

    return delta;
  }

  double _getAdjustedIncreasingDelta({
    required int index,
    required double delta,
  }) {
    final currentSize = pixels[index];
    final maxCurrentSize = _sizes[index].max ?? double.infinity;
    final adjacentSize = pixels[index + 1];
    final minAdjacentSize = _sizes[index + 1].min ?? 0;
    final maxAvailableSpace = min(maxCurrentSize, _availableSpace);
    final maxCurrentDelta = maxAvailableSpace - currentSize;
    final maxAdjacentDelta = adjacentSize - minAdjacentSize;
    final maxDelta = min(maxCurrentDelta, maxAdjacentDelta);

    if (delta > maxDelta) {
      delta = maxDelta;
    }

    return delta;
  }
}

final class ResizableControllerManager {
  const ResizableControllerManager(this._controller);

  final ResizableController _controller;

  void adjustChildSize({required int index, required double delta}) {
    _controller._adjustChildSize(index: index, delta: delta);
  }

  void setRenderedSizes(List<double> sizes) {
    _controller._setRenderedSizes(sizes);
  }

  void setAvailableSpace(double availableSpace) {
    _controller._setAvailableSpace(availableSpace);
  }

  void setNeedsLayout() {
    _controller._needsLayout = true;
  }

  void initChildren(List<ResizableChild> children) {
    _controller._initChildren(children);
  }
}

abstract class ResizableControllerTestHelper {
  const ResizableControllerTestHelper._();

  static List<ResizableChild> getChildren(ResizableController controller) =>
      controller._children;
}
