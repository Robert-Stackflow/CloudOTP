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
