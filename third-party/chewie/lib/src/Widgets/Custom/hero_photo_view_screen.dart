import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Utils/General/color_util.dart';
import 'package:awesome_chewie/src/Utils/System/file_util.dart';
import 'package:awesome_chewie/src/Utils/System/hive_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/constant.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/Widgets/Component/translucent_tag.dart';
import 'package:awesome_chewie/src/Widgets/Component/window_caption.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/window_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/appbar_wrapper.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/loading_widget.dart';
import 'package:awesome_chewie/src/Widgets/Module/PhotoView/photo_view.dart';
import 'package:awesome_chewie/src/Widgets/Module/PhotoView/photo_view_gallery.dart';

enum DownloadState { none, loading, succeed, failed }

class HeroPhotoViewScreen extends StatefulWidget {
  const HeroPhotoViewScreen({
    super.key,
    required this.imageUrls,
    this.initialScale = PhotoViewComputedScale.contained,
    this.minScale = PhotoViewComputedScale.contained,
    this.maxScale,
    this.initIndex,
    this.useMainColor = true,
    this.captions,
    this.onIndexChanged,
    this.title,
    this.tagPrefix,
    this.tagSuffix,
    this.mainColors,
    this.onDownloadSuccess,
  });

  final String? title;
  final String? tagPrefix;
  final String? tagSuffix;
  final List<String> imageUrls;
  final List<String>? captions;
  final dynamic initialScale;
  final dynamic minScale;
  final dynamic maxScale;
  final int? initIndex;
  final bool useMainColor;
  final List<Color>? mainColors;
  final Function(int)? onIndexChanged;
  final Function()? onDownloadSuccess;

  @override
  State<HeroPhotoViewScreen> createState() => HeroPhotoViewScreenState();
}

enum UrlType { string, photoLink, illust }

class HeroPhotoViewScreenState extends State<HeroPhotoViewScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final List<String> imageUrls;
  late final List<String> captions;
  late final dynamic initialScale;
  late final dynamic minScale;
  late final dynamic maxScale;
  String currentUrl = "";
  int currentIndex = 0;
  List<Color> mainColors = [];
  late dynamic downloadIcon;
  DownloadState downloadState = DownloadState.none;
  late dynamic allDownloadIcon;
  DownloadState allDownloadState = DownloadState.none;
  late PageController _pageController;
  final List<PhotoViewController> _viewControllers = [];

  @override
  void initState() {
    super.initState();
    setDownloadState(DownloadState.none, recover: false);
    setAllDownloadState(DownloadState.none, recover: false);
    imageUrls = widget.imageUrls;
    _viewControllers.addAll(List.generate(imageUrls.length, (index) {
      return PhotoViewController();
    }));
    captions = widget.captions ?? [];
    minScale = widget.minScale;
    maxScale = widget.maxScale;
    initialScale = widget.initialScale;
    currentIndex = widget.initIndex ?? 0;
    currentIndex = max(0, min(currentIndex, imageUrls.length - 1));
    _pageController = PageController(initialPage: currentIndex);
    if (widget.mainColors != null &&
        widget.mainColors!.length >= imageUrls.length &&
        ChewieHiveUtil.getBool(ChewieHiveUtil.followMainColorKey)) {
      mainColors = widget.mainColors!;
    } else {
      mainColors = List.filled(imageUrls.length, Colors.black);
      if (widget.useMainColor &&
          ChewieHiveUtil.getBool(ChewieHiveUtil.followMainColorKey)) {
        ColorUtil.getMainColors(
          context,
          imageUrls.map((e) => getUrl(imageUrls.indexOf(e))).toList(),
        ).then((value) {
          if (mounted) setState(() {});
          mainColors = value;
        });
      }
    }
    updateCurrentUrl();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Stack(
          children: [
            _buildAppBar(),
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
          ],
        ),
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          imageUrls.length == 1 ? _buildSinglePage() : _buildMultiplePage(),
          if (getCaption(currentIndex).isNotEmpty)
            Positioned(
              bottom: 60,
              child: Center(
                child: TranslucentTag(
                  text: getCaption(currentIndex),
                  borderRadius: 8,
                  opacity: 0.4,
                  fontSizeDelta: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            ),
          if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
            Positioned(
              left: 16,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: currentIndex == 0
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.4),
                  borderRadius: ChewieDimens.defaultBorderRadius,
                ),
                child: GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: MouseRegion(
                    cursor: currentIndex == 0
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: const Icon(
                      Icons.keyboard_arrow_left_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (imageUrls.length > 1 && ResponsiveUtil.isDesktop())
            Positioned(
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: currentIndex == imageUrls.length - 1
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.4),
                  borderRadius: ChewieDimens.defaultBorderRadius,
                ),
                child: GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  child: MouseRegion(
                    cursor: currentIndex == imageUrls.length - 1
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: const Icon(
                      Icons.keyboard_arrow_right_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String getUrl(int index) {
    return imageUrls[index];
  }

  getCaption(index) {
    if (index > captions.length - 1) return "";
    return captions[index];
  }

  updateCurrentUrl() {
    currentUrl = getUrl(currentIndex);
  }

  getPreferedScale(dynamic item) {
    dynamic preferScale = initialScale;
    return preferScale;
  }

  PointerSignalEventListener get onPointerSignal => (event) {
        if (event is PointerScrollEvent &&
            currentIndex >= 0 &&
            currentIndex < imageUrls.length) {
          final delta = event.scrollDelta.dy;
          final scale = _viewControllers[currentIndex].scale ?? 1.0;
          final newScale = scale - delta / 1000;
          _viewControllers[currentIndex].scale = newScale.clamp(0.1, 10.0);
        }
      };

  Widget _buildSinglePage() {
    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.sizeOf(context).height,
      ),
      child: Listener(
        onPointerSignal: onPointerSignal,
        child: PhotoView(
          controller: _viewControllers[0],
          imageProvider: CachedNetworkImageProvider(currentUrl),
          initialScale: getPreferedScale(currentUrl),
          minScale: minScale,
          maxScale: maxScale,
          backgroundDecoration: BoxDecoration(
              color: ColorUtil.getDarkColor(mainColors[currentIndex])),
          heroAttributes: PhotoViewHeroAttributes(
            tag: ChewieUtils.getHeroTag(
              tagSuffix: widget.tagSuffix,
              tagPrefix: widget.tagPrefix,
              url: currentUrl,
            ),
          ),
          loadingBuilder: (context, event) => _buildLoading(
            event,
            index: currentIndex,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiplePage() {
    return Listener(
      onPointerSignal: onPointerSignal,
      child: PhotoViewGallery.builder(
        scrollPhysics: const ClampingScrollPhysics(),
        pageController: _pageController,
        backgroundDecoration: BoxDecoration(
            color: ColorUtil.getDarkColor(mainColors[currentIndex])),
        loadingBuilder: (context, event) => _buildLoading(
          event,
          index: currentIndex,
        ),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            controller: _viewControllers[index],
            imageProvider: CachedNetworkImageProvider(getUrl(index)),
            initialScale: getPreferedScale(imageUrls[index]),
            minScale: minScale,
            maxScale: maxScale,
            heroAttributes: PhotoViewHeroAttributes(
              tag: ChewieUtils.getHeroTag(
                tagSuffix: widget.tagSuffix,
                tagPrefix: widget.tagPrefix,
                url: getUrl(index),
              ),
            ),
            filterQuality: FilterQuality.high,
            // onTapDown: (_, __, ___) {
            //   Navigator.pop(context);
            // },
          );
        },
        itemCount: imageUrls.length,
        onPageChanged: (index) async {
          if (widget.onIndexChanged != null) {
            widget.onIndexChanged!(index);
          }
          setState(() {
            currentIndex = index;
            updateCurrentUrl();
          });
          setDownloadState(DownloadState.none, recover: false);
        },
      ),
    );
  }

  void setDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        downloadIcon = LucideIcons.download;
        break;
      case DownloadState.loading:
        downloadIcon = Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          child: const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        );
        break;
      case DownloadState.succeed:
        downloadIcon =
            Icon(Icons.check_rounded, color: ChewieTheme.successColor);
        break;
      case DownloadState.failed:
        downloadIcon =
            Icon(Icons.warning_amber_rounded, color: ChewieTheme.errorColor);
        break;
    }
    downloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      Future.delayed(const Duration(seconds: 2), () {
        setDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  void setAllDownloadState(DownloadState state, {bool recover = true}) {
    switch (state) {
      case DownloadState.none:
        allDownloadIcon =
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 22);
        break;
      case DownloadState.loading:
        allDownloadIcon = Container(
          width: 20,
          height: 20,
          padding: const EdgeInsets.all(2),
          child: const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        );
        break;
      case DownloadState.succeed:
        allDownloadIcon =
            Icon(Icons.check_rounded, color: ChewieTheme.successColor);
        break;
      case DownloadState.failed:
        allDownloadIcon =
            Icon(Icons.warning_amber_rounded, color: ChewieTheme.errorColor);
        break;
    }
    allDownloadState = state;
    if (mounted) setState(() {});
    if (recover) {
      Future.delayed(const Duration(seconds: 2), () {
        setAllDownloadState(DownloadState.none, recover: false);
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWrapper(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 5,
      leadingIcon:
          ResponsiveUtil.isLandscape() ? null : Icons.arrow_back_rounded,
      leadingColor: Colors.white,
      onLeadingTap: () {
        Navigator.pop(context);
        chewieProvider.panelScreenState?.updateStatusBar();
      },
      title: imageUrls.length > 1
          ? Text(
              "${currentIndex + 1}/${imageUrls.length}",
              style: ChewieTheme.titleLarge.apply(
                color: Colors.white,
              ),
            )
          : widget.title != null
              ? Text(
                  widget.title!,
                  style: ChewieTheme.titleLarge.apply(
                    color: Colors.white,
                  ),
                )
              : emptyWidget,
      actions: [
        ToolButton(
          context: context,
          iconBuilder: (_) =>
              const Icon(LucideIcons.link2, color: Colors.white),
          padding: const EdgeInsets.all(8.0),
          onPressed: () {
            ChewieUtils.copy(context, currentUrl);
          },
        ),
        const SizedBox(width: 5),
        ToolButton(
          context: context,
          iconBuilder: (_) =>
              const Icon(Icons.share_rounded, color: Colors.white, size: 22),
          onPressed: () {
            FileUtil.shareImage(context, currentUrl);
          },
        ),
        const SizedBox(width: 5),
        ...[
          ToolButton(
            context: context,
            iconBuilder: (_) => downloadIcon,
            padding: const EdgeInsets.all(8.0),
            onPressed: () {
              if (downloadState == DownloadState.none) {
                setDownloadState(DownloadState.loading, recover: false);
                FileUtil.saveImage(
                  context,
                  currentUrl,
                ).then((res) {
                  if (res) {
                    widget.onDownloadSuccess?.call();
                    setDownloadState(DownloadState.succeed);
                  } else {
                    setDownloadState(DownloadState.failed);
                  }
                });
              }
            },
          ),
          if (imageUrls.length > 1 || ResponsiveUtil.isLandscape())
            const SizedBox(width: 5),
        ],
        if (imageUrls.length > 1) ...[
          ToolButton(
            context: context,
            iconBuilder: (_) => allDownloadIcon,
            onPressed: () {
              if (allDownloadState == DownloadState.none) {
                setAllDownloadState(DownloadState.loading, recover: false);

                FileUtil.saveImages(
                  context,
                  imageUrls,
                ).then((res) {
                  if (res) {
                    widget.onDownloadSuccess?.call();
                    setAllDownloadState(DownloadState.succeed);
                  } else {
                    setAllDownloadState(DownloadState.failed);
                  }
                });
              }
            },
          ),
          if (ResponsiveUtil.isLandscape()) const SizedBox(width: 5),
        ],
        if (ResponsiveUtil.isLandscape())
          ToolButton(
            context: context,
            iconBuilder: (_) =>
                const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            onPressed: () {
              chewieProvider.dialogNavigatorState?.popPage();
            },
          ),
      ],
    );
  }

  Widget _buildLoading(
    ImageChunkEvent? event, {
    int index = 0,
  }) {
    return const LoadingWidget(
      bottomPadding: 0,
      showText: false,
      size: 40,
      forceDark: true,
      background: Colors.transparent,
    );
  }
}
