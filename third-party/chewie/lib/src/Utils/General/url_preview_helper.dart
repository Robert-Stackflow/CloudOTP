/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:awesome_chewie/src/Utils/itoast.dart';
import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:smart_snackbars/widgets/snackbars/base_snackbar.dart';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/item_builder.dart';

class UrlPreviewHelper {
  static String _currentUrl = "";
  static bool _loading = false;

  static final CustomSnackBarController _snackBarController =
      CustomSnackBarController();

  static bool _hover = false;

  static Future<void> showUrlPreviewOverlay(
      BuildContext context, String url) async {
    url = Uri.decodeFull(url);
    if (_currentUrl == url || _loading) return;
    _currentUrl = url;
    _loading = true;
    await remove();
    Metadata? data = await IToast.showLoadingSnackbar("正在获取网站预览", () async {
      try {
        return await MetadataFetch.extract(url);
      } catch (e, t) {
        IToast.showTop("获取预览失败");
        ILogger.error("Failed to extract metadata for $url", e, t);
      } finally {
        _loading = false;
        _currentUrl = "";
      }
    }, onDismiss: () {
      _loading = false;
      _currentUrl = "";
    });
    _loading = false;
    if (data != null) {
      _showSnackBar(context, url, data);
    } else {
      _currentUrl = "";
      IToast.showTop("获取预览失败");
    }
  }

  static void _showSnackBar(BuildContext context, String url, Metadata data) {
    IToast.showCustomSnackbar(
      child: _buildPreview(context, url, data),
      persist: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      maxWidth: ResponsiveUtil.isLandscapeLayout() ? 600 : null,
      controller: _snackBarController,
      onDismiss: () {
        _loading = false;
        _currentUrl = "";
      },
    );
  }

  static Future<void> remove([bool force = false]) async {
    if (force || (!force && !_hover)) {
      await _snackBarController.close?.call();
    }
    _currentUrl = "";
  }

  static Widget _buildPreview(BuildContext context, String url, Metadata data) {
    return MouseRegion(
      onHover: (_) {
        _hover = true;
      },
      onExit: (_) {
        _hover = false;
        // remove();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "来自$url的预览",
                  style: ChewieTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ResponsiveUtil.isLandscapeLayout())
                RoundIconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () async => await remove(true),
                  padding: const EdgeInsets.all(6),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (data.image != null)
            Row(
              crossAxisAlignment: ResponsiveUtil.isLandscapeLayout()
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: IgnorePointer(
                    child: ItemBuilder.buildHeroCachedImage(
                      imageUrl: data.image!,
                      context: context,
                      height: 150,
                      width: 300,
                      showLoading: false,
                    ),
                  ),
                ),
              ],
            ),
          if (data.image != null) const SizedBox(height: 10),
          if (data.title != null)
            Text(
              data.title!,
              style: ChewieTheme.titleLarge,
              maxLines: 3,
            ),
          if (data.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                data.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.apply(fontSizeDelta: 2),
                maxLines: 5,
              ),
            ),
        ],
      ),
    );
  }
}

// class UrlPreviewHelper {
//   static OverlayEntry? _overlayEntry;
//   static bool _hasCanceled = false;
//
//   static Future<void> showUrlPreviewOverlay(
//       BuildContext context, String url) async {
//     _hasCanceled = false;
//     url = Uri.decodeFull(url);
//     Metadata? data = await MetadataFetch.extract(url);
//     if (data != null) {
//       if (_overlayEntry != null) {
//         removeOverlay();
//       }
//       if (!_hasCanceled) {
//         _overlayEntry = _createOverlayEntry(context, data);
//         Overlay.of(context).insert(_overlayEntry!);
//       }
//     }
//   }
//
//   static OverlayEntry _createOverlayEntry(BuildContext context, Metadata data) {
//     RenderBox renderBox = appProvider.rootContext.findRenderObject() as RenderBox;
//     var offset = renderBox.localToGlobal(Offset.zero);
//
//     return OverlayEntry(
//       builder: (context) => Positioned(
//         left: offset.dx + 20,
//         top: offset.dy + 20,
//         width: 300,
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: MyTheme.defaultDecoration,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (data.image != null)
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: ItemBuilder.buildCachedImage(
//                     imageUrl: data.image!,
//                     context: context,
//                     height: 150,
//                     width: 300,
//                     showLoading: false,
//                   ),
//                 ),
//               if (data.image != null) const SizedBox(height: 10),
//               if (data.title != null)
//                 Text(
//                   data.title!,
//                   style: MyTheme.titleLarge,
//                 ),
//               if (data.description != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8.0),
//                   child: Text(
//                     data.description!,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall
//                         ?.apply(fontSizeDelta: 2),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   static void removeOverlay() {
//     _hasCanceled = true;
//     if (_overlayEntry != null) {
//       _overlayEntry!.remove();
//       _overlayEntry = null;
//     }
//   }
// }
