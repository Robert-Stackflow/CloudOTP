import 'dart:math';

import 'package:awesome_chewie/src/Widgets/Item/Button/round_icon_text_button.dart';
import 'package:awesome_chewie/src/Widgets/Item/General/clickable_gesture_detector.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_context_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/dimens.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Utils/System/route_util.dart';
import 'package:awesome_chewie/src/Utils/utils.dart';
import 'package:awesome_chewie/src/generated/l10n.dart';
import 'package:awesome_chewie/src/Widgets/Component/my_cached_network_image.dart';
import 'package:awesome_chewie/src/Widgets/Custom/hero_photo_view_screen.dart';
import 'package:awesome_chewie/src/Widgets/Module/EasyRefresh/easy_refresh.dart';
import 'package:awesome_chewie/src/Widgets/Selectable/my_selection_toolbar.dart';
import 'General/clickable_wrapper.dart';
import 'General/responsive_app_bar.dart';

class ItemBuilder {
  static Widget buildSettingScreen({
    required BuildContext context,
    required String title,
    required bool showTitleBar,
    required EdgeInsets padding,
    List<Widget> children = const [],
    bool showBack = true,
    Color? backgroundColor,
    double titleLeftMargin = 5,
    bool showBorder = true,
    Function()? onTapBack,
    Widget? overrideBody,
  }) {
    return Scaffold(
      appBar: showTitleBar
          ? ResponsiveAppBar(
              titleLeftMargin: titleLeftMargin,
              showBack: showBack,
              title: title,
              backgroundColor: backgroundColor,
              showBorder: showBorder,
              onTapBack: onTapBack,
            )
          : null,
      body: overrideBody ??
          EasyRefresh(
            child: ListView(
              padding: padding,
              children: children,
            ),
          ),
    );
  }

  static PreferredSize buildPreferredSize({
    double height = kToolbarHeight,
    required Widget child,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: child,
    );
  }

  static MyCachedNetworkImage buildCachedImage({
    required String imageUrl,
    required BuildContext context,
    BoxFit? fit,
    bool showLoading = true,
    double? width,
    double? height,
    double? placeholderHeight,
    Color? placeholderBackground,
    double topPadding = 0,
    double bottomPadding = 0,
    bool simpleError = false,
  }) {
    return MyCachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      simpleError: simpleError,
      height: height,
      placeholderHeight: placeholderHeight,
      placeholderBackground: placeholderBackground,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      showLoading: showLoading,
    );
  }

  static buildHeroCachedImage({
    required String imageUrl,
    required BuildContext context,
    List<String>? imageUrls,
    BoxFit? fit = BoxFit.cover,
    bool showLoading = true,
    double? width,
    double? height,
    Color? placeholderBackground,
    double topPadding = 0,
    double bottomPadding = 0,
    String? title,
    String? caption,
    String? tagPrefix,
    String? tagSuffix,
  }) {
    imageUrls ??= [imageUrl];
    return ClickableGestureDetector(
      onTap: () {
        RouteUtil.pushDialogRoute(
          context,
          showClose: false,
          fullScreen: true,
          useFade: true,
          HeroPhotoViewScreen(
            tagPrefix: tagPrefix,
            tagSuffix: tagSuffix,
            imageUrls: imageUrls!,
            useMainColor: false,
            title: title,
            captions: [caption ?? ""],
            initIndex: imageUrls.indexOf(imageUrl),
          ),
        );
      },
      child: Hero(
        tag: ChewieUtils.getHeroTag(
            tagSuffix: tagSuffix, tagPrefix: tagPrefix, url: imageUrl),
        child: ItemBuilder.buildCachedImage(
          context: context,
          imageUrl: imageUrl,
          width: width,
          height: height,
          showLoading: showLoading,
          bottomPadding: bottomPadding,
          topPadding: topPadding,
          placeholderBackground: placeholderBackground,
          fit: fit,
        ),
      ),
    );
  }

  static buildAvatar({
    required BuildContext context,
    required String imageUrl,
    double size = 32,
    bool showLoading = false,
    bool useDefaultAvatar = false,
    bool showBorder = true,
    bool showDetail = false,
    String? title,
    String? caption,
    String? tagPrefix,
    String? tagSuffix,
    bool clickable = true,
    bool isOval = true,
    Function()? onTap,
  }) {
    String tagUrl = imageUrl;
    return ClickableWrapper(
      clickable: clickable,
      child: Container(
        decoration: BoxDecoration(
          border: showBorder
              ? Border.all(
                  color: ChewieTheme.dividerColor,
                  width: 0.5,
                )
              : const Border.fromBorderSide(BorderSide.none),
          shape: isOval ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isOval ? null : ChewieDimens.borderRadius8,
        ),
        child: useDefaultAvatar || tagUrl.isEmpty
            ? ClipOval(
                child: Image.asset(
                  "assets/avatar.png",
                  width: size,
                  height: size,
                ),
              )
            : ClickableGestureDetector(
                onTap: showDetail
                    ? () {
                        if (ResponsiveUtil.isMobile()) {
                          RouteUtil.pushMaterialRoute(
                            chewieProvider.rootContext,
                            HeroPhotoViewScreen(
                              tagPrefix: tagPrefix,
                              imageUrls: [tagUrl],
                              useMainColor: false,
                              title: title,
                              captions: [caption ?? ""],
                            ),
                          );
                        } else {
                          RouteUtil.pushDialogRoute(
                            context,
                            showClose: false,
                            fullScreen: true,
                            HeroPhotoViewScreen(
                              tagPrefix: tagPrefix,
                              imageUrls: [tagUrl],
                              useMainColor: false,
                              title: title,
                              captions: [caption ?? ""],
                            ),
                          );
                        }
                      }
                    : onTap,
                child: isOval
                    ? ClipOval(
                        child: ItemBuilder.buildCachedImage(
                          context: context,
                          imageUrl: tagUrl,
                          width: size,
                          showLoading: showLoading,
                          height: size,
                          fit: BoxFit.cover,
                          simpleError: true,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: ChewieDimens.borderRadius8,
                        child: ItemBuilder.buildCachedImage(
                          context: context,
                          imageUrl: tagUrl,
                          width: size,
                          showLoading: showLoading,
                          fit: BoxFit.cover,
                          height: size,
                          simpleError: true,
                        ),
                      ),
              ),
      ),
    );
  }

  static Widget buildLoadingDialog({
    required BuildContext context,
    ScrollPhysics? physics,
    bool shrinkWrap = true,
    ScrollController? scrollController,
    String? text,
    bool showText = true,
    double size = 50,
    double topPadding = 0,
    double bottomPadding = 100,
    bool forceDark = false,
    Color? background,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
  }) {
    return Center(
      child: ListView(
        physics: physics,
        shrinkWrap: shrinkWrap,
        controller: scrollController,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: topPadding),
              chewieProvider.loadingWidgetBuilder(size, forceDark),
              if (showText) const SizedBox(height: 10),
              if (showText)
                Text(text ?? ChewieS.current.loading,
                    style: ChewieTheme.labelLarge),
              SizedBox(height: bottomPadding),
            ],
          ),
        ],
      ),
    );
  }

  static buildGroupTile({
    required BuildContext context,
    String title = '',
    required List<String> buttons,
    GroupButtonController? controller,
    EdgeInsets? padding,
    bool disabled = false,
    bool enableDeselect = false,
    bool constraintWidth = true,
    Function(dynamic value, int index, bool isSelected)? onSelected,
  }) {
    return Container(
      color: Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: ChewieTheme.titleMedium
                    .apply(fontWeightDelta: 2, fontSizeDelta: -2),
              ),
            ),
          SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: ItemBuilder.buildGroupButtons(
              buttons: buttons,
              disabled: disabled,
              controller: controller,
              constraintWidth: constraintWidth,
              radius: 8,
              enableDeselect: enableDeselect,
              mainGroupAlignment: MainGroupAlignment.start,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }

  static buildGroupButtons({
    required List<String> buttons,
    GroupButtonController? controller,
    bool enableDeselect = false,
    bool isRadio = true,
    bool constraintWidth = true,
    double radius = 8,
    Function(dynamic value, int index, bool isSelected)? onSelected,
    bool disabled = false,
    MainGroupAlignment mainGroupAlignment = MainGroupAlignment.start,
  }) {
    return GroupButton(
      disabled: disabled,
      isRadio: isRadio,
      enableDeselect: enableDeselect,
      options: GroupButtonOptions(
        mainGroupAlignment: mainGroupAlignment,
      ),
      onSelected: onSelected,
      maxSelected: 1,
      controller: controller,
      buttons: buttons,
      buttonBuilder: (selected, label, context, onTap, __) {
        return SizedBox(
          width: constraintWidth ? 80 : null,
          child: RoundIconTextButton(
            height: 36,
            text: label,
            radius: radius,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            background: selected ? ChewieTheme.primaryColor : null,
            textStyle: ChewieTheme.titleSmall.apply(
                fontWeightDelta: 1, color: selected ? Colors.white : null),
            onPressed: onTap,
          ),
        );
      },
    );
  }

  static Widget editTextContextMenuBuilder(
    contextMenuContext,
    EditableTextState details, {
    required BuildContext context,
  }) {
    Map<ContextMenuButtonType, String> typeToString = {
      ContextMenuButtonType.copy: ChewieS.current.copy,
      ContextMenuButtonType.cut: ChewieS.current.cut,
      ContextMenuButtonType.paste: ChewieS.current.paste,
      ContextMenuButtonType.selectAll: ChewieS.current.selectAll,
      ContextMenuButtonType.searchWeb: ChewieS.current.search,
      ContextMenuButtonType.share: ChewieS.current.share,
      ContextMenuButtonType.lookUp: ChewieS.current.search,
      ContextMenuButtonType.delete: ChewieS.current.delete,
      ContextMenuButtonType.liveTextInput: ChewieS.current.input,
      ContextMenuButtonType.custom: ChewieS.current.custom,
    };
    List<MyContextMenuItem> items = [];
    // int start = details.textEditingValue.selection.start <= -1
    //     ? 0
    //     : details.textEditingValue.selection.start;
    // int end = details.textEditingValue.selection.end
    //     .clamp(0, details.textEditingValue.text.length);
    // String selectedText = details.textEditingValue.text.substring(start, end);
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
  }
}
