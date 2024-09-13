/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Simple extension to generate [HidableController] from scroll controller instance directly.
extension HidableControllerExt on ScrollController {
  static final hidableControllers = <int, HidableController>{};

  /// Creates new [HidableController] or returns already created existing [HidableController]
  /// from [hidableControllers].
  ///
  /// Identifys each controller via passed [hashCode] property.
  HidableController hidable(
      int hashCode, HidableVisibility? visibility, double deltaFactor) {
    // If the same instance was created before, we should keep using it.
    if (hidableControllers.containsKey(hashCode)) {
      return hidableControllers[hashCode]!;
    }

    return hidableControllers[hashCode] = HidableController(
      scrollController: this,
      hideableVisibility: visibility,
      deltaFactor: deltaFactor,
    );
  }
}

/// Defines a function signature for determining the visibility of a scrollable element
/// that can be hidden or revealed based on scrolling behavior.
///
/// The `HidableVisibility` function takes four parameters:
/// - `position`: A [ScrollPosition] object representing the current scroll position.
/// - `currentVisibility`: A [double] representing the current visibility status, typically
///   a value between 0.0 (completely hidden) and 1.0 (completely visible).
///
/// The function should return a [double] value representing the updated visibility status
/// of the scrollable element, typically also in the range of 0.0 to 1.0.
///
/// Example usage:
/// ```dart
/// HidableVisibility myVisibilityFunction(ScrollPosition position, double currentVisibility) {
///   // Your visibility logic here.
///   // Return the updated visibility value.
/// }
/// ```
///
/// This typedef is often used in conjunction with a [HidableController] to define custom
/// visibility behavior for scrollable elements.
typedef HidableVisibility = double Function(
  ScrollPosition position,
  double currentVisibility,
);

/// A custom wrapper for scroll controller.
///
/// Implements the main listener mehtod for [ScrollController].
/// And the [sizeNotifier] for providing/updating the hideable status.
class HidableController {
  ScrollController scrollController;
  HidableVisibility? hideableVisibility;
  double deltaFactor;

  HidableController({
    required this.scrollController,
    this.hideableVisibility,
    required this.deltaFactor,
  }) {
    scrollController
        .addListener(() => updateVisibility(hideableVisibility, deltaFactor));
  }

  final visibilityNotifier = ValueNotifier<double>(1.0);

  void updateVisibility(HidableVisibility? visibility, double deltaFactor) {
    final position = scrollController.position;
    if (visibility != null) {
      visibilityNotifier.value = visibility(
        position,
        visibilityNotifier.value,
      );
      return;
    }
    if (position.userScrollDirection == ScrollDirection.reverse) {
      visibilityNotifier.value =
          (visibilityNotifier.value - deltaFactor).clamp(0, 1);
    } else if (position.userScrollDirection == ScrollDirection.forward) {
      visibilityNotifier.value =
          (visibilityNotifier.value + deltaFactor).clamp(0, 1);
    }
  }

  void close() => visibilityNotifier.dispose();
}
