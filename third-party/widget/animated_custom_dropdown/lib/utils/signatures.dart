part of '../custom_dropdown.dart';

typedef _ListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
  VoidCallback onItemSelect,
);
typedef _HeaderBuilder<T> = Widget Function(
  BuildContext context,
  T selectedItem,
  bool enabled,
);
typedef _SelectedBuilder<T> = Widget Function(
  BuildContext context,
  T selectedItem,
  bool enabled,
);
typedef _SelectedListBuilder<T> = Widget Function(
  BuildContext context,
  List<T> selectedItems,
  bool enabled,
);
typedef _HintBuilder = Widget Function(
  BuildContext context,
  String hint,
  bool enabled,
);
typedef _NoResultFoundBuilder = Widget Function(
  BuildContext context,
  String text,
);
