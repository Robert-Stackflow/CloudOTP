import 'package:auto_size_text/auto_size_text.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class FontItem extends StatefulWidget {
  final CustomFont font;
  final CustomFont currentFont;
  final Function(CustomFont?)? onChanged;
  final Function(CustomFont?)? onDelete;
  final bool showDelete;
  final double width;
  final double height;

  const FontItem({
    super.key,
    required this.font,
    required this.currentFont,
    required this.onChanged,
    this.onDelete,
    this.showDelete = false,
    this.width = 110,
    this.height = 154,
  });

  @override
  FontItemState createState() => FontItemState();
}

class FontItemState extends State<FontItem> {
  bool exist = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
            decoration: BoxDecoration(
              color: ChewieTheme.canvasColor,
              border: ChewieTheme.border,
              borderRadius: ChewieDimens.borderRadius8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: widget.height - 65,
                  child: FutureBuilder(
                    future: Future<CustomFont>.sync(() async {
                      exist = await CustomFont.isFontFileExist(widget.font);
                      return widget.font;
                    }),
                    builder: (context, snapshot) {
                      return exist
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  "AaBbCcDd",
                                  style: ChewieTheme.bodyMedium.apply(
                                    fontFamily: widget.font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "AaBbCcDd",
                                  style: ChewieTheme.bodyMedium.apply(
                                    fontWeightDelta: 2,
                                    fontFamily: widget.font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "你好世界",
                                  style: ChewieTheme.bodyMedium.apply(
                                    fontFamily: widget.font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                                AutoSizeText(
                                  "你好世界",
                                  style: ChewieTheme.bodyMedium.apply(
                                    fontWeightDelta: 2,
                                    fontFamily: widget.font.fontFamily,
                                    letterSpacingDelta: 1,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            )
                          : Text(
                              chewieLocalizations.fontFileNotExist,
                              style: ChewieTheme.bodyMedium.apply(
                                fontFamily: widget.font.fontFamily,
                                fontWeightDelta: 0,
                              ),
                            );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio(
                      value: widget.font,
                      groupValue: widget.currentFont,
                      onChanged: widget.onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return ChewieTheme.primaryColor;
                        } else {
                          return ChewieTheme.bodySmall.color;
                        }
                      }),
                    ),
                    if (widget.showDelete) const SizedBox(width: 5),
                    if (widget.showDelete)
                      CircleIconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: ChewieTheme.errorColor,
                          size: 21,
                        ),
                        padding: const EdgeInsets.all(10),
                        onTap: () {
                          widget.onDelete?.call(widget.font);
                        },
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.font.intlFontName,
            style: ChewieTheme.bodySmall.apply(
              fontFamily: widget.font.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EmptyFontItem extends StatefulWidget {
  final Function()? onTap;
  final double width;
  final double height;

  const EmptyFontItem({
    super.key,
    this.onTap,
    this.width = 110,
    this.height = 160,
  });

  @override
  EmptyFontItemState createState() => EmptyFontItemState();
}

class EmptyFontItemState extends State<EmptyFontItem> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          ClickableGestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding:
                  const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
              decoration: BoxDecoration(
                color: ChewieTheme.canvasColor,
                border: ChewieTheme.border,
                borderRadius: ChewieDimens.borderRadius8,
              ),
              child: Icon(
                LucideIcons.plus,
                size: 40,
                color: ChewieTheme.labelSmall.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chewieLocalizations.loadFontFamily,
            style: ChewieTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
