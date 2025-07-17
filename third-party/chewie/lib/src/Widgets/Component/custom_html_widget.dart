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

import 'dart:async';

import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:awesome_chewie/src/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:code_highlight_view/code_highlight_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:highlighting/languages/dart.dart';
import 'package:provider/provider.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/colors.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Utils/General/html_util.dart';
import 'package:awesome_chewie/src/Utils/General/url_preview_helper.dart';
import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:awesome_chewie/src/Utils/System/uri_util.dart';
import 'package:awesome_chewie/src/Utils/constant.dart';
import 'package:awesome_chewie/src/Utils/enums.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/l10n/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Custom/hero_photo_view_screen.dart';
import 'package:awesome_chewie/src/Widgets/Custom/mouse_state_builder.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_gesture_detector.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_wrapper.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/selectable_area_wrapper.dart';
import 'package:awesome_chewie/src/Widgets/Item/item_builder.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_selectable_region.dart';

enum AnchorType {
  top,
  h1,
  h2,
  h3,
  h4,
  h5,
  h6;

  String get tagName {
    switch (this) {
      case AnchorType.top:
        return 'TOP';
      case AnchorType.h1:
        return 'h1';
      case AnchorType.h2:
        return 'h2';
      case AnchorType.h3:
        return 'h3';
      case AnchorType.h4:
        return 'h4';
      case AnchorType.h5:
        return 'h5';
      case AnchorType.h6:
        return 'h6';
    }
  }

  static AnchorType fromString(String type) {
    switch (type) {
      case 'h1':
        return AnchorType.h1;
      case 'h2':
        return AnchorType.h2;
      case 'h3':
        return AnchorType.h3;
      case 'h4':
        return AnchorType.h4;
      case 'h5':
        return AnchorType.h5;
      case 'h6':
        return AnchorType.h6;
    }
    return AnchorType.h1;
  }
}

class Anchor {
  bool get isTop => type == AnchorType.top;

  final AnchorType type;
  final String title;
  final GlobalKey key = GlobalKey();

  String get id => "${type.tagName}-$title";

  Anchor(this.type, this.title);

  @override
  String toString() {
    return '$type: $title';
  }
}

class CustomHtmlWidget extends StatefulWidget {
  const CustomHtmlWidget({
    super.key,
    this.url,
    required this.content,
    this.style,
    this.enableImageDetail = true,
    this.parseImage = true,
    this.showLoading = true,
    this.onDownloadSuccess,
    this.heightDelta,
    this.letterSpacingDelta,
    this.placeholderBackgroundColor,
    this.anchors = const [],
    this.onAnchorTap,
    this.contextMenuItemsBuilder,
  });

  final String content;
  final TextStyle? style;
  final bool enableImageDetail;
  final bool parseImage;
  final bool showLoading;
  final Function()? onDownloadSuccess;
  final double? heightDelta;
  final double? letterSpacingDelta;
  final Color? placeholderBackgroundColor;
  final List<Anchor> anchors;
  final Function(Anchor anchor)? onAnchorTap;
  final String? url;
  final List<FlutterContextMenuItem> Function(MySelectableRegionState, String?)?
      contextMenuItemsBuilder;

  @override
  CustomHtmlWidgetState createState() => CustomHtmlWidgetState();
}

class CustomHtmlWidgetState extends State<CustomHtmlWidget> {
  Timer? _hoverTimer;
  String? _url;

  _startHoverTimer() {
    _hoverTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_url != null) {
        UrlPreviewHelper.showUrlPreviewOverlay(context, _url!);
      }
    });
  }

  void _cancelHoverTimer() {
    _hoverTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return _buildHtmlWidget(
      widget.content,
      style: widget.style,
      enableImageDetail: widget.enableImageDetail,
      parseImage: widget.parseImage,
      showLoading: widget.showLoading,
      onDownloadSuccess: widget.onDownloadSuccess,
    );
  }

  _buildLinkContextMenuButtons(String url) {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          "在浏览器打开",
          iconData: Icons.open_in_browser_rounded,
          onPressed: () {
            UriUtil.processUrl(context, url);
          },
        ),
        FlutterContextMenuItem(
          chewieLocalizations.copyLink,
          iconData: Icons.copy_rounded,
          onPressed: () {
            ChewieUtils.copy(context, url);
          },
        ),
      ],
    );
  }

  _buildImageContextMenuButtons(String imageUrl) {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          "保存图片",
          iconData: Icons.download_rounded,
          onPressed: () {
            FileUtil.saveImage(context, imageUrl, showToast: true);
          },
        ),
        FlutterContextMenuItem(
          "复制图片链接",
          iconData: Icons.copy_rounded,
          onPressed: () {
            ChewieUtils.copy(context, imageUrl);
          },
        ),
        FlutterContextMenuItem(
          "在浏览器打开",
          iconData: Icons.open_in_browser_rounded,
          onPressed: () {
            UriUtil.openExternal(imageUrl);
          },
        ),
        FlutterContextMenuItem(
          "Google搜图",
          iconData: Icons.image_search_rounded,
          onPressed: () {
            UriUtil.openExternal(
                "https://lens.google.com/uploadbyurl?url=$imageUrl");
          },
        ),
        FlutterContextMenuItem(
          "Bing识图",
          iconData: Icons.image_search_rounded,
          onPressed: () {
            UriUtil.openExternal(
                "https://www.bing.com/images/searchbyimage?FORM=IRSBIQ&cbir=sbi&imgurl=$imageUrl");
          },
        )
      ],
    );
  }

  _buildHtmlWidget(
    String content, {
    TextStyle? style,
    bool enableImageDetail = true,
    bool parseImage = true,
    bool showLoading = true,
    Function()? onDownloadSuccess,
  }) {
    if (style != null) {
      style = style.apply(
        heightDelta: widget.heightDelta ?? -0.1,
        // letterSpacingDelta: widget.letterSpacingDelta ?? -0.5,
      );
    }
    style ??= Theme.of(context)
        .textTheme
        .bodyMedium
        ?.apply(fontSizeDelta: 1, heightDelta: 0.1);
    List<String> images = StringUtil.extractImagesFromHtml(content);
    int lastAnchorIndex = 0;
    return SelectableAreaWrapper(
      focusNode: FocusNode(),
      contextMenuItemsBuilder: widget.contextMenuItemsBuilder,
      child: HtmlWidget(
        content,
        enableCaching: true,
        renderMode: RenderMode.column,
        textStyle: style,
        factoryBuilder: () => CustomImageFactory(),
        customWidgetBuilder: (element) {
          if (element.localName == 'a' &&
              element.attributes.containsKey('href')) {
            String url = element.attributes['href']!;
            String? imageUrl =
                element.querySelector('img')?.attributes['src'] ??
                    element.querySelector('img')?.attributes['data-src'];
            return _renderA(
              url,
              element.text,
              imageUrl,
              style: style,
              images: images,
            );
          } else if (element.localName == 'img' && parseImage) {
            String imageUrl = element.attributes['src'] ??
                element.attributes['data-src'] ??
                '';
            return SelectionContainer.disabled(
              child: _renderImg(
                imageUrl,
                images,
                enableImageDetail: enableImageDetail,
                onDownloadSuccess: onDownloadSuccess,
              ),
            );
          } else if (element.localName == 'pre') {
            String code = StringUtil.extractTextFromHtml(element.outerHtml);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: _renderPre(code),
            );
          } else if (element.localName == 'code') {
            return _renderCode(element.text);
          } else if (element.localName == 'li') {
            return null;
          } else if (element.localName == 'h1' ||
              element.localName == 'h2' ||
              element.localName == 'h3' ||
              element.localName == 'h4') {
            List<String> titles = HtmlUtil.extractTitles(content);
            var res = _renderH(
              element.outerHtml,
              element.localName,
              element.text,
              titles,
              lastIndex: lastAnchorIndex,
            );
            lastAnchorIndex = res[0];
            return res[1];
          }
          return null;
        },
        customStylesBuilder: (e) {
          if (e.attributes.containsKey("data-f-id") &&
              e.attributes["data-f-id"] == "pbf") {
            return {
              'display': 'none',
            };
          }

          if (e.id == "title") {
            return {
              'font-weight': '700',
              'font-size': 'larger',
            };
          }

          if (e.localName == 'blockquote') {
            return {
              'font-style': 'italic',
              'border-left':
                  '3px solid #${ChewieTheme.primaryColor40WithoutAlpha.value.toRadixString(16)}',
              'padding': '0px',
              'padding-left': '10px',
              'margin': '10px 5px',
            };
          }

          // if (e.localName == 'ul') {
          //   return {
          //     'padding-left': '10px',
          //   };
          // }
          //
          // if (e.localName == 'ol') {
          //   return {
          //     'padding-left': '10px',
          //     'list-style-type': 'decimal',
          //   };
          // }
          //
          // if (e.localName == 'li') {
          //   return {
          //     'margin-bottom': '5px',
          //   };
          // }

          if (e.localName == 'hr') {
            return {
              'border': 'none',
              'border-radius': '5px',
              'border-top':
                  '1px solid #${ChewieColors.dividerColor.value.toRadixString(16)}',
              'margin': '30px 30px',
            };
          }

          if (e.localName == 'table') {
            return {
              'width': '80%',
              'border-collapse': 'collapse',
              'cellspacing': '0px',
              'margin': 'auto 0px',
            };
          }
          if (e.localName == 'td') {
            return {
              'border':
                  '1px solid #${ChewieTheme.primaryColor40WithoutAlpha.value.toRadixString(16)}',
              'padding': '8px',
              'text-align': 'center',
            };
          }
          if (e.localName == 'th') {
            return {
              'background-color':
                  '#${ChewieTheme.primaryColor40WithoutAlpha.value.toRadixString(16)}',
              'font-weight': 'bold',
              'border':
                  '1px solid #${ChewieTheme.primaryColor40WithoutAlpha.value.toRadixString(16)}',
              'padding': '8px',
              'text-align': 'center',
            };
          }

          return null;
        },
        onTapUrl: (url) async {
          UriUtil.processUrl(context, url);
          return true;
        },
        onLoadingBuilder: showLoading
            ? (context, _, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ItemBuilder.buildLoadingDialog(
                    context: context,
                    text: chewieLocalizations.loading,
                    size: 40,
                    bottomPadding: 30,
                    topPadding: 30,
                    background: widget.placeholderBackgroundColor,
                  ),
                );
              }
            : null,
      ),
    );
  }

  _renderH(
    String outerHtml,
    String? localName,
    String text,
    List<String> titles, {
    int lastIndex = 0,
  }) {
    text = text.trim();
    Anchor? anchor;
    Key? key;
    TextStyle style = ChewieTheme.titleLarge;
    try {
      var index = titles.indexOf(text, lastIndex);
      if (index != -1) {
        lastIndex = index + 1;
      }
      anchor = widget.anchors[index];
      key = anchor.key;
    } catch (e, t) {
      ILogger.error('render h error for $localName "$text" from $titles', e, t);
    }
    switch (localName) {
      case 'h1':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: 6);
        break;
      case 'h2':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: 4);
        break;
      case 'h3':
        style = ChewieTheme.titleLarge.apply(fontSizeDelta: 2);
        break;
      case 'h4':
        style = ChewieTheme.titleLarge;
        break;
    }
    //TODO
    // h也可能是链接
    return [
      lastIndex,
      Container(
        key: key,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: MouseStateBuilder(
          builder: (context, state) => Text.rich(
            textAlign: TextAlign.start,
            TextSpan(
              children: [
                TextSpan(text: text, style: style),
                if (state.isMouseOver)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AnimatedOpacity(
                      opacity: state.isMouseOver ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 3000),
                      curve: Curves.easeInOut,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ClickableGestureDetector(
                          onTap: () {
                            if (anchor != null && widget.onAnchorTap != null) {
                              widget.onAnchorTap!(anchor);
                            }
                          },
                          child: Icon(
                            Icons.tag_rounded,
                            size: 20,
                            color: ChewieTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  _renderA(
    String url,
    String text,
    String? imageUrl, {
    TextStyle? style,
    List<String> images = const [],
  }) {
    if (imageUrl != null) {
      return SelectionContainer.disabled(
        child: _renderImg(
          imageUrl,
          images,
          enableImageDetail: false,
        ),
      );
    }
    return InlineCustomWidget(
      child: ClickableWrapper(
        clickable: true,
        child: MouseRegion(
          onHover: (_) {
            if (ResponsiveUtil.isLandscape()) {
              _url = url;
              _startHoverTimer();
            }
          },
          onExit: (_) async {
            _url = null;
            _cancelHoverTimer();
            await UrlPreviewHelper.remove();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              UriUtil.processUrl(context, url);
            },
            onSecondaryTap: () {
              BottomSheetBuilder.showContextMenu(
                  context, _buildLinkContextMenuButtons(url));
            },
            child: Text(
              text,
              style: style?.apply(color: ChewieColors.getLinkColor(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderUlLi(String text, TextStyle? style) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor120,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HtmlWidget(text, textStyle: style),
          ),
        ],
      ),
    );
  }

  Widget _renderImg(
    String imageUrl,
    List<String> images, {
    bool enableImageDetail = true,
    Function()? onDownloadSuccess,
  }) {
    var res = enableImageDetail
        ? ClickableGestureDetector(
            onTap: () {
              if (imageUrl.isNotEmpty) {
                RouteUtil.pushDialogRoute(
                  context,
                  showClose: false,
                  fullScreen: true,
                  useFade: true,
                  barrierDismissible: false,
                  HeroPhotoViewScreen(
                    imageUrls: images,
                    useMainColor: true,
                    initIndex: images.indexOf(imageUrl),
                    onDownloadSuccess: onDownloadSuccess,
                  ),
                );
              }
            },
            onLongPress: () {
              BottomSheetBuilder.showContextMenu(
                context,
                _buildImageContextMenuButtons(imageUrl),
              );
            },
            onSecondaryTap: () {
              BottomSheetBuilder.showContextMenu(
                context,
                _buildImageContextMenuButtons(imageUrl),
              );
            },
            child: Hero(
              tag: ChewieUtils.getHeroTag(url: imageUrl),
              child: ClipRRect(
                borderRadius: ChewieDimens.borderRadius8,
                child: ItemBuilder.buildCachedImage(
                  context: context,
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholderHeight: 300,
                ),
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ItemBuilder.buildCachedImage(
              context: context,
              showLoading: false,
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      child: res,
    );
  }

  _renderPre(String code, {bool showRowIndex = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: ChewieTheme.borderWithWidth(1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor40,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: ChewieTheme.bottomBorderWithWidth(1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    HtmlUtil.detectLanguage(code).toUpperCase(),
                    style: ChewieTheme.titleMedium,
                  ),
                ),
                RoundIconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    ChewieUtils.copy(context, code);
                  },
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Selector<ChewieProvider, ActiveThemeMode>(
              selector: (context, chewieProvider) => chewieProvider.themeMode,
              builder: (context, themeMode, child) {
                final lines = code.split('\n');
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showRowIndex)
                      Container(
                        color: ChewieTheme.primaryColor40,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(lines.length, (index) {
                            return Text(
                              '${index + 1}',
                              style: ChewieTheme.bodyMedium.apply(
                                fontSizeDelta: 1,
                                color: themeMode == ActiveThemeMode.light
                                    ? Colors.grey
                                    : Colors.grey[400],
                                heightDelta: -0.01,
                              ),
                            );
                          }),
                        ),
                      ),
                    Expanded(
                      child: CodeHighlightView(
                        code,
                        language: dart.id,
                        theme: themeMode == ActiveThemeMode.light
                            ? githubTheme
                            : githubDarkTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle:
                            ChewieTheme.bodyMedium.apply(fontSizeDelta: 1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _renderCode(String text) {
    return InlineCustomWidget(
      child: GestureDetector(
        onLongPress: () {
          ChewieUtils.copy(context, text);
        },
        child: Container(
          decoration: BoxDecoration(
            color: ChewieTheme.primaryColor40,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(text),
        ),
      ),
    );
  }
}

class CustomImageFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree meta, ImageSource src) {
    final url = src.url;
    if (url.startsWith('asset:') ||
        url.startsWith('data:image/') ||
        url.startsWith('file:')) {
      return super.buildImageWidget(meta, src);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fill,
      placeholder: (_, __) => emptyWidget,
      errorWidget: (_, __, ___) => emptyWidget,
    );
  }
}
