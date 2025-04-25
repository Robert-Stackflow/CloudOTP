part of '../custom_dropdown.dart';

// overlay icon
const _defaultOverlayIconDown = Icon(
  Icons.keyboard_arrow_down_rounded,
  size: 20,
);

class _DropDownField<T extends DropdownMixin> extends StatefulWidget {
  final VoidCallback onTap;
  final SingleSelectController<T?> selectedItemNotifier;
  final String hintText;
  final Color? fillColor;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final TextStyle? showSelectedStyle, hintStyle;
  final Widget? prefixIcon, suffixIcon;
  final List<BoxShadow>? shadow;
  final EdgeInsets? headerPadding;
  final int maxLines;
  final _HeaderBuilder<T>? headerBuilder;
  final _SelectedBuilder<T>? showSelectedBuilder;
  final _SelectedListBuilder<T>? multiSelectShowSelectedBuilder;
  final _HintBuilder? hintBuilder;
  final _DropdownType dropdownType;
  final bool enabled;
  final MultiSelectController<T> selectedItemsNotifier;

  const _DropDownField({
    super.key,
    required this.onTap,
    required this.selectedItemNotifier,
    required this.maxLines,
    required this.dropdownType,
    required this.selectedItemsNotifier,
    this.hintText = 'Select value',
    this.fillColor,
    this.border,
    this.borderRadius,
    this.hintStyle,
    this.showSelectedStyle,
    this.headerBuilder,
    this.showSelectedBuilder,
    this.shadow,
    this.multiSelectShowSelectedBuilder,
    this.hintBuilder,
    this.prefixIcon,
    this.suffixIcon,
    this.headerPadding,
    this.enabled = true,
  });

  @override
  State<_DropDownField<T>> createState() => _DropDownFieldState<T>();
}

class _DropDownFieldState<T extends DropdownMixin>
    extends State<_DropDownField<T>> {
  T? selectedItem;
  late List<T> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItemNotifier.value;
    selectedItems = widget.selectedItemsNotifier.value;
  }

  Widget hintBuilder(BuildContext context) {
    return widget.hintBuilder != null
        ? widget.hintBuilder!(context, widget.hintText, widget.enabled)
        : defaultHintBuilder(widget.hintText, widget.enabled);
  }

  Widget defaultHintBuilder(String hint, bool enabled) {
    return Text(
      hint,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.hintStyle ??
          const TextStyle(
            fontSize: 16,
            color: Color(0xFFA7A7A7),
          ),
    );
  }

  Widget showSelectedBuilder(BuildContext context) {
    return widget.showSelectedBuilder != null
        ? widget.showSelectedBuilder!(
            context, selectedItem as T, widget.enabled)
        : defaultShowSelectedBuilder(oneItem: selectedItem);
  }

  Widget defaultShowSelectedBuilder({T? oneItem, List<T>? itemList}) {
    return Container(
      // margin: const EdgeInsets.only(left: 16),
      // alignment: Alignment.center,
      child: Text(
        itemList != null
            ? itemList.join(', ')
            : (oneItem as DropdownMixin).display,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style: widget.showSelectedStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.enabled ? null : Colors.black.withValues(alpha: .5),
            ),
      ),
    );
  }

  Widget multiSelectShowSelectedBuilder(BuildContext context) {
    return widget.multiSelectShowSelectedBuilder != null
        ? widget.multiSelectShowSelectedBuilder!(
            context, selectedItems, widget.enabled)
        : defaultMultiSelectShowSelectedBuilder(itemList: selectedItems);
  }

  Widget defaultMultiSelectShowSelectedBuilder(
      {T? oneItem, List<T>? itemList}) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: itemList!
          .map((item) => _buildSelectedItem((item as DropdownMixin).display))
          .toList(),
    );
  }

  Widget _buildSelectedItem(String item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: Text(
        item,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style: widget.showSelectedStyle?.apply(fontSizeDelta: -1) ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.enabled ? null : Colors.black.withValues(alpha: .5),
            ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _DropDownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    switch (widget.dropdownType) {
      case _DropdownType.singleSelect:
        selectedItem = widget.selectedItemNotifier.value;
      case _DropdownType.multipleSelect:
        selectedItems = widget.selectedItemsNotifier.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: widget.headerPadding ?? _defaultHeaderPadding,
        decoration: BoxDecoration(
          color: widget.fillColor ??
              (widget.enabled
                  ? CustomDropdownDecoration._defaultFillColor
                  : CustomDropdownDecoration._defaultFillColor
                      .withValues(alpha: .5)),
          border: widget.border,
          borderRadius: widget.borderRadius ?? _defaultBorderRadius,
          boxShadow: widget.shadow,
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              widget.prefixIcon!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: switch (widget.dropdownType) {
                _DropdownType.singleSelect => selectedItem != null
                    ? showSelectedBuilder(context)
                    : hintBuilder(context),
                _DropdownType.multipleSelect => selectedItems.isNotEmpty
                    ? multiSelectShowSelectedBuilder(context)
                    : hintBuilder(context),
              },
            ),
            const SizedBox(width: 12),
            widget.suffixIcon ??
                (widget.enabled
                    ? _defaultOverlayIconDown
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
