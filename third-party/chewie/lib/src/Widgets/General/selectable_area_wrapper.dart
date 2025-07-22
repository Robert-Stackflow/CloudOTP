import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_chewie/awesome_chewie.dart';

class SelectableAreaWrapper extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;
  final List<FlutterContextMenuItem> Function(MySelectableRegionState, String?)?
      contextMenuItemsBuilder;

  const SelectableAreaWrapper({
    super.key,
    required this.child,
    required this.focusNode,
    this.contextMenuItemsBuilder,
  });

  @override
  Widget build(BuildContext _) {
    return MySelectionArea(
      focusNode: focusNode,
      // onRightclick: !ResponsiveUtil.isDesktop()
      //     ? null
      //     : (details) {
      //         String? selectedText = details.selectedText;
      //         FlutterContextMenu contextMenu = FlutterContextMenu(
      //           entries: [
      //             if (selectedText.notNullOrEmpty)
      //               FlutterContextMenuItem(
      //                 chewieLocalizations.copy,
      //                 iconData: LucideIcons.copy,
      //                 onPressed: () {
      //                   details.clearSelection();
      //                   ChewieUtils.copy(
      //                       chewieProvider.rootContext, selectedText);
      //                 },
      //               ),
      //             if (selectedText.notNullOrEmpty)
      //               FlutterContextMenuItem.submenu(
      //                 chewieLocalizations.search,
      //                 iconData: LucideIcons.search,
      //                 items: [
      //                   FlutterContextMenuItem(
      //                     "Google搜索",
      //                     onPressed: () {
      //                       details.clearSelection();
      //                       UriUtil.launchUrlUri(chewieProvider.rootContext,
      //                           "https://www.google.com/search?q=$selectedText");
      //                     },
      //                   ),
      //                   FlutterContextMenuItem(
      //                     "Bing搜索",
      //                     onPressed: () {
      //                       details.clearSelection();
      //                       UriUtil.launchUrlUri(chewieProvider.rootContext,
      //                           "https://bing.com/search?q=$selectedText");
      //                     },
      //                   ),
      //                   FlutterContextMenuItem(
      //                     "百度搜索",
      //                     onPressed: () {
      //                       details.clearSelection();
      //                       UriUtil.launchUrlUri(chewieProvider.rootContext,
      //                           "https://www.baidu.com/s?wd=$selectedText");
      //                     },
      //                   ),
      //                 ],
      //               ),
      //             FlutterContextMenuItem(
      //               chewieLocalizations.selectAll,
      //               iconData: LucideIcons.textCursorInput,
      //               onPressed: () {
      //                 details.clearSelection();
      //                 details.selectAll();
      //               },
      //             ),
      //             if (selectedText.notNullOrEmpty)
      //               ...contextMenuItemsBuilder?.call(details, selectedText) ??
      //                   [],
      //           ],
      //         );
      //         contextMenu.showAtMousePosition(
      //           chewieProvider.rootContext,
      //           details.contextMenuAnchors.primaryAnchor,
      //         );
      //       },
      contextMenuBuilder: (contextMenuContext, details) {
        Map<ContextMenuButtonType, String> typeToString = {
          ContextMenuButtonType.copy: chewieLocalizations.copy,
          ContextMenuButtonType.cut: chewieLocalizations.cut,
          ContextMenuButtonType.paste: chewieLocalizations.paste,
          ContextMenuButtonType.selectAll: chewieLocalizations.selectAll,
          ContextMenuButtonType.searchWeb: chewieLocalizations.search,
          ContextMenuButtonType.share: chewieLocalizations.share,
          ContextMenuButtonType.lookUp: chewieLocalizations.search,
          ContextMenuButtonType.delete: chewieLocalizations.delete,
          ContextMenuButtonType.liveTextInput: chewieLocalizations.input,
          ContextMenuButtonType.custom: chewieLocalizations.custom,
        };
        List<MyContextMenuItem> items = [];
        for (var e in details.contextMenuButtonItems) {
          if (e.type != ContextMenuButtonType.custom) {
            items.add(
              MyContextMenuItem(
                label: typeToString[e.type] ?? "",
                type: e.type,
                onPressed: () {
                  e.onPressed?.call();
                },
              ),
            );
          }
        }
        if (ResponsiveUtil.isMobile()) {
          return MyMobileTextSelectionToolbar.items(
            anchorAbove: details.contextMenuAnchors.primaryAnchor,
            anchorBelow: details.contextMenuAnchors.primaryAnchor,
            backgroundColor: ChewieTheme.canvasColor,
            dividerColor: ChewieTheme.dividerColor,
            items: items,
            itemBuilder: (MyContextMenuItem item) {
              return Text(
                item.label ?? "",
                style: ChewieTheme.titleMedium,
              );
            },
          );
        } else {
          return MyDesktopTextSelectionToolbar(
            anchor: details.contextMenuAnchors.primaryAnchor,
            // decoration: ChewieTheme.defaultDecoration,
            dividerColor: ChewieTheme.dividerColor,
            items: items,
          );
        }
      },
      child: SelectionTransformer.separated(
        child: child,
      ),
    );
  }
}
