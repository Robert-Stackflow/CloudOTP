import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Item/Tile/entry_item.dart';

class TileList extends StatelessWidget {
  const TileList(
    this.children, {
    required this.title,
    required Key key,
    this.onCloseTap,
    this.showTitle = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.showCancel = false,
  }) : super(key: key);

  TileList.fromOptions(
    List<Tuple2<String, dynamic>> options,
    Function onSelected, {
    List<dynamic> redOptions = const [],
    Map<dynamic, String> descriptions = const {},
    dynamic selected,
    this.onCloseTap,
    this.title = "",
    this.showTitle = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    required BuildContext context,
    super.key,
    this.showCancel = false,
  }) : children = options
            .map(
              (t) => EntryItem(
                roundTop: !showTitle && t == options.first,
                title: t.item1,
                description: descriptions[t.item2] ?? "",
                trailing: Icons.done_rounded,
                showTrailing: t.item2 == selected,
                titleColor: redOptions.contains(t.item2)
                    ? ChewieTheme.errorColor
                    : null,
                crossAxisAlignment: crossAxisAlignment,
                onTap: () {
                  onSelected(t.item2);
                },
              ),
            )
            .toList();

  final Iterable<Widget> children;
  final String title;
  final Function()? onCloseTap;
  final bool showTitle;
  final bool showCancel;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        if (showTitle)
          Container(
            width: MediaQuery.sizeOf(context).width,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              color: ChewieTheme.canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: ChewieTheme.border,
            ),
            child: Text(title, style: ChewieTheme.titleLarge),
          ),
        if (showTitle)
          Container(
            height: 0,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: ChewieTheme.bottomBorder),
          ),
        ...children,
        if (showCancel)
          EntryItem(
            title: chewieLocalizations.cancel,
            backgroundColor: Theme.of(context).cardColor.withAlpha(127),
            showTrailing: false,
            onTap: onCloseTap,
            crossAxisAlignment: crossAxisAlignment,
          ),
      ],
    );
  }
}
