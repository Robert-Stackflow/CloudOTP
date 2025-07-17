import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_context_menu_item.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_selectable_region.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_selection_area.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_selection_toolbar.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/selection_transformer.dart';

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
