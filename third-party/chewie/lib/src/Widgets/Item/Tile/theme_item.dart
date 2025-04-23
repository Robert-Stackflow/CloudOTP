import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Resources/theme_color_data.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';

class ThemeItem extends StatefulWidget {
  final ChewieThemeColorData themeColorData;
  final int index;
  final int groupIndex;
  final Function(int?)? onChanged;

  const ThemeItem({
    Key? key,
    required this.themeColorData,
    required this.index,
    required this.groupIndex,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ThemeItemState createState() => _ThemeItemState();
}

class _ThemeItemState extends State<ThemeItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 107.3,
      height: 166.4,
      margin: EdgeInsets.only(left: widget.index == 0 ? 10 : 0, right: 10),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 10, bottom: 0, left: 8, right: 8),
            decoration: BoxDecoration(
              color: widget.themeColorData.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: ChewieTheme.border,
            ),
            child: Column(
              children: [
                _buildCardRow(widget.themeColorData),
                const SizedBox(height: 5),
                _buildCardRow(widget.themeColorData),
                const SizedBox(height: 15),
                Radio(
                  value: widget.index,
                  groupValue: widget.groupIndex,
                  onChanged: widget.onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return widget.themeColorData.primaryColor;
                    } else {
                      return widget.themeColorData.textLightGreyColor;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.themeColorData.name,
            style: ChewieTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(ChewieThemeColorData themeColorData) {
    return Container(
      height: 35,
      width: 90,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: themeColorData.canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 22,
            width: 22,
            decoration: BoxDecoration(
              color: themeColorData.splashColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: themeColorData.textColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 5,
                width: 35,
                decoration: BoxDecoration(
                  color: themeColorData.textLightGreyColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyThemeItem extends StatefulWidget {
  final Function()? onTap;

  const EmptyThemeItem({
    super.key,
    required this.onTap,
  });

  @override
  _EmptyThemeItemState createState() => _EmptyThemeItemState();
}

class _EmptyThemeItemState extends State<EmptyThemeItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 107.3,
      height: 166.4,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 107.3,
            height: 141.7,
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: ChewieTheme.border,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: ChewieTheme.titleSmall.color,
                ),
                const SizedBox(height: 6),
                Text(ChewieS.current.newTheme, style: ChewieTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "",
            style: ChewieTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
