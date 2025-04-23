import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:animated_custom_dropdown/models/dropdown_mixin.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';

class DropdownWrapper<T extends DropdownMixin> extends StatelessWidget {
  final String hint;
  final List<T> items;
  final T? selected;
  final Function(T?) onChanged;
  final double width;

  const DropdownWrapper({
    super.key,
    required this.hint,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.width = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: CustomDropdown<T>(
        hintText: hint,
        initialItem: selected,
        items: items,
        excludeSelected: false,
        maxlines: 1,
        onChanged: onChanged,
        closedHeaderPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        noItemText: "暂无数据",
        decoration: CustomDropdownDecoration(
          overlayScrollbarThemeData: Theme.of(context).scrollbarTheme,
          showSelectStyle: ChewieTheme.titleSmall.apply(
            fontSizeDelta: -2,
            color: ChewieTheme.iconColor,
            fontWeightDelta: 2,
          ),
          noItemStyle: ChewieTheme.bodyMedium,
          hintStyle: ChewieTheme.bodySmall,
          expandedShadow: ChewieTheme.defaultBoxShadow,
          expandedBorder: ChewieTheme.borderWithWidth(1),
          expandedBorderRadius: ChewieDimens.borderRadius8,
          closedBorder: ChewieTheme.borderWithWidth(1),
          closedBorderRadius: ChewieDimens.borderRadius8,
          listItemDecoration: ListItemDecoration(
            selectedIconColor: ChewieTheme.successColor,
            splashColor: ChewieTheme.splashColor,
            highlightColor: ChewieTheme.highlightColor,
            selectedColor: ChewieTheme.hoverColor,
          ),
          closedFillColor: ChewieTheme.canvasColor,
          listItemStyle: ChewieTheme.bodyMedium,
          expandedFillColor: ChewieTheme.scaffoldBackgroundColor,
          closedSuffixIcon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: ChewieTheme.iconColor,
          ),
          expandedSuffixIcon: Icon(
            LucideIcons.chevronUp,
            size: 16,
            color: ChewieTheme.iconColor,
          ),
        ),
      ),
    );
  }
}
