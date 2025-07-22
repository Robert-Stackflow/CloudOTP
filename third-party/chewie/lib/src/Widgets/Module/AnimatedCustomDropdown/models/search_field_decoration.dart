part of '../custom_dropdown.dart';

class SearchFieldDecoration {
  /// Fill color for [CustomDropdown] search field.
  ///
  /// Default to Color(0xFFFAFAFA).
  final Color? fillColor;

  /// Layout constraints for [CustomDropdown] search field.
  final BoxConstraints? constraints;

  /// Content spacing for [CustomDropdown] search field.
  final EdgeInsetsGeometry? contentPadding;

  /// Text Style (text being edited) for [CustomDropdown] search field.
  final TextStyle? textStyle;

  /// Hint text style for [CustomDropdown] search field.
  final TextStyle? hintStyle;

  /// Icon (before the text area) for [CustomDropdown] search field.
  final Widget? prefixIcon;

  /// Icon (after the text area) for [CustomDropdown] search field.
  /// "onClear" callback can be used to clear typed text appearing on search field.
  final Widget Function(VoidCallback onClear)? suffixIcon;

  /// Border for [CustomDropdown] search field.
  final InputBorder? border;

  /// Focused border for [CustomDropdown] search field.
  final InputBorder? focusedBorder;

  final Color? borderColor;

  final Color? focusedBorderColor;

  const SearchFieldDecoration({
    this.fillColor,
    this.constraints,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.border,
    this.focusedBorder,
    this.borderColor,
    this.focusedBorderColor,
  });
}
