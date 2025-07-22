/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

enum SelectionItemLeadingTailingType { none, addSelection, icon, text, widget }

class SelectionItemLeadingTailingConfig {
  final IconData? icon;
  final String? text;
  final Widget? widget;
  final SelectionItemLeadingTailingType type;
  final bool show;
  final Function()? onTap;

  SelectionItemLeadingTailingConfig({
    this.icon,
    this.text,
    this.widget,
    this.show = true,
    this.type = SelectionItemLeadingTailingType.none,
    this.onTap,
  });
}

class SelectionItemStyle {
  final Color? backgroundColor;
  final Color? fieldBackgroundColor;
  final bool topRadius;
  final bool bottomRadius;
  final bool showBorder;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final double radius;
  final bool isDense;
  final double horizontalMargin;
  final double topMargin;
  final double bottomMargin;

  SelectionItemStyle({
    this.backgroundColor,
    this.fieldBackgroundColor,
    this.topRadius = true,
    this.bottomRadius = true,
    this.radius = 8,
    this.showBorder = true,
    this.maxLength,
    this.horizontalMargin = 0,
    this.topMargin = 5,
    this.bottomMargin = 5,
    this.maxLines,
    this.minLines,
    this.isDense = true,
  });
}

class SelectionItem<T extends DropdownMixin> extends StatefulWidget {
  const SelectionItem({
    super.key,
    this.title,
    this.description,
    this.hint,
    this.focusNode,
    this.leadingConfig,
    this.tailingConfig,
    required this.items,
    required this.initItem,
    this.searchHint,
    this.noResultHint,
    this.noItemHint,
    this.onChanged,
    this.enabled = true,
    this.style,
  })  : initItems = const [],
        onListChanged = null,
        isMultiSelect = false;

  const SelectionItem.multiSelect({
    super.key,
    this.title,
    this.description,
    this.hint,
    this.focusNode,
    this.leadingConfig,
    this.tailingConfig,
    required this.items,
    required this.initItems,
    this.searchHint,
    this.noResultHint,
    this.noItemHint,
    this.onListChanged,
    this.enabled = true,
    this.style,
  })  : initItem = null,
        onChanged = null,
        isMultiSelect = true;

  final String? hint;
  final FocusNode? focusNode;
  final String? title;
  final String? description;

  final List<T> items;
  final List<T> initItems;
  final T? initItem;
  final String? searchHint;
  final String? noItemHint;
  final String? noResultHint;
  final Function(List<DropdownMixin>)? onListChanged;
  final Function(DropdownMixin?)? onChanged;
  final bool isMultiSelect;
  final bool enabled;

  final SelectionItemStyle? style;

  final SelectionItemLeadingTailingConfig? leadingConfig;
  final SelectionItemLeadingTailingConfig? tailingConfig;

  @override
  State<StatefulWidget> createState() => SelectionItemState();
}

class SelectionItemState<T extends DropdownMixin>
    extends State<SelectionItem<T>> {
  String? get hint => widget.hint;

  FocusNode? get focusNode => widget.focusNode;

  late SelectionItemLeadingTailingConfig leadingConfig;

  late SelectionItemLeadingTailingConfig tailingConfig;

  late SelectionItemStyle style;

  @override
  void initState() {
    super.initState();
    leadingConfig = SelectionItemLeadingTailingConfig(
      type: widget.leadingConfig?.type ?? SelectionItemLeadingTailingType.none,
      show: widget.leadingConfig?.show ?? true,
      icon: widget.leadingConfig?.icon,
      text: widget.leadingConfig?.text,
      widget: widget.leadingConfig?.widget,
      onTap: widget.leadingConfig?.onTap,
    );
    tailingConfig = SelectionItemLeadingTailingConfig(
      type: widget.tailingConfig?.type ?? SelectionItemLeadingTailingType.none,
      show: widget.tailingConfig?.show ?? true,
      icon: widget.tailingConfig?.icon,
      text: widget.tailingConfig?.text,
      widget: widget.tailingConfig?.widget,
      onTap: widget.tailingConfig?.onTap,
    );
    style =
        widget.style ?? SelectionItemStyle(backgroundColor: Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    Widget? leading = getLeadingTailingByConfig(leadingConfig);
    Widget? tailing = getLeadingTailingByConfig(tailingConfig);
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return Container(
      margin: EdgeInsets.only(
        left: style.horizontalMargin,
        right: style.horizontalMargin,
        top: style.topMargin,
        bottom: style.bottomMargin,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor ?? Colors.transparent,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.vertical(
          top: style.topRadius ? const Radius.circular(10) : Radius.zero,
          bottom: style.bottomRadius ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title.notNullOrEmpty) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: Text(
                widget.title!,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
          if (widget.description.notNullOrEmpty) ...[
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: Text(
                widget.description!,
                style: textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: widget.isMultiSelect
                      ? buildMultiSelectionItem()
                      : buildSelectionItem(),
                ),
              ),
              if (tailing != null) ...[
                const SizedBox(width: 12),
                tailing,
              ],
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSelectionItem() {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return CustomDropdown<T>.search(
      hintText: hint,
      noItemText: widget.noItemHint,
      searchHintText: widget.searchHint,
      noResultFoundText: widget.noResultHint,
      items: widget.items,
      onChanged: widget.onChanged,
      initialItem: widget.initItem,
      enabled: widget.enabled,
      overlayController: OverlayPortalController(),
      closedHeaderPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      disabledDecoration: CustomDropdownDisabledDecoration(
        showSelectStyle: textTheme.bodyMedium?.apply(color: Colors.grey),
        fillColor: ChewieTheme.canvasColor.withOpacity(0.5),
      ),
      decoration: CustomDropdownDecoration(
        overlayScrollbarThemeData: Theme.of(context).scrollbarTheme,
        hintStyle:
            textTheme.bodyMedium?.apply(color: textTheme.bodySmall?.color),
        showSelectStyle: textTheme.bodyMedium,
        expandedShadow: ChewieTheme.defaultBoxShadow,
        expandedBorder: ChewieTheme.border,
        expandedBorderRadius: ChewieDimens.borderRadius8,
        closedBorder: ChewieTheme.border,
        closedBorderRadius: ChewieDimens.borderRadius8,
        listItemDecoration: ListItemDecoration(
          splashColor: Theme.of(context).splashColor,
          highlightColor: Theme.of(context).highlightColor,
          selectedColor: Theme.of(context).hoverColor,
          selectedIconColor: ChewieTheme.successColor,
        ),
        searchFieldDecoration: SearchFieldDecoration(
          hintStyle:
              textTheme.bodyMedium?.apply(color: textTheme.bodySmall?.color),
          borderColor: ChewieTheme.borderColor,
        ),
        closedFillColor: ChewieTheme.canvasColor,
        listItemStyle: textTheme.bodyMedium,
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
    );
  }

  Widget buildMultiSelectionItem() {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    return CustomDropdown<T>.multiSelectSearch(
      hintText: hint,
      noItemText: widget.noItemHint,
      searchHintText: widget.searchHint,
      noResultFoundText: widget.noResultHint,
      enabled: widget.enabled,
      items: widget.items,
      onListChanged: widget.onListChanged,
      initialItems: widget.initItems,
      overlayController: OverlayPortalController(),
      disabledDecoration: CustomDropdownDisabledDecoration(
        showSelectStyle: textTheme.bodyMedium?.apply(color: Colors.grey),
        fillColor: ChewieTheme.canvasColor.withOpacity(0.5),
      ),
      closedHeaderPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: CustomDropdownDecoration(
        overlayScrollbarThemeData: Theme.of(context).scrollbarTheme,
        hintStyle:
            textTheme.bodyMedium?.apply(color: textTheme.bodySmall?.color),
        showSelectStyle: textTheme.bodyMedium,
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
        searchFieldDecoration: SearchFieldDecoration(
          hintStyle:
              textTheme.bodyMedium?.apply(color: textTheme.bodySmall?.color),
          borderColor: ChewieTheme.borderColor,
        ),
        closedFillColor: ChewieTheme.canvasColor,
        listItemStyle: textTheme.bodyMedium,
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
    );
  }

  Widget? getLeadingTailingByConfig(SelectionItemLeadingTailingConfig config) {
    Widget? res;
    switch (config.type) {
      case SelectionItemLeadingTailingType.none:
        res = null;
        break;
      case SelectionItemLeadingTailingType.addSelection:
        res = RoundIconTextButton(
          background: ChewieTheme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: Icon(
            LucideIcons.plus,
            color: ChewieTheme.iconColor,
            size: 20,
          ),
          onPressed: config.onTap,
        );
        break;
      case SelectionItemLeadingTailingType.icon:
        res = Icon(config.icon!, color: ChewieTheme.iconColor);
        break;
      case SelectionItemLeadingTailingType.text:
        res = RoundIconTextButton(
          background: ChewieTheme.canvasColor,
          border: ChewieTheme.borderWithWidth(1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          text: config.text,
          textStyle: ChewieTheme.bodySmall,
          onPressed: config.onTap,
        );
        break;
      case SelectionItemLeadingTailingType.widget:
        res = config.widget;
        break;
    }
    return res;
  }
}
