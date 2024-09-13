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

import 'package:flutter/widgets.dart';

enum DragHandleVerticalAlignment {
  top,
  center,
  bottom,
}

class DragHandle extends StatelessWidget {
  /// Set the drag handle to be on the left side instead of the default right side
  final bool onLeft;

  /// Align the list drag handle to the top, center, or bottom
  final DragHandleVerticalAlignment verticalAlignment;

  /// Child widget to displaying the drag handle
  final Widget child;

  const DragHandle({
    super.key,
    required this.child,
    this.onLeft = false,
    this.verticalAlignment = DragHandleVerticalAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
