import 'package:awesome_chewie/src/Widgets/Item/Tile/searchable_stateful_widget.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/ink_animation.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/number_field.dart';
import 'highlight_text.dart';

class InlineNumberInputItem extends SearchableStatefulWidget {
  final double value;
  final double maxValue;
  final double minValue;
  final double step;
  final int decimalPrecision;
  final Function(double)? onChanged;
  final String hint;
  final double radius;
  final bool roundTop;
  final bool roundBottom;
  final bool showLeading;
  final CrossAxisAlignment crossAxisAlignment;
  final IconData leading;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final double? paddingVertical;
  final double? paddingHorizontal;
  final double trailingLeftMargin;
  final bool dividerIndent;
  final OverlayPortalController? overlayController;
  final bool ink;

  const InlineNumberInputItem({
    super.key,
    required super.title,
    required this.value,
    this.maxValue = 100,
    this.minValue = 0,
    this.step = 1,
    this.decimalPrecision = 2,
    this.onChanged,
    this.hint = "",
    super.description = "",
    this.radius = 8,
    this.roundTop = false,
    this.roundBottom = false,
    this.showLeading = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.leading = LucideIcons.house,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
    this.paddingVertical,
    this.paddingHorizontal,
    this.trailingLeftMargin = 5,
    this.dividerIndent = true,
    this.overlayController,
    this.ink = false,
    super.searchConfig,
    super.searchText,
  });

  @override
  InlineNumberInputItemState createState() => InlineNumberInputItemState();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return InlineNumberInputItem(
      searchConfig: searchConfig ?? this.searchConfig,
      searchText: searchText ?? this.searchText,
      title: title,
      description: description,
      value: value,
      maxValue: maxValue,
      minValue: minValue,
      step: step,
      decimalPrecision: decimalPrecision,
      onChanged: onChanged,
      hint: hint,
      radius: radius,
      roundTop: roundTop,
      roundBottom: roundBottom,
      showLeading: showLeading,
      crossAxisAlignment: crossAxisAlignment,
      leading: leading,
      backgroundColor: backgroundColor,
      titleColor: titleColor,
      descriptionColor: descriptionColor,
      paddingVertical: paddingVertical,
      paddingHorizontal: paddingHorizontal,
      trailingLeftMargin: trailingLeftMargin,
      dividerIndent: dividerIndent,
      overlayController: overlayController,
      ink: ink,
    );
  }
}

class InlineNumberInputItemState
    extends SearchableState<InlineNumberInputItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    final paddingVertical = widget.paddingVertical ?? 12;
    final paddingHorizontal = widget.paddingHorizontal ?? 6;

    return InkAnimation(
      ink: widget.ink,
      borderRadius: BorderRadius.vertical(
        top: widget.roundTop ? Radius.circular(widget.radius) : Radius.zero,
        bottom:
            widget.roundBottom ? Radius.circular(widget.radius) : Radius.zero,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: paddingVertical,
              horizontal: paddingHorizontal,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showLeading) Icon(widget.leading, size: 20),
                SizedBox(width: widget.showLeading ? 10 : 5),
                Expanded(child: _buildTitleDescription()),
                const SizedBox(width: 50),
                SizedBox(width: 200, child: _buildNumberField()),
              ],
            ),
          ),
          // Container(
          //   height: 0,
          //   margin: const EdgeInsets.symmetric(horizontal: 10),
          //   decoration: BoxDecoration(
          //     border: widget.roundBottom ? null : ChewieTheme.bottomDivider,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTitleDescription() {
    final titleStyle = ChewieTheme.titleMedium.apply(color: widget.titleColor);
    final descStyle =
        ChewieTheme.bodySmall.apply(color: widget.descriptionColor);
    final highlightTitleStyle = titleStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    final highlightDescStyle = descStyle.copyWith(
      color: ChewieTheme.warningColor,
      fontWeight: FontWeight.bold,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: highlightText(
            widget.title,
            widget.searchText,
            titleStyle,
            highlightTitleStyle,
            searchConfig: widget.searchConfig,
          ),
        ),
        if (widget.description.isNotEmpty) const SizedBox(height: 3),
        if (widget.description.isNotEmpty)
          RichText(
            text: highlightText(
              widget.description,
              widget.searchText,
              descStyle,
              highlightDescStyle,
              searchConfig: widget.searchConfig,
            ),
          ),
      ],
    );
  }

  Widget _buildNumberField() {
    return NumberField(
      height: 28,
      initialValue: widget.value,
      maxValue: widget.maxValue,
      minValue: widget.minValue,
      step: widget.step,
      decimalPrecision: widget.decimalPrecision,
      onChanged: widget.onChanged,
    );
  }
}
