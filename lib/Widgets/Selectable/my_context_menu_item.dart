import 'package:flutter/cupertino.dart';

/// The type and callback for a context menu button.
///
/// See also:
///
///  * [AdaptiveTextSelectionToolbar], which can take a list of
///    ContextMenuButtonItems and create a platform-specific context menu with
///    the indicated buttons.
@immutable
class MyContextMenuItem {
  /// Creates a const instance of [MyContextMenuItem].
  const MyContextMenuItem({
    required this.onPressed,
    this.type = ContextMenuButtonType.custom,
    this.label,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback? onPressed;

  final ContextMenuButtonType type;

  /// The label to display on the button.
  ///
  /// If a [type] other than [ContextMenuButtonType.custom] is given
  /// and a label is not provided, then the default label for that type for the
  /// platform will be looked up.
  final String? label;

  /// Creates a new [MyContextMenuItem] with the provided parameters
  /// overridden.
  MyContextMenuItem copyWith({
    VoidCallback? onPressed,
    ContextMenuButtonType? type,
    String? label,
  }) {
    return MyContextMenuItem(
      onPressed: onPressed ?? this.onPressed,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MyContextMenuItem &&
        other.label == label &&
        other.onPressed == onPressed &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(label, onPressed, type);

  @override
  String toString() => 'ContextMenuButtonItem $type, $label';
}

extension TransformItem on ContextMenuButtonItem {
  MyContextMenuItem get toMyContextMenuItem => MyContextMenuItem(
        onPressed: onPressed,
        type: type,
        label: label,
      );
}

extension TransformItemReverse on MyContextMenuItem {
  ContextMenuButtonItem get toContextMenuButtonItem => ContextMenuButtonItem(
        onPressed: onPressed,
        type: type,
        label: label,
      );
}

extension TransformItems on List<ContextMenuButtonItem> {
  List<MyContextMenuItem> get toMyContextMenuItems =>
      map((item) => item.toMyContextMenuItem).toList();
}
