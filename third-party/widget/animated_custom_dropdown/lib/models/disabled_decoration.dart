part of '../custom_dropdown.dart';

class CustomDropdownDisabledDecoration {
  /// [CustomDropdown] field color (disabled state).
  ///
  /// Default to Color(0xFFF3F3F3).
  final Color? fillColor;

  /// [CustomDropdown] box shadow (disabled state).
  final List<BoxShadow>? shadow;

  /// Suffix icon for disabled state of [CustomDropdown].
  final Widget? suffixIcon;

  /// Prefix icon for disabled state of [CustomDropdown].
  final Widget? prefixIcon;

  /// Border for disabled state of [CustomDropdown].
  final BoxBorder? border;

  /// Border radius for disabled state of [CustomDropdown].
  final BorderRadius? borderRadius;

  /// The style to use for the [CustomDropdown] header hint (disabled state).
  final TextStyle? hintStyle;

  /// The style to use for the [CustomDropdown] header text (disabled state).
  final TextStyle? showSelectStyle;

  const CustomDropdownDisabledDecoration({
    this.fillColor,
    this.shadow,
    this.suffixIcon,
    this.prefixIcon,
    this.border,
    this.borderRadius,
    this.showSelectStyle,
    this.hintStyle,
  });
}
