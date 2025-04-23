import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/Tile/searchable_stateful_widget.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Item/Animation/ink_animation.dart';
import 'highlight_text.dart';

class EntryItem extends SearchableStatefulWidget {
  final double radius;
  final bool roundTop;
  final bool roundBottom;
  final bool showLeading;
  final bool showTrailing;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final CrossAxisAlignment crossAxisAlignment;
  final IconData leading;
  final String tip;
  final Function()? onTap;
  final double? paddingVertical;
  final double? paddingHorizontal;
  final double trailingLeftMargin;
  final bool dividerPadding;
  final IconData trailing;
  final double tipWidth;
  final Widget? tipWidget;
  final bool ink;

  const EntryItem({
    super.key,
    this.radius = 8,
    this.roundTop = false,
    this.roundBottom = false,
    this.showLeading = false,
    this.showTrailing = true,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.leading = LucideIcons.house,
    this.tip = "",
    this.onTap,
    this.paddingVertical,
    this.paddingHorizontal,
    this.trailingLeftMargin = 5,
    this.dividerPadding = true,
    this.trailing = LucideIcons.chevronRight,
    this.tipWidth = 80,
    this.tipWidget,
    this.ink = true,
    required super.title,
    super.description,
    super.searchText,
    super.searchConfig,
  });

  @override
  List<String> get sentences => [title, description];

  @override
  State<EntryItem> createState() => EntryItemState();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return EntryItem(
      searchConfig: searchConfig ?? this.searchConfig,
      title: title,
      description: description,
      searchText: searchText ?? this.searchText,
      radius: radius,
      roundTop: roundTop,
      roundBottom: roundBottom,
      showLeading: showLeading,
      showTrailing: showTrailing,
      backgroundColor: backgroundColor,
      titleColor: titleColor,
      descriptionColor: descriptionColor,
      crossAxisAlignment: crossAxisAlignment,
      leading: leading,
      tip: tip,
      onTap: onTap,
      paddingVertical: paddingVertical,
      paddingHorizontal: paddingHorizontal,
      trailingLeftMargin: trailingLeftMargin,
      dividerPadding: dividerPadding,
      trailing: trailing,
      tipWidth: tipWidth,
      tipWidget: tipWidget,
    );
  }
}

class EntryItemState extends SearchableState<EntryItem> {
  double get _paddingVertical => widget.paddingVertical ?? 12;

  double get _paddingHorizontal => widget.paddingHorizontal ?? 6;

  BorderRadius get _borderRadius =>
      const BorderRadius.vertical(top: Radius.zero, bottom: Radius.zero);

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    return InkAnimation(
      color: Colors.transparent,
      ink: widget.ink,
      borderRadius: _borderRadius,
      // onTap: widget.onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: _paddingVertical,
              horizontal: _paddingHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildRowChildren(),
            ),
          ),
          // _buildBottomDivider(),
        ],
      ),
    );
  }

  List<Widget> _buildRowChildren() {
    return [
      if (widget.showLeading) Icon(widget.leading, size: 20),
      SizedBox(width: widget.showLeading ? 10 : 5),
      Expanded(child: _buildTextContent()),
      const SizedBox(width: 50),
      _buildTipWidget(),
      if (widget.tipWidget != null) _buildCustomTipWidget(),
      // if (widget.showTrailing) SizedBox(width: widget.trailingLeftMargin),
      // if (widget.showTrailing) _buildTrailingIcon(),
    ];
  }

  Widget _buildTextContent() {
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
      crossAxisAlignment: widget.crossAxisAlignment,
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

  Widget _buildTipWidget() {
    return widget.tip.isNotEmpty
        ? Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: RoundIconTextButton(
              onPressed: widget.onTap,
              text: widget.tip,
              textStyle: ChewieTheme.bodyMedium
                  .apply(fontSizeDelta: -1, fontWeightDelta: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              background: ChewieTheme.canvasColor,
              border: ChewieTheme.border,
            ),
          )
        : RoundIconTextButton(
            onPressed: widget.onTap,
            icon: Icon(
              widget.trailing,
              size: 16,
              color: ChewieTheme.bodyMedium.color,
            ),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            background: ChewieTheme.canvasColor,
            border: ChewieTheme.border,
          );
  }

  Widget _buildCustomTipWidget() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.description.isNotEmpty
            ? widget.tipWidth
            : widget.tipWidth + 40,
      ),
      child: widget.tipWidget!,
    );
  }

// Widget _buildBottomDivider() {
//   return Container(
//     height: 0,
//     margin: const EdgeInsets.symmetric(horizontal: 10),
//     decoration: BoxDecoration(
//       border: widget.roundBottom ? null : ChewieTheme.bottomDivider,
//     ),
//   );
// }
}

class SearchableCaptionItem extends SearchableStatefulWidget {
  final EdgeInsetsGeometry? padding;
  final bool showDivider;
  final List<SearchableStatefulWidget> children;
  final bool initiallyExpanded;

  const SearchableCaptionItem({
    super.key,
    required super.title,
    this.padding,
    this.showDivider = true,
    this.children = const [],
    this.initiallyExpanded = true,
    super.searchText,
    super.description,
    super.searchConfig,
  });

  @override
  SearchableCaptionItemState createState() => SearchableCaptionItemState();

  @override
  List<String> get sentences =>
      children.map((c) => c.sentences).expand((e) => e).toList();

  @override
  SearchableStatefulWidget copyWith({
    String? searchText,
    SearchConfig? searchConfig,
  }) {
    return SearchableCaptionItem(
      title: title,
      padding: padding,
      showDivider: showDivider,
      initiallyExpanded: initiallyExpanded,
      searchText: searchText ?? this.searchText,
      searchConfig: searchConfig,
      children: children,
    );
  }
}

class SearchableCaptionItemState extends SearchableState<SearchableCaptionItem>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpansion,
          child: Container(
            color: Colors.transparent,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 12)
                    .add(const EdgeInsets.only(top: 20, bottom: 10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ChewieTheme.textDarkGreyColor,
                    letterSpacing: 0.5,
                  ),
                ),
                RotationTransition(
                  turns: _arrowAnimation,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: ChewieTheme.textDarkGreyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 0,
            margin: const EdgeInsets.symmetric(horizontal: 10)
                .add(const EdgeInsets.only(bottom: 4)),
            decoration: BoxDecoration(border: ChewieTheme.bottomDivider),
          ),
        ClipRect(
          child: SizeTransition(
            sizeFactor: _sizeAnimation,
            axisAlignment: -1.0,
            child: Column(children: _buildChildren()),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren() {
    return widget.children
        .map((child) => _withUpdatedSearchText(child))
        .toList();
  }

  SearchableStatefulWidget _withUpdatedSearchText(
      SearchableStatefulWidget child) {
    return child.copyWith(
      searchText: widget.searchText,
      searchConfig: widget.searchConfig,
    );
  }
}

class CaptionItem extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final bool showDivider;
  final List<Widget> children;
  final bool initiallyExpanded;
  final String title;

  const CaptionItem({
    super.key,
    required this.title,
    this.padding,
    this.showDivider = true,
    this.children = const [],
    this.initiallyExpanded = true,
  });

  @override
  CaptionItemState createState() => CaptionItemState();
}

class CaptionItemState extends State<CaptionItem>
    with TickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (_isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpansion,
          child: Container(
            color: Colors.transparent,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 12)
                    .add(const EdgeInsets.only(top: 20, bottom: 10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ChewieTheme.textDarkGreyColor,
                    letterSpacing: 0.5,
                  ),
                ),
                RotationTransition(
                  turns: _arrowAnimation,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: ChewieTheme.textDarkGreyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            height: 0,
            margin: const EdgeInsets.symmetric(horizontal: 10)
                .add(const EdgeInsets.only(bottom: 4)),
            decoration: BoxDecoration(border: ChewieTheme.bottomDivider),
          ),
        ClipRect(
          child: SizeTransition(
            sizeFactor: _sizeAnimation,
            axisAlignment: -1.0,
            child: Column(children: widget.children),
          ),
        ),
      ],
    );
  }
}
