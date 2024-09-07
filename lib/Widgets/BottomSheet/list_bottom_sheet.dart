import 'package:cloudotp/Utils/Tuple/tuple.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

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
              (t) => ItemBuilder.buildEntryItem(
                topRadius: !showTitle && t == options.first,
                title: t.item1,
                trailing: Icons.done_rounded,
                showTrailing: t.item2 == selected,
                titleColor:
                    redOptions.contains(t.item2) ? Colors.redAccent : null,
                crossAxisAlignment: crossAxisAlignment,
                onTap: () {
                  onSelected(t.item2);
                },
                context: context,
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
              color: Theme.of(context).canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        if (showTitle)
          Container(
            height: 0,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ...children,
        if (showCancel)
          ItemBuilder.buildEntryItem(
            title: S.current.cancel,
            backgroundColor: Colors.grey.withOpacity(0.1),
            showTrailing: false,
            onTap: onCloseTap,
            context: context,
            crossAxisAlignment: crossAxisAlignment,
          ),
      ],
    );
  }
}
