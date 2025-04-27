import 'package:awesome_chewie/src/Widgets/Item/General/appbar_wrapper.dart';
import 'package:flutter/material.dart';

import 'package:awesome_chewie/src/Providers/chewie_provider.dart';
import 'package:awesome_chewie/src/Resources/theme.dart';
import 'package:awesome_chewie/src/Utils/General/responsive_util.dart';
import 'package:awesome_chewie/src/Widgets/Component/window_caption.dart';
import 'package:awesome_chewie/src/Widgets/Item/Button/window_button.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBack;
  final Function()? onTapBack;
  final bool? showBorder;
  final Widget? bottomWidget;
  final double? bottomHeight;
  final Color? backgroundColor;
  final bool centerTitle;
  final double titleLeftMargin;
  final double rightSpacing;
  final List<Widget> actions;
  final double height;
  final double? borderWidth;

  const ResponsiveAppBar({
    super.key,
    this.title = "",
    this.titleWidget,
    this.showBack = false,
    this.onTapBack,
    this.showBorder,
    this.bottomWidget,
    this.bottomHeight,
    this.backgroundColor,
    this.centerTitle = false,
    this.titleLeftMargin = 5,
    this.rightSpacing = 8,
    this.actions = const [],
    this.height = 48,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = ResponsiveUtil.isLandscape();
    final Widget titleContent = Container(
      margin: EdgeInsets.only(left: titleLeftMargin),
      child: titleWidget ?? Text(title, style: ChewieTheme.titleLarge),
    );

    final PreferredSize topWidget = PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? ChewieTheme.appBarBackgroundColor,
          border: (showBorder ?? true)
              ? ChewieTheme.bottomDividerWithWidth(borderWidth)
              : null,
        ),
        child: isLandscape
            ? Stack(
                children: [
                  ResponsiveUtil.buildDesktopWidget(
                      desktop: const WindowMoveHandle()),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (showBack)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: ToolButton(
                              context: context,
                              onPressed: onTapBack ??
                                  () => chewieProvider.panelScreenState
                                      ?.popPage(),
                              iconBuilder: (_) => const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 22),
                            ),
                          ),
                        titleContent,
                      ],
                    ),
                  ),
                ],
              )
            : AppBarWrapper(
                centerTitle: centerTitle,
                leadingIcon: showBack ? Icons.arrow_back_rounded : null,
                onLeadingTap: onTapBack ??
                    () => chewieProvider.panelScreenState?.popPage(),
                backgroundColor:
                    backgroundColor ?? ChewieTheme.scaffoldBackgroundColor,
                titleLeftMargin: titleLeftMargin,
                rightSpacing: rightSpacing,
                title: titleWidget != null
                    ? Container(
                        constraints: const BoxConstraints(maxHeight: 60),
                        child: titleWidget,
                      )
                    : Text(
                        title,
                        style:
                            ChewieTheme.titleMedium.apply(fontWeightDelta: 2),
                      ),
                actions: actions,
              ),
      ),
    );

    return SafeArea(
      child: bottomWidget != null && bottomHeight != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(height + bottomHeight!),
              child: Column(
                children: [
                  topWidget,
                  bottomWidget!,
                ],
              ),
            )
          : topWidget,
    );
  }

  @override
  Size get preferredSize => bottomWidget != null && bottomHeight != null
      ? Size.fromHeight(height + bottomHeight!)
      : Size.fromHeight(height);
}
