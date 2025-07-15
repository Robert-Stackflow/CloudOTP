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
import 'dart:ui';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Screens/Backup/cloud_service_screen.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/backup_log_screen.dart';
import 'package:cloudotp/Screens/Setting/mobile_setting_navigation_screen.dart';
import 'package:cloudotp/Screens/main_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/add_bottom_sheet.dart';
import 'package:cloudotp/Widgets/cloudotp/cloudotp_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:provider/provider.dart';

import '../Database/token_dao.dart';
import '../Models/token_category.dart';
import '../Utils/app_provider.dart';
import '../Widgets/BottomSheet/select_token_bottom_sheet.dart';
import '../generated/l10n.dart';
import 'Token/category_screen.dart';
import 'Token/token_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  static const String routeName = "/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BasePanelScreenState<HomeScreen>
    with TickerProviderStateMixin {
  LayoutType layoutType = CloudOTPHiveUtil.getLayoutType();
  OrderType orderType = CloudOTPHiveUtil.getOrderType();
  List<OtpToken> tokens = [];
  List<TokenCategory> categories = [];

  List<Tab> tabList = [];
  int _currentTabIndex = 0;
  String _searchKey = "";
  Map<String, GlobalKey<TokenLayoutState>> tokenKeyMap = {};
  late TabController _tabController;
  ScrollController _scrollController = ScrollController();
  final ScrollController _nestScrollController = ScrollController();
  final ScrollToHideController _fabScrollToHideController =
      ScrollToHideController();
  final ScrollToHideController _bottombarScrollToHideController =
      ScrollToHideController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _marqueeController = PageController();
  late AnimationController _animationController;
  GridItemsNotifier gridItemsNotifier = GridItemsNotifier();
  final ValueNotifier<bool> _shownSearchbarNotifier = ValueNotifier(false);

  bool get hasSearchFocus => appProvider.searchFocusNode.hasFocus;

  String get currentCategoryUid {
    if (_currentTabIndex == 0) {
      return "";
    } else {
      if (_currentTabIndex - 1 < 0 ||
          _currentTabIndex - 1 >= categories.length) {
        return "";
      }
      return categories[_currentTabIndex - 1].uid;
    }
  }

  @override
  void initState() {
    super.initState();
    initTab(true);
    refresh(true);
    _searchController.addListener(() {
      performSearch(_searchController.text);
    });
    _animationController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!ResponsiveUtil.isLandscape() &&
          ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoFocusSearchBarKey,
              defaultValue: false)) {
        changeSearchBar(true);
      }
    });
  }

  insertToken(
    OtpToken token, {
    bool forceAll = false,
  }) async {
    if (currentCategoryUid.isEmpty) {
      if (!forceAll) {
        return;
      }
    } else {
      if (!(await BindingDao.getCategoryUids(token.uid))
          .contains(currentCategoryUid)) {
        return;
      }
    }
    int calculateInsertIndex = 0;
    switch (orderType) {
      case OrderType.Default:
        calculateInsertIndex = 0;
        break;
      case OrderType.AlphabeticalASC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.issuer.compareTo(token.issuer) > 0);
        break;
      case OrderType.AlphabeticalDESC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.issuer.compareTo(token.issuer) < 0);
        break;
      case OrderType.CopyTimesDESC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.copyTimes.compareTo(token.copyTimes) < 0);
        break;
      case OrderType.CopyTimesASC:
        calculateInsertIndex = tokens.indexWhere(
            (element) => element.copyTimes.compareTo(token.copyTimes) > 0);
        break;
      case OrderType.LastCopyTimeDESC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.lastCopyTimeStamp.compareTo(token.lastCopyTimeStamp) < 0);
        break;
      case OrderType.LastCopyTimeASC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.lastCopyTimeStamp.compareTo(token.lastCopyTimeStamp) > 0);
        break;
      case OrderType.CreateTimeDESC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.createTimeStamp.compareTo(token.createTimeStamp) < 0);
        break;
      case OrderType.CreateTimeASC:
        calculateInsertIndex = tokens.indexWhere((element) =>
            element.createTimeStamp.compareTo(token.createTimeStamp) > 0);
        break;
    }
    int pinnedCount = tokens.where((e) => e.pinned).toList().length;
    calculateInsertIndex += pinnedCount;
    calculateInsertIndex = calculateInsertIndex.clamp(0, tokens.length);
    tokens.insert(calculateInsertIndex, token);
    gridItemsNotifier.notifyItemInserted?.call(calculateInsertIndex, () {
      setState(() {});
    });
  }

  updateToken(
    OtpToken token, {
    bool pinnedStateChanged = false,
    bool counterChanged = false,
  }) {
    int updateIndex = tokens.indexWhere((element) => element.uid == token.uid);
    tokens[updateIndex] = token;
    tokenKeyMap
        .putIfAbsent(token.uid, () => GlobalKey())
        .currentState
        ?.updateInfo(counterChanged: counterChanged);
    if (pinnedStateChanged) performSort();
  }

  removeToken(OtpToken token) {
    int removeIndex = tokens.indexWhere((element) => element.uid == token.uid);
    if (removeIndex != -1) tokens.removeAt(removeIndex);
    gridItemsNotifier.notifyItemRemoved?.call(removeIndex, () {
      setState(() {});
    });
  }

  changeCategoriesForToken(OtpToken token, List<String> unselectedCategoryUids,
      List<String> selectedCategorUids) {
    if (unselectedCategoryUids.contains(currentCategoryUid)) {
      removeToken(token);
    }
    if (selectedCategorUids.contains(currentCategoryUid)) {
      insertToken(token);
    }
  }

  changeTokensForCategory(TokenCategory category) {
    if (category.uid == currentCategoryUid && currentCategoryUid.isNotEmpty) {
      getTokens();
    }
  }

  refreshCategories() async {
    await getCategories();
  }

  refresh([bool isInit = false]) async {
    if (!mounted) return;
    await getCategories(isInit);
    await getTokens();
  }

  getTokens() async {
    await CategoryDao.getTokensByCategoryUid(
      currentCategoryUid,
      searchKey: _searchKey,
    ).then((value) {
      tokens = value;
      performSort();
    });
  }

  getCategories([bool isInit = false]) async {
    String oldUid = currentCategoryUid;
    await CategoryDao.listCategories().then((value) async {
      categories = value;
      List<String> uids = categories.map((e) => e.uid).toList();
      if (!uids.contains(oldUid)) {
        _currentTabIndex = 0;
        await getTokens();
      } else {
        _currentTabIndex = uids.indexOf(oldUid) + 1;
      }
      initTab(isInit);
      setState(() {});
    });
  }

  initTab([bool isInit = false]) {
    tabList.clear();
    tabList.add(_buildTab(null));
    String categoryUid = CloudOTPHiveUtil.getSelectedCategoryId();
    for (var category in categories) {
      tabList.add(_buildTab(category));
      if (category.uid == categoryUid && isInit) {
        _currentTabIndex = categories.indexOf(category) + 1;
      }
    }
    setState(() {});
    _tabController = TabController(length: tabList.length, vsync: this);
    _tabController.index = _currentTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      appBar: ResponsiveUtil.isLandscape()
          ? ResponsiveAppBar(
              titleLeftMargin: 10,
              titleWidget: Container(
                constraints: const BoxConstraints(
                    maxWidth: 300, minWidth: 200, maxHeight: 36),
                child: MySearchBar(
                  borderRadius: 8,
                  bottomMargin: 18,
                  focusNode: appProvider.searchFocusNode,
                  controller: _searchController,
                  background: ChewieTheme.scaffoldBackgroundColor,
                  hintText: S.current.searchToken,
                  onSubmitted: (text) {
                    performSearch(text);
                  },
                ),
              ),
            )
          : null,
      body: ResponsiveUtil.buildLandscapeWidget(
        landscape: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabBar(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
        portrait: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) {
            if (mounted && _shownSearchbarNotifier.value) {
              changeSearchBar(false);
            } else {
              MoveToBackground.moveTaskToBack();
            }
          },
          child: _buildMobileBody(),
        ),
      ),
      bottomNavigationBar: ResponsiveUtil.buildDesktopWidget(
        mobile: _buildMobileBottombar(),
      ),
      floatingActionButton: ResponsiveUtil.buildDesktopWidget(
        mobile: _buildFloatingActionButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      extendBody: true,
    );
  }

  _buildMobileBody() {
    return NestedScrollView(
      controller: _nestScrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildMobileAppbar(),
        ];
      },
      body: Builder(
        builder: (context) {
          _scrollController = PrimaryScrollController.of(context);
          return _buildMainContent();
        },
      ),
    );
  }

  changeSearchBar(bool shown) {
    Future.delayed(const Duration(milliseconds: 200), () {
      _shownSearchbarNotifier.value = shown;
    });
    _marqueeController.animateToPage(shown ? 1 : 0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    if (shown) {
      appProvider.searchFocusNode.requestFocus();
      _animationController.reverse();
    } else {
      _searchController.clear();
      appProvider.searchFocusNode.unfocus();
      _animationController.forward();
    }
  }

  _buildFloatingActionButton() {
    var button = MyFloatingActionButton(
      heroTag: "Hero-${categories.length}",
      onPressed: () {
        BottomSheetBuilder.showBottomSheet(
          chewieProvider.rootContext,
          enableDrag: false,
          responsive: true,
          (context) => AddBottomSheet(
            onlyShowScanner: ResponsiveUtil.isLandscapeTablet(),
          ),
        );
      },
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: ChewieTheme.primaryColor,
      child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 28),
    );
    return Selector<AppProvider, bool>(
      selector: (context, provider) => provider.hideBottombarWhenScrolling,
      builder: (context, hideBottombarWhenScrolling, child) => ScrollToHide(
        enabled: hideBottombarWhenScrolling || categories.isEmpty,
        scrollController: _scrollController,
        controller: _fabScrollToHideController,
        height: kToolbarHeight,
        duration: const Duration(milliseconds: 300),
        hideDirection: Axis.vertical,
        child: button,
      ),
    );
  }

  getActions(AppProvider provider) {
    return [
      if (provider.showBackupLogButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: CircleIconButton(
            padding: EdgeInsets.zero,
            icon: Selector<AppProvider, LoadingStatus>(
              selector: (context, appProvider) =>
                  appProvider.autoBackupLoadingStatus,
              builder: (context, autoBackupLoadingStatus, child) => LoadingIcon(
                status: autoBackupLoadingStatus,
                normalIcon: Icon(Icons.history_rounded,
                    color: ChewieTheme.iconColor),
              ),
            ),
            onTap: () {
              RouteUtil.pushCupertinoRoute(context, const BackupLogScreen());
            },
          ),
        ),
      if (provider.canShowCloudBackupButton && provider.showCloudBackupButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: CircleIconButton(
            icon: Icon(
              LucideIcons.cloud,
              color: ChewieTheme.iconColor,
            ),
            onTap: () {
              RouteUtil.pushCupertinoRoute(context, const CloudServiceScreen());
            },
          ),
        ),
      if (provider.showLayoutButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: ToolButton(
            context: context,
            icon: layoutType.icon,
            onPressed: () {
              BottomSheetBuilder.showContextMenu(
                context,
                MainScreenState.buildLayoutContextMenuButtons(),
              );
            },
          ),
        ),
      if (provider.showSortButton)
        Container(
          margin: const EdgeInsets.only(right: 5),
          child: ToolButton(
            context: context,
            icon: orderType.icon,
            onPressed: () {
              BottomSheetBuilder.showContextMenu(
                context,
                MainScreenState.buildSortContextMenuButtons(),
              );
            },
          ),
        ),
      ToolButton(
        context: context,
        icon: LucideIcons.ellipsisVertical,
        onPressed: () {
          BottomSheetBuilder.showContextMenu(
            context,
            FlutterContextMenu(
              entries: [
                FlutterContextMenuItem(
                  S.current.category,
                  iconData: LucideIcons.shapes,
                  onPressed: () {
                    RouteUtil.pushCupertinoRoute(
                        context, const CategoryScreen());
                  },
                ),
                FlutterContextMenuItem(
                  S.current.setting,
                  iconData: LucideIcons.bolt,
                  onPressed: () {
                    RouteUtil.pushCupertinoRoute(
                        context, const MobileSettingNavigationScreen());
                  },
                ),
                FlutterContextMenuItem(
                  S.current.about,
                  iconData: LucideIcons.info,
                  onPressed: () {
                    RouteUtil.pushCupertinoRoute(
                        context, const AboutSettingScreen());
                  },
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(width: 5),
    ];
  }

  _buildMobileAppbar() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) => ValueListenableBuilder(
        valueListenable: _shownSearchbarNotifier,
        builder: (context, shownSearchbar, child) =>
            CloudOTPItemBuilder.buildSliverAppBar(
          context: context,
          useBackdropFilter: provider.enableFrostedGlassEffect,
          floating: provider.hideAppbarWhenScrolling,
          pinned: !provider.hideAppbarWhenScrolling,
          backgroundColor: Theme.of(context)
              .scaffoldBackgroundColor
              .withOpacity(provider.enableFrostedGlassEffect ? 0.2 : 1),
          title: SizedBox(
            height: kToolbarHeight,
            child: MarqueeWidget(
              count: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        if (!_shownSearchbarNotifier.value) {
                          changeSearchBar(true);
                        }
                      },
                      child: Text(
                        ResponsiveUtil.appName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .apply(fontWeightDelta: 2),
                      ),
                    ),
                  );
                } else {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(right: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleIconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: ChewieTheme.iconColor,
                            ),
                            onTap: () {
                              changeSearchBar(false);
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InputItem(
                              hint: S.current.searchToken,
                              onSubmit: (text) {
                                performSearch(text);
                              },
                              style: InputItemStyle(
                                backgroundColor: Colors.transparent,
                                bottomMargin: 0,
                                topMargin: 0,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              focusNode: appProvider.searchFocusNode,
                              controller: _searchController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              autoPlay: false,
              controller: _marqueeController,
            ),
          ),
          expandedHeight: kToolbarHeight,
          collapsedHeight: kToolbarHeight,
          actions: _shownSearchbarNotifier.value ? [] : getActions(provider),
        ),
      ),
    );
  }

  _buildMobileBottombar({double verticalPadding = 10}) {
    double height = kToolbarHeight +
        verticalPadding * 2 +
        (ResponsiveUtil.isLandscapeTablet() ? 24 : 0);
    return Selector<AppProvider, bool>(
      selector: (context, provider) => provider.hideBottombarWhenScrolling,
      builder: (context, hideBottombarWhenScrolling, child) =>
          Selector<AppProvider, bool>(
        selector: (context, provider) => provider.enableFrostedGlassEffect,
        builder: (context, enableFrostedGlassEffect, child) {
          var container = Container(
            alignment: Alignment.centerLeft,
            height: height,
            decoration: BoxDecoration(
              color: ChewieTheme.scaffoldBackgroundColor
                  .withOpacity(enableFrostedGlassEffect ? 0.2 : 1),
              boxShadow: [
                BoxShadow(
                  color: ChewieTheme.shadowColor,
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
              // border: ChewieTheme.topDivider,
            ),
            padding: EdgeInsets.symmetric(vertical: 5 + verticalPadding)
                .copyWith(right: 70),
            child: _buildTabBar(const EdgeInsets.only(left: 10, right: 10)),
          );
          return ScrollToHide(
            enabled: hideBottombarWhenScrolling,
            scrollController: _scrollController,
            controller: _bottombarScrollToHideController,
            height: height,
            duration: const Duration(milliseconds: 300),
            hideDirection: Axis.vertical,
            child: ResponsiveUtil.isLandscapeTablet() || categories.isEmpty
                ? IgnorePointer(
                    child: Container(
                      height: height,
                      decoration: const BoxDecoration(color: Color(0x00ffffff)),
                    ),
                  )
                : enableFrostedGlassEffect
                    ? ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: container,
                        ),
                      )
                    : container,
          );
        },
      ),
    );
  }

  _buildMainContent() {
    Widget gridView = Selector<AppProvider, bool>(
      selector: (context, provider) => provider.dragToReorder,
      builder: (context, dragToReorder, child) => Selector<AppProvider, bool>(
        selector: (context, provider) => provider.hideBottombarWhenScrolling,
        builder: (context, hideBottombarWhenScrolling, child) =>
            Selector<AppProvider, bool>(
          selector: (context, provider) => provider.hideProgressBar,
          builder: (context, hideProgressBar, child) =>
              ReorderableGridView.builder(
            // controller: _scrollController,
            gridItemsNotifier: gridItemsNotifier,
            autoScroll: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: 10,
                bottom:
                    hideBottombarWhenScrolling || categories.isEmpty ? 10 : 85),
            gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: layoutType.maxCrossAxisExtent,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              preferredHeight: layoutType.getHeight(hideProgressBar),
            ),
            dragToReorder: dragToReorder,
            cacheExtent: 9999,
            // itemDragEnable: (index) {
            //   if (tokens[index].pinnedInt == 1) {
            //     return false;
            //   }
            //   return true;
            // },
            onReorderStart: (_) {
              _fabScrollToHideController.hide();
              _bottombarScrollToHideController.hide();
            },
            onReorderEnd: (_, __) {
              _fabScrollToHideController.show();
              _bottombarScrollToHideController.show();
            },
            onReorder: (int oldIndex, int newIndex) async {
              final selectedToken = tokens[oldIndex];
              int pinnedCount = tokens.where((e) => e.pinned).length;
              if (selectedToken.pinned) {
                if (newIndex >= pinnedCount) newIndex = pinnedCount - 1;
              } else {
                if (newIndex < pinnedCount) newIndex = pinnedCount;
              }
              final item = tokens.removeAt(oldIndex);
              tokens.insert(newIndex, item);
              for (int i = 0; i < tokens.length; i++) {
                tokens[i].seq = tokens.length - i;
              }
              await TokenDao.updateTokens(tokens, autoBackup: false);
              changeOrderType(type: OrderType.Default, doPerformSort: false);
            },
            proxyDecorator:
                (Widget child, int index, Animation<double> animation) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(chewieProvider.rootContext).shadowColor,
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ).scale(2)
                  ],
                ),
                child: child,
              );
            },
            itemCount: tokens.length,
            itemBuilder: (context, index) {
              return TokenLayout(
                key: tokenKeyMap.putIfAbsent(
                    tokens[index].uid, () => GlobalKey()),
                token: tokens[index],
                layoutType: layoutType,
              );
            },
          ),
        ),
      ),
    );
    Widget body = tokens.isEmpty
        ? ListView(
            padding: const EdgeInsets.symmetric(vertical: 50),
            children: [
              EmptyPlaceholder(
                text: _searchKey.isEmpty
                    ? S.current.noToken
                    : S.current.noTokenContainingSearchKey(_searchKey),
              ),
            ],
          )
        : gridView;
    return SlidableAutoCloseBehavior(child: body);
  }

  _buildTabBar([EdgeInsetsGeometry? padding]) {
    return TabBar(
      controller: _tabController,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: tabList,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      isScrollable: true,
      dividerHeight: 0,
      padding: padding,
      tabAlignment: TabAlignment.start,
      physics: const ClampingScrollPhysics(),
      labelStyle:
          Theme.of(context).textTheme.titleMedium?.apply(fontWeightDelta: 2),
      unselectedLabelStyle:
          Theme.of(context).textTheme.titleMedium?.apply(color: Colors.grey),
      indicator: UnderlinedTabIndicator(
        borderColor: ChewieTheme.primaryColor,
      ),
      onTap: (index) {
        if (_nestScrollController.hasClients) {
          _nestScrollController.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }
        _currentTabIndex = index;
        getTokens();
        CloudOTPHiveUtil.setSelectedCategoryUid(currentCategoryUid);
      },
    );
  }

  _buildTab(TokenCategory? category) {
    // {
    // bool normalUserBold = false,
    // bool sameFontSize = false,
    // double fontSizeDelta = 0,
    // }) {
    // TextStyle normalStyle = Theme.of(context).textTheme.titleLarge!.apply(
    //       color: Colors.grey,
    //       fontSizeDelta: fontSizeDelta - (sameFontSize ? 0 : 1),
    //       fontWeightDelta: normalUserBold ? 0 : -2,
    //     );
    // TextStyle selectedStyle = Theme.of(context).textTheme.titleLarge!.apply(
    //       fontSizeDelta: fontSizeDelta + (sameFontSize ? 0 : 1),
    //     );
    return Tab(
      child: ContextMenuRegion(
        contextMenu: _buildTabContextMenuButtons(category),
        child: GestureDetector(
          onLongPress: () {
            if (category != null) {
              HapticFeedback.lightImpact();
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => SelectTokenBottomSheet(category: category),
              );
            }
          },
          // child: AnimatedDefaultTextStyle(
          //   style: (category == null
          //           ? _currentTabIndex == 0
          //           : currentCategoryId == category.id)
          //       ? selectedStyle
          //       : normalStyle,
          //   duration: const Duration(milliseconds: 100),
          //   child: Container(
          //     alignment: Alignment.center,
          child: Text(category?.title ?? S.current.allTokens),
        ),
        // ),
        // ),
      ),
    );
  }

  processEditCategory(TokenCategory category) {
    InputValidateAsyncController validateAsyncController =
        InputValidateAsyncController(
      validator: (text) async {
        if (text.isEmpty) {
          return S.current.categoryNameCannotBeEmpty;
        }
        if (text != category.title && await CategoryDao.isCategoryExist(text)) {
          return S.current.categoryNameDuplicate;
        }
        return null;
      },
      controller: TextEditingController(),
    );
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      useWideLandscape: true,
      (context) => InputBottomSheet(
        title: S.current.editCategoryName,
        hint: S.current.inputCategory,
        style: InputItemStyle(
          maxLength: 32,
        ),
        text: category.title,
        validator: (text) {
          if (text.isEmpty) {
            return S.current.categoryNameCannotBeEmpty;
          }
          return null;
        },
        validateAsyncController: validateAsyncController,
        onValidConfirm: (text) async {
          category.title = text;
          await CategoryDao.updateCategory(category);
          refreshCategories();
        },
      ),
    );
  }

  static addCategory(
    BuildContext context, {
    Function(TokenCategory)? onAdded,
  }) async {
    InputValidateAsyncController validateAsyncController =
        InputValidateAsyncController(
      validator: (text) async {
        if (text.isEmpty) {
          return S.current.categoryNameCannotBeEmpty;
        }
        if (await CategoryDao.isCategoryExist(text)) {
          return S.current.categoryNameDuplicate;
        }
        return null;
      },
      controller: TextEditingController(),
    );
    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      useWideLandscape: true,
      (context) => InputBottomSheet(
        title: S.current.addCategory,
        hint: S.current.inputCategory,
        validator: (text) {
          if (text.isEmpty) {
            return S.current.categoryNameCannotBeEmpty;
          }
          return null;
        },
        checkSyncValidator: false,
        validateAsyncController: validateAsyncController,
        style: InputItemStyle(
          maxLength: 32,
        ),
        onValidConfirm: (text) async {
          TokenCategory category = TokenCategory.title(title: text);
          await CategoryDao.insertCategory(category);
          homeScreenState?.refreshCategories();
          onAdded?.call(category);
          return true;
        },
      ),
    );
  }

  _buildTabContextMenuButtons(TokenCategory? category) {
    if (category == null) {
      return FlutterContextMenu(
        entries: [
          FlutterContextMenuItem(
            S.current.addCategory,
            onPressed: () {
              addCategory(context);
            },
          ),
        ],
      );
    }
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(S.current.editCategoryName, onPressed: () {
          processEditCategory(category);
        }),
        FlutterContextMenuItem(S.current.editCategoryTokens, onPressed: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            responsive: true,
            (context) => SelectTokenBottomSheet(category: category),
          );
        }),
        FlutterContextMenuItem.divider(),
        FlutterContextMenuItem(S.current.addCategory, onPressed: () {
          addCategory(context);
        }),
        FlutterContextMenuItem(
          S.current.deleteCategory,
          status: MenuItemStatus.warning,
          onPressed: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: S.current.deleteCategory,
              message: S.current.deleteCategoryHint(category.title),
              confirmButtonText: S.current.confirm,
              cancelButtonText: S.current.cancel,
              onTapConfirm: () async {
                await CategoryDao.deleteCategory(category);
                IToast.showTop(S.current.deleteCategorySuccess(category.title));
                refreshCategories();
              },
              onTapCancel: () {},
            );
          },
        ),
      ],
    );
  }

  unfocusSearch() {
    appProvider.searchFocusNode.unfocus();
    appProvider.shortcutFocusNode.unfocus();
  }

  performSearch(String searchKey) {
    _searchKey = searchKey;
    getTokens();
  }

  changeLayoutType([LayoutType? type]) {
    setState(() {
      if (type != null) {
        layoutType = type;
      } else {
        layoutType = layoutType == LayoutType.values.last
            ? LayoutType.Simple
            : LayoutType.values[layoutType.index + 1];
      }
      CloudOTPHiveUtil.setLayoutType(layoutType);
    });
    mainScreenState?.refresh();
  }

  changeOrderType({
    bool doPerformSort = true,
    OrderType? type,
  }) {
    setState(() {
      if (type != null) {
        orderType = type;
      } else {
        orderType = orderType == OrderType.CreateTimeASC
            ? OrderType.Default
            : OrderType.values[orderType.index + 1];
      }
      CloudOTPHiveUtil.setOrderType(orderType);
    });
    if (doPerformSort) performSort();
    mainScreenState?.refresh();
  }

  resetCopyTimesSingle(OtpToken token) {
    int updateIndex = tokens.indexWhere((element) => element.uid == token.uid);
    tokens[updateIndex].copyTimes = 0;
    tokens[updateIndex].lastCopyTimeStamp = 0;
    if (orderType == OrderType.CopyTimesDESC ||
        orderType == OrderType.CopyTimesASC) {
      performSort();
    }
  }

  resetCopyTimes() {
    for (var element in tokens) {
      element.copyTimes = 0;
    }
    if (orderType == OrderType.CopyTimesDESC ||
        orderType == OrderType.CopyTimesASC) {
      performSort();
    }
  }

  performSort() {
    switch (orderType) {
      case OrderType.Default:
        tokens.sort((a, b) => -a.seq.compareTo(b.seq));
        break;
      case OrderType.AlphabeticalASC:
        tokens.sort((a, b) => a.issuer.compareTo(b.issuer));
        break;
      case OrderType.AlphabeticalDESC:
        tokens.sort((a, b) => -a.issuer.compareTo(b.issuer));
        break;
      case OrderType.CopyTimesDESC:
        tokens.sort((a, b) => -a.copyTimes.compareTo(b.copyTimes));
        break;
      case OrderType.CopyTimesASC:
        tokens.sort((a, b) => a.copyTimes.compareTo(b.copyTimes));
        break;
      case OrderType.LastCopyTimeDESC:
        tokens.sort(
            (a, b) => -a.lastCopyTimeStamp.compareTo(b.lastCopyTimeStamp));
        break;
      case OrderType.LastCopyTimeASC:
        tokens
            .sort((a, b) => a.lastCopyTimeStamp.compareTo(b.lastCopyTimeStamp));
        break;
      case OrderType.CreateTimeDESC:
        tokens.sort((a, b) => -a.createTimeStamp.compareTo(b.createTimeStamp));
        break;
      case OrderType.CreateTimeASC:
        tokens.sort((a, b) => a.createTimeStamp.compareTo(b.createTimeStamp));
        break;
    }
    tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
    setState(() {});
  }

  @override
  void jumpToPage(int index) {}

  @override
  FutureOr popAll([bool initPage = true]) {
    Navigator.pop(chewieProvider.rootContext);
  }

  @override
  FutureOr popPage() {
    Navigator.pop(chewieProvider.rootContext);
  }

  @override
  FutureOr pushPage(Widget page) {
    RouteUtil.pushCupertinoRoute(chewieProvider.rootContext, page);
  }

  @override
  void refreshScrollControllers() {}

  @override
  void showBottomNavigationBar() {}

  @override
  void updateStatusBar() {}
}

enum LayoutType {
  Simple,
  Compact,
  Spotlight,
  List;

  double get maxCrossAxisExtent {
    switch (this) {
      case LayoutType.Simple:
        return 250;
      case LayoutType.Compact:
        return 250;
      // case LayoutType.Tile:
      //   return 420;
      case LayoutType.List:
        return 480;
      case LayoutType.Spotlight:
        return 480;
    }
  }

  double getHeight([bool hideProgressBar = false]) {
    switch (this) {
      case LayoutType.Simple:
        return 108;
      case LayoutType.Compact:
        return 108;
      // case LayoutType.Tile:
      //   return 114;
      case LayoutType.List:
        return 60;
      case LayoutType.Spotlight:
        return 108;
    }
  }

  IconData get icon {
    switch (this) {
      case LayoutType.Simple:
        return LucideIcons.layoutGrid;
      case LayoutType.Compact:
        return LucideIcons.layoutDashboard;
      // case LayoutType.Tile:
      //   return LucideIcons.grid;
      case LayoutType.List:
        return LucideIcons.layoutList;
      case LayoutType.Spotlight:
        return LucideIcons.layoutTemplate;
    }
  }

  String get title {
    switch (this) {
      case LayoutType.Simple:
        return S.current.simpleLayoutType;
      case LayoutType.Compact:
        return S.current.compactLayoutType;
      // case LayoutType.Tile:
      //   return S.current.tileLayout;
      case LayoutType.List:
        return S.current.listLayoutType;
      case LayoutType.Spotlight:
        return S.current.spotlightLayoutType;
    }
  }
}

enum OrderType {
  Default,
  AlphabeticalASC,
  AlphabeticalDESC,
  CopyTimesDESC,
  CopyTimesASC,
  LastCopyTimeDESC,
  LastCopyTimeASC,
  CreateTimeDESC,
  CreateTimeASC;

  String get title {
    switch (this) {
      case OrderType.Default:
        return S.current.defaultOrder;
      case OrderType.AlphabeticalASC:
        return S.current.alphabeticalASCOrder;
      case OrderType.AlphabeticalDESC:
        return S.current.alphabeticalDESCOrder;
      case OrderType.CopyTimesDESC:
        return S.current.copyTimesDESCOrder;
      case OrderType.CopyTimesASC:
        return S.current.copyTimesASCOrder;
      case OrderType.LastCopyTimeDESC:
        return S.current.lastCopyTimeDESCOrder;
      case OrderType.LastCopyTimeASC:
        return S.current.lastCopyTimeASCOrder;
      case OrderType.CreateTimeDESC:
        return S.current.createTimeDESCOrder;
      case OrderType.CreateTimeASC:
        return S.current.createTimeASCOrder;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.Default:
        return LucideIcons.arrowUpNarrowWide;
      case OrderType.AlphabeticalASC:
        return LucideIcons.arrowDownAZ;
      case OrderType.AlphabeticalDESC:
        return LucideIcons.arrowDownZA;
      case OrderType.CopyTimesDESC:
        return LucideIcons.arrowDown10;
      case OrderType.CopyTimesASC:
        return LucideIcons.arrowDown01;
      case OrderType.LastCopyTimeDESC:
        return LucideIcons.clockArrowDown;
      case OrderType.LastCopyTimeASC:
        return LucideIcons.clockArrowUp;
      case OrderType.CreateTimeDESC:
        return LucideIcons.clockArrowDown;
      case OrderType.CreateTimeASC:
        return LucideIcons.clockArrowUp;
    }
  }
}

extension LayoutTypeExtension on int {
  LayoutType get layoutType {
    return LayoutType
        .values[ChewieUtils.patchEnum(0, LayoutType.values.length)];
  }
}

extension OrderTypeExtension on int {
  OrderType get orderType {
    return OrderType.values[ChewieUtils.patchEnum(0, OrderType.values.length)];
  }
}
