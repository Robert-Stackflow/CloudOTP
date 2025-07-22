import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class InlineSelectionItem<T extends DropdownMixin>
    extends SearchableStatefulWidget {
  final List<T> selections;
  final T? selected;
  final List<T> selectedItems;
  final bool isMultiSelect;
  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;
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

  const InlineSelectionItem({
    super.key,
    required super.title,
    required this.selections,
    required this.selected,
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
    super.searchText,
    super.searchConfig,
  })  : isMultiSelect = false,
        selectedItems = const [],
        onListChanged = null;

  const InlineSelectionItem.multiSelect({
    super.key,
    required super.title,
    required this.selections,
    required this.selectedItems,
    this.onListChanged,
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
    super.searchText,
    super.searchConfig,
  })  : isMultiSelect = true,
        selected = null,
        onChanged = null;

  const InlineSelectionItem._internal({
    super.key,
    required this.selections,
    required super.title,
    required this.selected,
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
    this.isMultiSelect = false,
    this.selectedItems = const [],
    this.onListChanged,
    super.searchConfig,
  });

  @override
  InlineSelectionItemState<T> createState() => InlineSelectionItemState<T>();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return InlineSelectionItem<T>._internal(
      searchConfig: searchConfig ?? this.searchConfig,
      title: title,
      selections: selections,
      selected: selected,
      selectedItems: selectedItems,
      onChanged: onChanged,
      onListChanged: onListChanged,
      hint: hint,
      description: description,
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
    );
  }

  @override
  List<String> get sentences => [
        title,
        description,
        ...selections.map((e) => e.display),
      ];
}

class InlineSelectionItemState<T extends DropdownMixin>
    extends SearchableState<InlineSelectionItem<T>> {
  late final OverlayPortalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.overlayController ?? OverlayPortalController();
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    final vertical = widget.paddingVertical ?? 12;
    final horizontal = widget.paddingHorizontal ?? 6;

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
                vertical: vertical, horizontal: horizontal),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showLeading) Icon(widget.leading, size: 20),
                SizedBox(width: widget.showLeading ? 10 : 5),
                Expanded(child: _buildTitleDescription()),
                const SizedBox(width: 50),
                SizedBox(width: 180, child: _buildDropdownContainer()),
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

  Widget _buildDropdownContainer() {
    return widget.isMultiSelect
        ? _buildMultiSelectDropdown()
        : _buildDropdown();
  }

  Widget _buildDropdown() {
    return CustomDropdown<T>(
      hintText: widget.hint,
      initialItem: widget.selected,
      items: widget.selections,
      excludeSelected: false,
      onChanged: widget.onChanged,
      overlayController: _controller,
      closedHeaderPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: _dropdownDecoration(),
    );
  }

  Widget _buildMultiSelectDropdown() {
    return CustomDropdown<T>.multiSelect(
      hintText: widget.hint,
      initialItems: widget.selectedItems,
      items: widget.selections,
      onListChanged: widget.onListChanged,
      overlayController: _controller,
      closedHeaderPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _dropdownDecoration(),
    );
  }

  CustomDropdownDecoration _dropdownDecoration() {
    return CustomDropdownDecoration(
      overlayScrollbarThemeData: ChewieTheme.scrollbarTheme,
      showSelectStyle:
          ChewieTheme.bodyMedium.apply(fontSizeDelta: -1, fontWeightDelta: 2),
      noItemStyle: ChewieTheme.bodyMedium,
      hintStyle: ChewieTheme.bodySmall,
      expandedShadow: ChewieTheme.defaultBoxShadow,
      expandedBorder: ChewieTheme.border,
      expandedBorderRadius: ChewieDimens.borderRadius8,
      closedBorder: ChewieTheme.border,
      closedBorderRadius: ChewieDimens.borderRadius8,
      listItemDecoration: ListItemDecoration(
        splashColor: ChewieTheme.splashColor,
        highlightColor: ChewieTheme.highlightColor,
        selectedColor: ChewieTheme.hoverColor,
        selectedIconColor: ChewieTheme.successColor,
      ),
      closedFillColor: ChewieTheme.canvasColor,
      expandedFillColor: ChewieTheme.scaffoldBackgroundColor,
      listItemStyle: ChewieTheme.bodyMedium,
      closedSuffixIcon:
          Icon(LucideIcons.chevronDown, size: 16, color: ChewieTheme.iconColor),
      expandedSuffixIcon:
          Icon(LucideIcons.chevronUp, size: 16, color: ChewieTheme.iconColor),
    );
  }
}
