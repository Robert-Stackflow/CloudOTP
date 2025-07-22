import 'package:flutter/material.dart';

class RadioItem<T> extends StatelessWidget {
  const RadioItem({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.toggleable = false,
    this.activeColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.autofocus = false,
    this.contentPadding,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.visualDensity,
    this.focusNode,
    this.onFocusChange,
    this.enableFeedback,
    this.selectedColor,
  });

  final T value;

  final T? groupValue;

  final ValueChanged<T?>? onChanged;

  final bool toggleable;

  final Color? activeColor;

  final Widget? title;

  final Widget? subtitle;

  final Widget? secondary;

  final bool isThreeLine;

  final bool? dense;

  final bool selected;

  final bool autofocus;

  final EdgeInsetsGeometry? contentPadding;

  bool get checked => value == groupValue;

  final ShapeBorder? shape;

  final Color? tileColor;

  final Color? selectedTileColor;
  final Color? selectedColor;

  final VisualDensity? visualDensity;

  final FocusNode? focusNode;

  final ValueChanged<bool>? onFocusChange;

  final bool? enableFeedback;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        style: ListTileStyle.list,
        selectedColor: selectedColor,
        title: title,
        subtitle: subtitle,
        isThreeLine: isThreeLine,
        dense: dense,
        enabled: onChanged != null,
        shape: shape,
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: onChanged != null
            ? () {
                if (toggleable && checked) {
                  onChanged!(null);
                  return;
                }
                if (!checked) {
                  onChanged!(value);
                }
              }
            : null,
        selected: selected,
        autofocus: autofocus,
        contentPadding: contentPadding,
        visualDensity: visualDensity,
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        enableFeedback: enableFeedback,
      ),
    );
  }
}
