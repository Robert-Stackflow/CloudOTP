import 'package:animated_tree_view/animated_tree_view.dart';

sealed class TreeDiffNodeChange {
  const TreeDiffNodeChange();
}

class TreeDiffNodeAdd extends TreeDiffNodeChange {
  final INode data;

  const TreeDiffNodeAdd(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeDiffNodeAdd &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class TreeDiffNodeInsert extends TreeDiffNodeChange {
  final int position;
  final INode data;

  const TreeDiffNodeInsert({required this.position, required this.data});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeDiffNodeInsert &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          data == other.data;

  @override
  int get hashCode => position.hashCode ^ data.hashCode;
}

class TreeDiffNodeRemove extends TreeDiffNodeChange {
  final int? position;
  final INode data;

  const TreeDiffNodeRemove({this.position, required this.data});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeDiffNodeRemove &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          data == other.data;

  @override
  int get hashCode => position.hashCode ^ data.hashCode;
}

class TreeDiffNodeUpdate extends TreeDiffNodeChange {
  final INode data;

  const TreeDiffNodeUpdate(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeDiffNodeUpdate &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}
