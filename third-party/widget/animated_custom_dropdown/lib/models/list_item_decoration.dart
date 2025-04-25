part of '../custom_dropdown.dart';

class ListItemDecoration {
  /// Splash color for [CustomDropdown] list item area.
  ///
  /// Default to [Colors.transparent].
  final Color? splashColor;

  /// Highlight color for [CustomDropdown] list item area.
  ///
  /// Default to Color(0xFFEEEEEE).
  final Color? highlightColor;

  /// Selected color for [CustomDropdown] list item area.
  ///
  /// Default to Color(0xFFF5F5F5).
  final Color? selectedColor;

  /// Selected icon color for [CustomDropdown] list item area.
  /// Useless if [listItemBuilder] provided.
  final Color? selectedIconColor;

  /// Selected icon border for [CustomDropdown] list item area.
  /// Useless if [listItemBuilder] provided.
  final BorderSide? selectedIconBorder;

  /// Selected icon shape for [CustomDropdown] list item area.
  /// Useless if [listItemBuilder] provided.
  final OutlinedBorder? selectedIconShape;

  const ListItemDecoration({
    this.splashColor,
    this.highlightColor,
    this.selectedColor,
    this.selectedIconColor,
    this.selectedIconBorder,
    this.selectedIconShape,
  });

  static const _defaultSplashColor = Colors.transparent;
  static const _defaultHighlightColor = Color(0xFFEEEEEE);
  static const _defaultSelectedColor = Color(0xFFF5F5F5);
}
