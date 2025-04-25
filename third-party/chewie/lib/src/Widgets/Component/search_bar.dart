import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/Tile/input_item.dart';
import 'package:awesome_chewie/src/Widgets/Item/item_builder.dart';

class MySearchBar extends StatefulWidget {
  final String hintText;
  final Function(dynamic value) onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color? background;
  final double borderRadius;
  final double? bottomMargin;
  final InputItemStyle? style;
  final bool showSearchButton;

  const MySearchBar({
    super.key,
    required this.hintText,
    required this.onSubmitted,
    this.controller,
    this.focusNode,
    this.background,
    this.borderRadius = 50,
    this.bottomMargin,
    this.style,
    this.showSearchButton = false,
  });

  @override
  MySearchBarState createState() => MySearchBarState();
}

class MySearchBarState extends State<MySearchBar> {
  @override
  Widget build(BuildContext context) {
    InputItemStyle style =
        widget.style ?? InputItemStyle(backgroundColor: Colors.transparent);
    return Row(
      children: [
        Expanded(
          child: TextField(
            focusNode: widget.focusNode,
            controller: widget.controller,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSubmitted,
            style: ChewieTheme.titleSmall,
            cursorColor: ChewieTheme.primaryColor,
            cursorRadius: const Radius.circular(5),
            cursorOpacityAnimates: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              filled: true,
              fillColor: widget.background ??
                  style.fieldBackgroundColor ??
                  ChewieTheme.canvasColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13.5),
              isDense: style.isDense,
              counterStyle: ChewieTheme.bodySmall,
              hintStyle: ChewieTheme.bodySmall,
              prefixIcon: null,
              errorStyle:
                  ChewieTheme.bodySmall.apply(color: ChewieTheme.errorColor),
              errorMaxLines: 1,
              border: style.showBorder
                  ? OutlineInputBorder(
                      borderSide: ChewieTheme.borderSide,
                      borderRadius: BorderRadius.circular(style.radius),
                      gapPadding: 0,
                    )
                  : InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: ChewieTheme.primaryColor, width: 0.8),
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: ChewieTheme.borderSide,
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: ChewieTheme.borderSide,
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              ),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: ChewieTheme.errorColor, width: 0.8),
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ChewieTheme.errorColor, width: 1),
                borderRadius: BorderRadius.circular(style.radius),
                gapPadding: 0,
              ),
            ),
            contextMenuBuilder: (contextMenuContext, details) =>
                ItemBuilder.editTextContextMenuBuilder(
              contextMenuContext,
              details,
              context: context,
            ),
          ),
        ),
        if (widget.showSearchButton) ...[
          const SizedBox(width: 8),
          RoundIconTextButton(
            background: ChewieTheme.canvasColor,
            border: ChewieTheme.borderWithWidth(1),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tooltip: ChewieS.current.search,
            icon: Icon(
              LucideIcons.search,
              color: ChewieTheme.iconColor,
              size: 20,
            ),
            onPressed: () {
              widget.onSubmitted(widget.controller?.text);
            },
          ),
        ],
      ],
    );
  }
}
