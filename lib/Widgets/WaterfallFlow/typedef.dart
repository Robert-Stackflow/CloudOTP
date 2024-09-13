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

import 'package:flutter/rendering.dart';

import 'extended_list_library.dart';

/// The builder to get layout type of last child
/// Notice: it should only for last child
typedef LastChildLayoutTypeBuilder = LastChildLayoutType Function(int index);

/// Return indexes of children which are disposed to collect
typedef CollectGarbage = void Function(List<int> garbages);

/// The builder to get indexes in viewport
/// if sliver is all out of viewport then return [-1,-1]
typedef ViewportBuilder = void Function(int firstIndex, int lastIndex);

/// Return paint extent of child
typedef PaintExtentOf = double Function(RenderBox? child);
