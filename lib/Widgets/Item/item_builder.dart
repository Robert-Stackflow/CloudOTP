import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Resources/theme_color_data.dart';
import 'package:cloudotp/Utils/lottie_util.dart';
import 'package:cloudotp/Widgets/Selectable/my_context_menu_item.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:group_button/group_button.dart';
import 'package:provider/provider.dart';

import '../../Resources/colors.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../Scaffold/my_appbar.dart';
import '../Selectable/my_selection_area.dart';
import '../Selectable/my_selection_toolbar.dart';
import '../Selectable/selection_transformer.dart';
import '../TextDrawable/text_drawable_widget.dart';

enum TailingType { none, clear, password, icon, text, widget }

class ItemBuilder {
  static PreferredSizeWidget buildSimpleAppBar({
    String title = "",
    Key? key,
    IconData leading = Icons.arrow_back_rounded,
    List<Widget>? actions,
    required BuildContext context,
    bool transparent = false,
  }) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    return MyAppBar(
      key: key,
      backgroundColor: transparent
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: showLeading ? 56.0 : 0.0,
      automaticallyImplyLeading: false,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: buildIconButton(
                context: context,
                icon: Icon(leading, color: Theme.of(context).iconTheme.color),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      title: title.isNotEmpty
          ? Container(
              margin: EdgeInsets.only(left: showLeading ? 5 : 20),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.apply(
                      fontWeightDelta: 2,
                    ),
              ),
            )
          : emptyWidget,
      actions: actions,
    );
  }

  static PreferredSizeWidget buildAppBar({
    Widget? title,
    Key? key,
    bool center = false,
    IconData? leading,
    Color? leadingColor,
    Function()? onLeadingTap,
    List<Widget>? actions,
    required BuildContext context,
    bool transparent = false,
    Color? backgroundColor,
    bool forceShowClose = false,
  }) {
    bool showLeading =
        leading != null && (!ResponsiveUtil.isLandscape() || forceShowClose);
    // center = ResponsiveUtil.isDesktop() ? false : center;
    return MyAppBar(
      key: key,
      backgroundColor: transparent
          ? Colors.transparent
          : backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: showLeading ? 56.0 : 0.0,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: buildIconButton(
                context: context,
                icon: Icon(leading,
                    color: leadingColor ?? Theme.of(context).iconTheme.color),
                onTap: onLeadingTap,
              ),
            )
          : null,
      title: center
          ? Center(
              child: Container(
                  margin: EdgeInsets.only(
                      left: center ? 0 : (showLeading ? 4 : 20)),
                  child: title))
          : Container(
              margin:
                  EdgeInsets.only(left: center ? 0 : (showLeading ? 4 : 20)),
              child: title,
            ),
      actions: actions,
    );
  }

  static buildSliverAppBar({
    required BuildContext context,
    Widget? backgroundWidget,
    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    Widget? title,
    bool center = false,
    double expandedHeight = 320,
    double? collapsedHeight,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    bool showLeading = !ResponsiveUtil.isLandscape();
    center = ResponsiveUtil.isLandscape() ? false : center;
    return MySliverAppBar(
      systemOverlayStyle: systemOverlayStyle,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight ??
          max(100, kToolbarHeight + MediaQuery.of(context).padding.top),
      pinned: true,
      leadingWidth: showLeading ? 56 : 0,
      leading: showLeading
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: ItemBuilder.buildIconButton(
                context: context,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      automaticallyImplyLeading: false,
      backgroundWidget: backgroundWidget,
      actions: actions,
      title: showLeading
          ? center
              ? Center(child: title)
              : title ?? emptyWidget
          : center
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: title,
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: title,
                ),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
    );
  }

  static buildGroupTile({
    required BuildContext context,
    required String title,
    required List<String> buttons,
    GroupButtonController? controller,
    EdgeInsets? padding,
    bool disabled = false,
    bool enableDeselect = false,
    Function(dynamic value, int index, bool isSelected)? onSelected,
  }) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: buildGroupButtons(
                buttons: buttons,
                disabled: disabled,
                controller: controller,
                enableDeselect: enableDeselect,
                onSelected: onSelected,
              ),
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
    bool disabled = false,
    Function(dynamic value, int index, bool isSelected)? onSelected,
  }) {
    return GroupButton(
      isRadio: true,
      enableDeselect: enableDeselect,
      options: const GroupButtonOptions(
        mainGroupAlignment: MainGroupAlignment.start,
      ),
      disabled: disabled,
      onSelected: onSelected,
      maxSelected: 1,
      controller: controller,
      buttons: buttons,
      buttonBuilder: (selected, label, context, onTap, disabled) {
        return SizedBox(
          width: 80,
          child: ItemBuilder.buildRoundButton(
            context,
            text: label,
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            background: selected
                ? disabled
                    ? Theme.of(context).primaryColor.withAlpha(80)
                    : Theme.of(context).primaryColor
                : null,
            textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                fontSizeDelta: 1, color: selected ? Colors.white : null),
          ),
        );
      },
    );
  }

  static buildLoadMoreNotification({
    Function()? onLoad,
    required Widget child,
    required bool noMore,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0) {
          return false;
        }
        if (!noMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - kLoadExtentOffset) {
          onLoad?.call();
        }
        return false;
      },
      child: child,
    );
  }

  static Widget buildBlankIconButton(BuildContext context) {
    return Visibility(
      visible: false,
      maintainAnimation: true,
      maintainState: true,
      maintainSize: true,
      child: ItemBuilder.buildIconButton(
          context: context,
          icon: Icon(Icons.more_vert_rounded,
              color: Theme.of(context).iconTheme.color),
          onTap: () {}),
    );
  }

  static Widget buildIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function()? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: icon ?? emptyWidget,
        ),
      ),
    );
  }

  static Widget buildRoundIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function()? onLongPress,
    Color? normalBackground,
    double radius = 8,
    EdgeInsets? padding,
    bool disabled = false,
  }) {
    return Material(
      color: disabled
          ? Colors.transparent
          : normalBackground ?? Colors.transparent,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: padding ?? const EdgeInsets.all(10),
          child: icon ?? emptyWidget,
        ),
      ),
    );
  }

  static Widget buildDynamicIconButton({
    required BuildContext context,
    required dynamic icon,
    required Function()? onTap,
    Function(BuildContext context, dynamic value, Widget? child)? onChangemode,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: Selector<AppProvider, ActiveThemeMode>(
        selector: (context, globalProvider) => globalProvider.themeMode,
        builder: (context, themeMode, child) {
          onChangemode?.call(context, themeMode, child);
          return buildIconButton(context: context, icon: icon, onTap: onTap);
        },
      ),
    );
  }

  static Widget buildRadioItem({
    double radius = 10,
    bool topRadius = false,
    bool bottomRadius = false,
    required bool value,
    Color? titleColor,
    bool showLeading = false,
    IconData leading = Icons.check_box_outline_blank,
    required String title,
    String description = "",
    Function()? onTap,
    double trailingLeftMargin = 5,
    double padding = 15,
    required BuildContext context,
    bool disabled = false,
  }) {
    assert(padding > 5);
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              bottomRadius ? Radius.circular(radius) : const Radius.circular(0),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.vertical(
            top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
            bottom: bottomRadius
                ? Radius.circular(radius)
                : const Radius.circular(0),
          ),
          border: ThemeColorData.isImmersive(context)
              ? Border.merge(
                  Border.symmetric(
                    vertical: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  Border(
                    top: topRadius
                        ? BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          )
                        : BorderSide.none,
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                )
              : const Border(),
        ),
        child: InkWell(
          borderRadius: BorderRadius.vertical(
              top: topRadius
                  ? Radius.circular(radius)
                  : const Radius.circular(0),
              bottom: bottomRadius
                  ? Radius.circular(radius)
                  : const Radius.circular(0)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: description.isNotEmpty ? padding : padding - 5,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible: showLeading,
                      child: Icon(leading, size: 20),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          description.isNotEmpty
                              ? Text(description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.apply(fontSizeDelta: 1))
                              : emptyWidget,
                        ],
                      ),
                    ),
                    SizedBox(width: trailingLeftMargin),
                    Opacity(
                      opacity: disabled ? 0.2 : 1,
                      child: Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: value,
                          onChanged: disabled
                              ? null
                              : (_) {
                                  HapticFeedback.lightImpact();
                                  if (onTap != null) onTap();
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ThemeColorData.isImmersive(context)
                  ? Container()
                  : Container(
                      height: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                            style: bottomRadius
                                ? BorderStyle.none
                                : BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildEntryItem({
    required BuildContext context,
    double radius = 10,
    bool topRadius = false,
    bool bottomRadius = false,
    bool showLeading = false,
    bool showTrailing = true,
    bool isCaption = false,
    Color? backgroundColor,
    Color? titleColor,
    Color? descriptionColor,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    IconData leading = Icons.home_filled,
    required String title,
    String tip = "",
    String description = "",
    Function()? onTap,
    double padding = 18,
    double trailingLeftMargin = 5,
    bool dividerPadding = true,
    IconData trailing = Icons.keyboard_arrow_right_rounded,
  }) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              bottomRadius ? Radius.circular(radius) : const Radius.circular(0),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).canvasColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.vertical(
            top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
            bottom: bottomRadius
                ? Radius.circular(radius)
                : const Radius.circular(0),
          ),
          border: ThemeColorData.isImmersive(context)
              ? Border.merge(
                  Border.symmetric(
                    vertical: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                  Border(
                    top: topRadius
                        ? BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          )
                        : BorderSide.none,
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                )
              : const Border(),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
            bottom: bottomRadius
                ? Radius.circular(radius)
                : const Radius.circular(0),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(vertical: padding, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible: showLeading,
                      child: Icon(leading, size: 20),
                    ),
                    showLeading
                        ? const SizedBox(width: 10)
                        : const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: crossAxisAlignment,
                        children: [
                          Text(
                            title,
                            style: isCaption
                                ? Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.apply(fontSizeDelta: 1)
                                : Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.apply(
                                      color: titleColor,
                                    ),
                          ),
                          description.isNotEmpty
                              ? Text(
                                  description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.apply(
                                        fontSizeDelta: 1,
                                        color: descriptionColor,
                                      ),
                                )
                              : emptyWidget,
                        ],
                      ),
                    ),
                    isCaption || tip.isEmpty
                        ? Container()
                        : const SizedBox(width: 50),
                    Text(
                      tip,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.apply(fontSizeDelta: 1),
                    ),
                    SizedBox(width: showTrailing ? trailingLeftMargin : 0),
                    Visibility(
                      visible: showTrailing,
                      child: Icon(
                        trailing,
                        size: 20,
                        color:
                            Theme.of(context).iconTheme.color?.withAlpha(127),
                      ),
                    ),
                  ],
                ),
              ),
              ThemeColorData.isImmersive(context)
                  ? Container()
                  : Container(
                      height: 0,
                      margin: EdgeInsets.symmetric(
                          horizontal: dividerPadding ? 10 : 0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                            style: bottomRadius
                                ? BorderStyle.none
                                : BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  static buildContextMenuOverlay(Widget child) {
    return ContextMenuOverlay(
      cardBuilder: (context, widgets) => Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).canvasColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ).scale(2)
          ],
        ),
        child: Column(
          children: widgets,
        ),
      ),
      dividerBuilder: (context) => ItemBuilder.buildDivider(
        context,
        width: 1.5,
        vertical: 6,
        horizontal: 4,
      ),
      buttonBuilder: (context, config, [_]) {
        return Material(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: config.onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (config.icon != null) config.icon!,
                  Text(
                    config.label,
                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                          color:
                              config.type == ContextMenuButtonConfigType.warning
                                  ? Colors.red
                                  : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  static Widget buildCaptionItem({
    required BuildContext context,
    double radius = 10,
    bool topRadius = true,
    bool bottomRadius = false,
    bool showLeading = false,
    bool showTrailing = true,
    IconData leading = Icons.home_filled,
    required String title,
    IconData trailing = Icons.keyboard_arrow_right_rounded,
  }) {
    return buildEntryItem(
      context: context,
      title: title,
      radius: radius,
      topRadius: topRadius,
      bottomRadius: bottomRadius,
      showTrailing: false,
      showLeading: showLeading,
      onTap: null,
      leading: leading,
      trailing: trailing,
      padding: 10,
      isCaption: true,
      dividerPadding: false,
    );
  }

  static Widget buildContainerItem({
    double radius = 10,
    bool topRadius = false,
    bool bottomRadius = false,
    required Widget child,
    required BuildContext context,
    Color? backgroundColor,
    EdgeInsets? padding,
    Border? border,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).canvasColor,
        borderRadius: BorderRadius.vertical(
          top: topRadius ? Radius.circular(radius) : const Radius.circular(0),
          bottom:
              bottomRadius ? Radius.circular(radius) : const Radius.circular(0),
        ),
        border: ThemeColorData.isImmersive(context)
            ? Border.merge(
                Border.symmetric(
                  vertical: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              )
            : border,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.05,
              style: bottomRadius ? BorderStyle.none : BorderStyle.solid,
            ),
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.05,
              style: topRadius ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  static Widget buildThemeItem({
    required ThemeColorData themeColorData,
    required int index,
    required int groupIndex,
    required BuildContext context,
    required Function(int?)? onChanged,
  }) {
    return Container(
      width: 107.3,
      height: 166.4,
      margin: EdgeInsets.only(left: index == 0 ? 10 : 0, right: 10),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 10, bottom: 0, left: 8, right: 8),
            decoration: BoxDecoration(
              color: themeColorData.background,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(
                color: themeColorData.dividerColor,
                style: BorderStyle.solid,
                width: 0.6,
              ),
            ),
            child: Column(
              children: [
                _buildCardRow(themeColorData),
                const SizedBox(height: 5),
                _buildCardRow(themeColorData),
                const SizedBox(height: 15),
                Radio(
                  value: index,
                  groupValue: groupIndex,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return themeColorData.primaryColor;
                    } else {
                      return themeColorData.textGrayColor;
                    }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            themeColorData.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyThemeItem({
    required BuildContext context,
    required Function()? onTap,
  }) {
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
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: BorderStyle.solid,
                width: 0.6,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Theme.of(context).textTheme.titleSmall?.color,
                ),
                const SizedBox(height: 6),
                Text("新建主题", style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Widget _buildCardRow(ThemeColorData themeColorData) {
    return Container(
      height: 35,
      width: 90,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: themeColorData.canvasBackground,
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
                  color: themeColorData.textGrayColor,
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

  static Widget buildInputItem({
    required BuildContext context,
    TextInputAction? textInputAction,
    IconData? leadingIcon,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TailingType tailingType = TailingType.none,
    String? tailingText,
    bool tailingEnable = true,
    IconData? tailingIcon,
    Function()? onTailingTap,
    Widget? tailingWidget,
    Widget? leadingWidget,
    String? leadingText,
    Color? backgroundColor,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    bool topRadius = false,
    bool bottomRadius = false,
    bool readOnly = false,
  }) {
    Widget? tailing;
    Function()? defaultTapFunction;
    if (tailingType == TailingType.clear) {
      tailing = Icon(Icons.clear_rounded,
          color: Theme.of(context).iconTheme.color?.withAlpha(120));
      defaultTapFunction = () {
        controller?.clear();
      };
    }
    if (tailingType == TailingType.password) {
      tailing = Icon(Icons.remove_red_eye_outlined,
          color: Theme.of(context).iconTheme.color?.withAlpha(120));
      defaultTapFunction = () {
        obscureText = !obscureText;
      };
    }
    if (tailingType == TailingType.icon && tailingIcon != null) {
      tailing = Icon(tailingIcon, color: Theme.of(context).iconTheme.color);
    }
    if (tailingType == TailingType.text && tailingText != null) {
      tailing = Text(
        tailingText,
        style: Theme.of(context).textTheme.titleSmall?.apply(
              color: tailingEnable
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.labelSmall?.color,
              fontWeightDelta: 2,
            ),
      );
    }
    if (tailingType == TailingType.widget && tailingWidget != null) {
      tailing = tailingWidget;
    }
    return Container(
      padding: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).canvasColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.vertical(
          top: topRadius ? const Radius.circular(10) : Radius.zero,
          bottom: bottomRadius ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (Utils.isNotEmpty(leadingText))
            Container(
              margin: const EdgeInsets.only(left: 10, right: 5),
              child: Text(
                leadingText!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (leadingWidget != null) leadingWidget,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                textInputAction: textInputAction,
                keyboardType: keyboardType,
                readOnly: readOnly,
                obscureText: obscureText,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  contentPadding: EdgeInsets.only(
                    top: leadingIcon != null ? 13.0 : 0,
                    left: leadingIcon != null ? 0 : 10,
                  ),
                  hintStyle: Theme.of(context).textTheme.titleSmall?.apply(
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  prefixIcon: leadingIcon != null
                      ? Icon(leadingIcon,
                          color: Theme.of(context).iconTheme.color)
                      : null,
                ),
                contextMenuBuilder: (contextMenuContext, details) =>
                    ItemBuilder.editTextContextMenuBuilder(
                        contextMenuContext, details,
                        context: context),
              ),
            ),
          ),
          if (tailing != null)
            GestureDetector(
              onTap: () {
                if (tailingEnable) {
                  onTailingTap?.call();
                  defaultTapFunction?.call();
                }
              },
              child:
                  MouseRegion(cursor: SystemMouseCursors.click, child: tailing),
            ),
        ],
      ),
    );
  }

  static Widget buildSmallIcon({
    required BuildContext context,
    required IconData icon,
    Function()? onTap,
    Color? backgroundColor,
  }) {
    return Material(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).canvasColor,
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon),
          ),
        ),
      ),
    );
  }

  static Widget buildTextDivider({
    required BuildContext context,
    required String text,
    double margin = 15,
    double width = 300,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: margin),
              height: 1,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: margin),
              height: 1,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyPlaceholder({
    required BuildContext context,
    required String text,
    double size = 50,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AssetUtil.load(
          AssetUtil.emptyIcon,
          size: size,
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  static buildTokenImage(OtpToken token, {double size = 80}) {
    if (Utils.isNotEmpty(token.imagePath)) {
      return Image.asset(
        token.imagePath,
        height: size,
        width: size,
        fit: BoxFit.contain,
      );
    } else {
      return TextDrawable(
        text: token.issuer,
        boxShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
        width: size,
        height: size,
      );
    }
  }

  static Widget buildTransparentTag(
    BuildContext context, {
    required String text,
    bool isCircle = false,
    int? width,
    int? height,
    double opacity = 0.4,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    double? fontSizeDelta,
    dynamic icon,
  }) {
    return Container(
      padding: isCircle
          ? padding ?? const EdgeInsets.all(5)
          : padding ?? const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        color: Colors.black.withOpacity(opacity),
        borderRadius: isCircle
            ? null
            : BorderRadius.all(Radius.circular(borderRadius ?? 50)),
      ),
      child: Row(
        children: [
          if (icon != null) icon,
          if (icon != null && Utils.isNotEmpty(text)) const SizedBox(width: 3),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.apply(
                  color: Colors.white,
                  fontSizeDelta: fontSizeDelta ?? -1,
                ),
          ),
        ],
      ),
    );
  }

  static Widget buildCopyItem(
    BuildContext context, {
    required Widget child,
    Function()? onTap,
    required String? copyText,
    String? toastText,
    bool condition = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (condition) {
          Utils.copy(context, copyText, toastText: toastText);
        }
      },
      child: child,
    );
  }

  static Widget buildDot(
    BuildContext context, {
    TextStyle? style,
  }) {
    return Text(
      " · ",
      style: style ??
          Theme.of(context).textTheme.titleSmall?.apply(fontWeightDelta: 2),
    );
  }

  static Widget buildLoadingDialog(
    BuildContext context, {
    double size = 50,
    bool showText = true,
    double topPadding = 0,
    double bottomPadding = 100,
    String? text,
    bool forceDark = false,
    Color? background,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        color: background ?? Theme.of(context).cardColor.withAlpha(127),
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieUtil.load(
              LottieUtil.getLoadingPath(context, forceDark: forceDark),
              size: size,
            ),
            if (showText) const SizedBox(height: 10),
            if (showText)
              Text(text ?? "正在加载...",
                  style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }

  static CachedNetworkImage buildCachedImage({
    required String imageUrl,
    required BuildContext context,
    BoxFit? fit,
    bool showLoading = true,
    double? width,
    double? height,
    Color? placeholderBackground,
    double topPadding = 0,
    double bottomPadding = 0,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      filterQuality: FilterQuality.high,
      placeholder: showLoading
          ? (context, url) => ItemBuilder.buildLoadingDialog(
                context,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
                showText: false,
                size: 40,
                background: placeholderBackground,
              )
          : (context, url) => Container(
                color: placeholderBackground ?? Theme.of(context).cardColor,
                width: width,
                height: height,
              ),
    );
  }

  static Widget buildRoundButton(
    BuildContext context, {
    String? text,
    Function()? onTap,
    Color? background,
    Icon? icon,
    EdgeInsets? padding,
    double radius = 50,
    Color? color,
    double fontSizeDelta = 0,
    TextStyle? textStyle,
    double? width,
  }) {
    return Material(
      color: background ?? Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickItem(
          clickable: onTap != null,
          Container(
            width: width,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) icon,
                Text(
                  text ?? "",
                  style: textStyle ??
                      Theme.of(context).textTheme.titleSmall?.apply(
                            color: color ??
                                (background != null
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.color),
                            fontWeightDelta: 2,
                            fontSizeDelta: fontSizeDelta,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildFramedButton(
    BuildContext context, {
    String? text,
    Function()? onTap,
    Color? outline,
    Icon? icon,
    EdgeInsets? padding,
    double radius = 50,
    Color? color,
    double fontSizeDelta = 0,
    TextStyle? textStyle,
    double? width,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickItem(
          clickable: onTap != null,
          Container(
            width: width,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                  color: outline ?? Theme.of(context).primaryColor, width: 1),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) icon,
                Text(
                  text ?? "",
                  style: textStyle ??
                      Theme.of(context).textTheme.titleSmall?.apply(
                            color: color ?? Theme.of(context).primaryColor,
                            fontWeightDelta: 2,
                            fontSizeDelta: fontSizeDelta,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildFramedDoubleButton({
    required BuildContext context,
    required bool isFollowed,
    required Function() onTap,
    String? positiveText,
    String? negtiveText,
    double radius = 50,
    Color? outline,
  }) {
    return Material(
      color: isFollowed ? Theme.of(context).cardColor : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: ItemBuilder.buildClickItem(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isFollowed
                    ? Theme.of(context).dividerColor
                    : outline ?? Theme.of(context).primaryColor.withAlpha(127),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  isFollowed ? positiveText ?? "已关注" : negtiveText ?? "关注",
                  style: TextStyle(
                    color: isFollowed
                        ? Theme.of(context).textTheme.labelSmall?.color
                        : Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildSearchBar({
    required BuildContext context,
    required hintText,
    required Null Function(dynamic value) onSubmitted,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AssetUtil.load(
            AssetUtil.searchDarkIcon,
            size: 20,
          ),
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  focusNode: focusNode,
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  contextMenuBuilder: (contextMenuContext, details) =>
                      ItemBuilder.editTextContextMenuBuilder(
                          contextMenuContext, details,
                          context: context),
                  onSubmitted: onSubmitted,
                  style: Theme.of(context).textTheme.titleSmall,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 8),
                    border:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                    hintText: hintText,
                    hintStyle: Theme.of(context).textTheme.titleSmall?.apply(
                        color: Theme.of(context).textTheme.labelSmall?.color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDesktopSearchBar({
    required BuildContext context,
    required hintText,
    required Function(dynamic value) onSubmitted,
    TextEditingController? controller,
    FocusNode? focusNode,
    Color? background,
    double borderRadius = 50,
    double? bottomMargin,
    double hintFontSizeDelta = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  focusNode: focusNode,
                  contextMenuBuilder: (contextMenuContext, details) =>
                      ItemBuilder.editTextContextMenuBuilder(
                          contextMenuContext, details,
                          context: context),
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: Theme.of(context).textTheme.titleSmall?.apply(
                        fontSizeDelta: hintFontSizeDelta,
                      ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 8),
                    border:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                    hintText: hintText,
                    hintStyle: Theme.of(context).textTheme.titleSmall?.apply(
                          color: Theme.of(context).textTheme.labelSmall?.color,
                          fontSizeDelta: hintFontSizeDelta,
                        ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onSubmitted(controller?.text);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AssetUtil.loadDouble(
                context,
                AssetUtil.searchLightIcon,
                AssetUtil.searchDarkIcon,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTitle(
    BuildContext context, {
    String? title,
    IconData? icon,
    String? suffixText,
    Function()? onTap,
    double topMargin = 8,
    double bottomMargin = 4,
    double left = 16,
    TextStyle? textStyle,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: left,
        right: Utils.isNotEmpty(suffixText) ? 8 : 16,
        top: topMargin,
        bottom: bottomMargin,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title ?? "",
              style: textStyle ??
                  Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.apply(fontWeightDelta: 2, fontSizeDelta: 1),
            ),
          ),
          if (icon != null)
            ItemBuilder.buildIconButton(
              context: context,
              icon: Icon(
                icon,
                size: 18,
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
              onTap: onTap,
            ),
          if (Utils.isNotEmpty(suffixText))
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    suffixText!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static buildDivider(
    BuildContext context, {
    double vertical = 8,
    double horizontal = 16,
    double? width,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
      height: width ?? 0.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  static buildStatisticItem(
    BuildContext context, {
    Color? labelColor,
    Color? countColor,
    int labelFontWeightDelta = 0,
    int countFontWeightDelta = 0,
    required String title,
    required int? count,
    Function()? onTap,
  }) {
    Map countWithScale = Utils.formatCountToMap(count ?? 0);
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              count != null
                  ? Row(
                      children: [
                        Text(
                          countWithScale['count'],
                          style: Theme.of(context).textTheme.titleLarge?.apply(
                              color: countColor,
                              fontWeightDelta: countFontWeightDelta),
                        ),
                        if (countWithScale.containsKey("scale"))
                          const SizedBox(width: 2),
                        if (countWithScale.containsKey("scale"))
                          Text(
                            countWithScale['scale'],
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.apply(
                                    fontSizeDelta: -2,
                                    color: countColor,
                                    fontWeightDelta: countFontWeightDelta),
                          ),
                      ],
                    )
                  : Text(
                      "-",
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                          color: countColor,
                          fontWeightDelta: countFontWeightDelta),
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.apply(
                      fontSizeDelta: -1,
                      color: labelColor,
                      fontWeightDelta: labelFontWeightDelta,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static buildIconTextButton(
    BuildContext context, {
    Axis direction = Axis.horizontal,
    double spacing = 2,
    Widget? icon,
    String text = "",
    double fontSizeDelta = 0,
    int fontWeightDelta = 0,
    bool showIcon = true,
    bool showText = true,
    Function()? onTap,
    Color? color,
    int quarterTurns = 0,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: direction == Axis.horizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null && showIcon)
                    RotatedBox(quarterTurns: quarterTurns, child: icon),
                  if (icon != null && showIcon) SizedBox(width: spacing),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.titleSmall?.apply(
                          fontSizeDelta: fontSizeDelta,
                          color: color,
                          fontWeightDelta: fontWeightDelta,
                        ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null && showIcon)
                    RotatedBox(
                        quarterTurns: quarterTurns,
                        child: ItemBuilder.buildIconButton(
                            context: context, icon: icon, onTap: onTap)),
                  if (icon != null && showIcon) SizedBox(height: spacing),
                  if (showText)
                    Text(
                      text,
                      style: Theme.of(context).textTheme.titleSmall?.apply(
                            fontSizeDelta: fontSizeDelta,
                            color: color,
                            fontWeightDelta: fontWeightDelta,
                          ),
                    ),
                ],
              ),
      ),
    );
  }

  static Widget buildWrapTagList(
    BuildContext context,
    List<String> list, {
    Function(String)? onTap,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: List.generate(list.length, (index) {
          return buildWrapTagItem(context, list[index], onTap: onTap);
        }),
      ),
    );
  }

  static Widget buildWrapTagItem(
    BuildContext context,
    String str, {
    Function(String)? onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onTap?.call(str);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Text(
            str,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  static Tab buildAnimatedTab(
    BuildContext context, {
    required bool selected,
    required String text,
    bool normalUserBold = false,
    bool sameFontSize = false,
    double fontSizeDelta = 0,
  }) {
    TextStyle normalStyle = Theme.of(context).textTheme.titleLarge!.apply(
          color: Colors.grey,
          fontSizeDelta: fontSizeDelta - (sameFontSize ? 0 : 1),
          fontWeightDelta: normalUserBold ? 0 : -2,
        );
    TextStyle selectedStyle = Theme.of(context).textTheme.titleLarge!.apply(
          fontSizeDelta: fontSizeDelta + (sameFontSize ? 0 : 1),
        );
    return Tab(
      child: AnimatedDefaultTextStyle(
        style: selected ? selectedStyle : normalStyle,
        duration: const Duration(milliseconds: 100),
        child: Container(
          alignment: Alignment.center,
          child: Text(text),
        ),
      ),
    );
  }

  static buildSelectableArea({
    required BuildContext context,
    required Widget child,
  }) {
    return MySelectionArea(
      contextMenuBuilder: (contextMenuContext, details) {
        Map<ContextMenuButtonType, String> typeToString = {
          ContextMenuButtonType.copy: "复制",
          ContextMenuButtonType.cut: "剪切",
          ContextMenuButtonType.paste: "粘贴",
          ContextMenuButtonType.selectAll: "全选",
          ContextMenuButtonType.searchWeb: "选择",
          ContextMenuButtonType.share: "分享",
          ContextMenuButtonType.lookUp: "搜索",
          ContextMenuButtonType.delete: "删除",
          ContextMenuButtonType.liveTextInput: "输入",
          ContextMenuButtonType.custom: "自定义",
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
                  if (e.type == ContextMenuButtonType.copy) {
                    IToast.showTop("已复制到剪贴板");
                  }
                },
              ),
            );
          }
        }
        if (ResponsiveUtil.isMobile()) {
          return MyMobileTextSelectionToolbar.items(
            anchorAbove: details.contextMenuAnchors.primaryAnchor,
            anchorBelow: details.contextMenuAnchors.primaryAnchor,
            backgroundColor: Theme.of(context).canvasColor,
            dividerColor: Theme.of(context).dividerColor,
            items: items,
            itemBuilder: (MyContextMenuItem item) {
              return Text(
                item.label ?? "",
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          );
        } else {
          return MyDesktopTextSelectionToolbar(
            anchor: details.contextMenuAnchors.primaryAnchor,
            backgroundColor: Theme.of(context).canvasColor,
            dividerColor: Theme.of(context).dividerColor,
            items: items,
          );
        }
      },
      child: SelectionTransformer.separated(
        child: child,
      ),
    );
  }

  static Widget editTextContextMenuBuilder(
    contextMenuContext,
    EditableTextState details, {
    required BuildContext context,
  }) {
    Map<ContextMenuButtonType, String> typeToString = {
      ContextMenuButtonType.copy: "复制",
      ContextMenuButtonType.cut: "剪切",
      ContextMenuButtonType.paste: "粘贴",
      ContextMenuButtonType.selectAll: "全选",
      ContextMenuButtonType.searchWeb: "选择",
      ContextMenuButtonType.share: "分享",
      ContextMenuButtonType.lookUp: "搜索",
      ContextMenuButtonType.delete: "删除",
      ContextMenuButtonType.liveTextInput: "输入",
      ContextMenuButtonType.custom: "自定义",
    };
    List<MyContextMenuItem> items = [];
    int start = details.textEditingValue.selection.start <= -1
        ? 0
        : details.textEditingValue.selection.start;
    int end = details.textEditingValue.selection.end
        .clamp(0, details.textEditingValue.text.length);
    String selectedText = details.textEditingValue.text.substring(start, end);
    for (var e in details.contextMenuButtonItems) {
      if (e.type != ContextMenuButtonType.custom) {
        items.add(
          MyContextMenuItem(
            label: typeToString[e.type] ?? "",
            type: e.type,
            onPressed: () {
              e.onPressed?.call();
              if (e.type == ContextMenuButtonType.copy) {
                IToast.showTop("已复制到剪贴板");
              }
            },
          ),
        );
      }
    }
    if (ResponsiveUtil.isMobile()) {
      return MyMobileTextSelectionToolbar.items(
        anchorAbove: details.contextMenuAnchors.primaryAnchor,
        anchorBelow: details.contextMenuAnchors.primaryAnchor,
        backgroundColor: Theme.of(contextMenuContext).canvasColor,
        dividerColor: Theme.of(contextMenuContext).dividerColor,
        items: items,
        itemBuilder: (MyContextMenuItem item) {
          return Text(
            item.label ?? "",
            style: Theme.of(contextMenuContext).textTheme.titleMedium,
          );
        },
      );
    } else {
      return MyDesktopTextSelectionToolbar(
        anchor: details.contextMenuAnchors.primaryAnchor,
        backgroundColor: Theme.of(contextMenuContext).canvasColor,
        dividerColor: Theme.of(contextMenuContext).dividerColor,
        items: items,
      );
    }
  }

  static buildHtmlWidget(
    BuildContext context,
    String content, {
    TextStyle? textStyle,
    bool enableImageDetail = true,
    bool parseImage = true,
    bool showLoading = true,
    Function()? onDownloadSuccess,
  }) {
    return ItemBuilder.buildSelectableArea(
      context: context,
      child: HtmlWidget(
        content,
        enableCaching: true,
        renderMode: RenderMode.column,
        textStyle: textStyle ??
            Theme.of(context)
                .textTheme
                .bodyMedium
                ?.apply(fontSizeDelta: 3, heightDelta: 0.3),
        factoryBuilder: () {
          return CustomImageFactory();
        },
        customStylesBuilder: (e) {
          if (e.attributes.containsKey('href')) {
            return {
              'color':
                  '#${MyColors.getLinkColor(context).value.toRadixString(16).substring(2, 8)}',
              'font-weight': '700',
              'text-decoration-line': 'none',
            };
          } else if (e.id == "title") {
            return {
              'font-weight': '700',
              'font-size': 'larger',
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
                    context,
                    text: "加载中...",
                    size: 40,
                    bottomPadding: 30,
                    topPadding: 30,
                  ),
                );
              }
            : null,
      ),
    );
  }

  static buildClickItem(
    Widget child, {
    bool clickable = true,
  }) {
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: child,
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