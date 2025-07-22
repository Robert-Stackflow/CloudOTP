import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class InlineInputItemStyle {
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
  bool obscure;

  InlineInputItemStyle({
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
    this.obscure = false,
    this.isDense = true,
  });
}

class InlineInputItem extends SearchableStatefulWidget {
  final String text;
  final Function(String) onChanged;
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
  final bool ink;
  final List<TextInputFormatter> inputFormatters;
  final InlineInputItemStyle? style;
  final double fieldWidth;
  final int maxLines;

  const InlineInputItem({
    super.key,
    required this.text,
    required super.title,
    required this.onChanged,
    this.style,
    this.hint = "",
    this.inputFormatters = const [],
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
    this.ink = false,
    this.fieldWidth = 200,
    this.maxLines = 1,
    super.searchText,
    super.searchConfig,
  });

  @override
  InlineInputItemState createState() => InlineInputItemState();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return InlineInputItem(
      key: key,
      searchConfig: searchConfig ?? this.searchConfig,
      searchText: searchText ?? this.searchText,
      title: title,
      description: description,
      text: text,
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
      ink: ink,
    );
  }
}

class InlineInputItemState extends SearchableState<InlineInputItem> {
  late final TextEditingController controller;
  late final InlineInputItemStyle style;
  final FocusNode focusNode = FocusNode();

  bool readonly = false;
  bool enabled = true;

  @override
  void initState() {
    super.initState();
    style = widget.style ?? InlineInputItemStyle();
    controller = TextEditingController(text: widget.text)
      ..addListener(() => widget.onChanged(controller.text));
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    final theme = Theme.of(context);
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
                const SizedBox(width: 5),
                Expanded(child: _buildTitleDescription()),
                const SizedBox(width: 50),
                SizedBox(
                    width: widget.fieldWidth, child: _buildTextField(theme)),
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

  Widget _buildTextField(ThemeData theme) {
    final textTheme = theme.textTheme;

    return TextField(
      focusNode: focusNode,
      controller: controller,
      readOnly: readonly,
      enabled: enabled,
      obscureText: style.obscure,
      maxLines: widget.maxLines,
      minLines: 1,
      inputFormatters: widget.inputFormatters,
      scrollPhysics: const ClampingScrollPhysics(),
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.text,
      cursorColor: theme.primaryColor,
      cursorRadius: const Radius.circular(5),
      cursorOpacityAnimates: true,
      cursorHeight: 18,
      style: textTheme.bodyMedium?.copyWith(
        letterSpacing: 1.1,
        color: enabled ? null : textTheme.labelSmall?.color,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: style.fieldBackgroundColor ?? theme.canvasColor,
        contentPadding: const EdgeInsets.all(10),
        isDense: style.isDense,
        counterStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.apply(color: ChewieTheme.errorColor),
        border: style.showBorder
            ? OutlineInputBorder(
                borderSide: ChewieTheme.borderSide,
                borderRadius: BorderRadius.circular(style.radius),
              )
            : InputBorder.none,
        enabledBorder: _border(theme),
        focusedBorder: _border(theme, focused: true),
        disabledBorder: _border(theme),
        errorBorder: _border(theme, error: true),
        focusedErrorBorder: _border(theme, focused: true, error: true),
      ),
      contextMenuBuilder: (context, details) =>
          ItemBuilder.editTextContextMenuBuilder(context, details,
              context: context),
    );
  }

  OutlineInputBorder _border(
    ThemeData theme, {
    bool focused = false,
    bool error = false,
  }) {
    final color = error
        ? ChewieTheme.errorColor
        : focused
            ? theme.primaryColor
            : ChewieTheme.borderColor;
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: focused ? 0.8 : 0.5),
      borderRadius: BorderRadius.circular(style.radius),
    );
  }
}
