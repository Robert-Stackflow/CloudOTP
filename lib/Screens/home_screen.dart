import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_screen.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Screens/Token/import_export_token_screen.dart';
import 'package:cloudotp/Screens/main_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Utils/utils.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_drawer.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:cloudotp/Widgets/WaterfallFlow/sliver_waterfall_flow.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../Database/token_dao.dart';
import '../Models/category.dart';
import '../Utils/app_provider.dart';
import '../Utils/lottie_util.dart';
import '../Utils/route_util.dart';
import '../Widgets/Custom/animated_search_bar.dart';
import '../Widgets/Custom/custom_tab_indicator.dart';
import '../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../Widgets/General/LottieCupertinoRefresh/lottie_cupertino_refresh.dart';
import '../Widgets/WaterfallFlow/reorderable_grid_view.dart';
import '../generated/l10n.dart';
import 'Token/category_screen.dart';
import 'Token/scan_token_screen.dart';
import 'Token/token_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  static const String routeName = "/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

enum LayoutType {
  Simple,
  Compact,
  Tile;

  double get maxCrossAxisExtent {
    switch (this) {
      case LayoutType.Simple:
        return 250;
      case LayoutType.Compact:
        return 250;
      case LayoutType.Tile:
        return 480;
    }
  }

  double get height {
    switch (this) {
      case LayoutType.Simple:
        return 110;
      case LayoutType.Compact:
        return 110;
      case LayoutType.Tile:
        return 110;
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
}

extension LayoutTypeExtension on int {
  LayoutType get layoutType {
    return LayoutType.values[Utils.patchEnum(0, LayoutType.values.length)];
  }
}

extension OrderTypeExtension on int {
  OrderType get orderType {
    return OrderType.values[Utils.patchEnum(0, OrderType.values.length)];
  }
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String appName = "";
  LayoutType layoutType = HiveUtil.getLayoutType();
  OrderType orderType = HiveUtil.getOrderType();
  List<OtpToken> tokens = [];
  List<TokenCategory> categories = [];
  late TabController _tabController;
  List<Tab> tabList = [];
  int _currentTabIndex = 0;
  String _searchKey = "";

  @override
  void initState() {
    super.initState();
    initAppName();
    initTab();
    refresh();
  }

  initAppName() {
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        appName = info.appName;
      });
    });
  }

  refresh() async {
    if (!mounted) return;
    await getCategories();
    await getTokens();
  }

  int get currentCategoryId {
    if (_currentTabIndex == 0) {
      return -1;
    } else {
      if (_currentTabIndex - 1 < 0 ||
          _currentTabIndex - 1 >= categories.length) {
        return -1;
      }
      return categories[_currentTabIndex - 1].id;
    }
  }

  getTokens() async {
    await CategoryDao.getTokensByCategoryId(
      currentCategoryId,
      searchKey: _searchKey,
    ).then((value) {
      tokens = value;
      performSort();
      setState(() {});
    });
  }

  getCategories() async {
    int oldId = currentCategoryId;
    await CategoryDao.listCategories().then((value) {
      setState(() {
        categories = value;
        List<int> ids = categories.map((e) => e.id).toList();
        if (!ids.contains(oldId)) {
          _currentTabIndex = 0;
        } else {
          _currentTabIndex = ids.indexOf(oldId) + 1;
        }
        initTab();
      });
    });
  }

  initTab() {
    tabList.clear();
    tabList.add(Tab(text: S.current.allTokens));
    for (var category in categories) {
      tabList.add(Tab(text: category.title));
    }
    _tabController = TabController(length: tabList.length, vsync: this);
    _tabController.index = _currentTabIndex;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      key: homeScaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: ResponsiveUtil.isLandscape()
          ? PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: _buildTabBar(),
              ),
            )
          : null,
      drawerEdgeDragWidth: 30,
      body: ResponsiveUtil.isLandscape() ? _buildMainContent() : _buildBody(),
      drawer: _buildDrawer(),
    );
  }

  _buildBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          Selector<AppProvider, bool>(
            selector: (context, provider) => provider.hideAppbarWhenScrolling,
            builder: (context, hideAppbarWhenScrolling, child) =>
                ItemBuilder.buildSliverAppBar(
              context: context,
              floating: hideAppbarWhenScrolling,
              pinned: !hideAppbarWhenScrolling,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              // title: Text(
              //   appName,
              //   style: Theme.of(context)
              //       .textTheme
              //       .titleMedium
              //       ?.apply(fontWeightDelta: 2),
              // ),
              title: AnimatedSearchBar(
                label: appName,
                labelStyle: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .apply(fontWeightDelta: 2),
                onChanged: (value) {
                  performSearch(value);
                },
              ),
              expandedHeight: kToolbarHeight,
              collapsedHeight: kToolbarHeight,
              leading: Icons.menu_rounded,
              onLeadingTap: () {
                homeScaffoldState?.openDrawer();
              },
              actions: [
                // ItemBuilder.buildIconButton(
                //   context: context,
                //   icon: Icon(Icons.search_rounded,
                //       color: Theme.of(context).iconTheme.color),
                //   onTap: () {},
                // ),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: Icon(Icons.qr_code_scanner_rounded,
                      color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    RouteUtil.pushCupertinoRoute(
                        context, const ScanTokenScreen());
                  },
                ),
                const SizedBox(width: 5),
                ItemBuilder.buildPopupMenuButton(
                  context: context,
                  icon: Icon(Icons.dashboard_outlined,
                      color: Theme.of(context).iconTheme.color),
                  itemBuilder: (context) {
                    return ItemBuilder.buildPopupMenuItems(
                      context,
                      MainScreenState.buildLayoutContextMenuButtons(),
                    );
                  },
                  onSelected: (_) {
                    globalNavigatorState?.pop();
                  },
                ),
                const SizedBox(width: 5),
                ItemBuilder.buildPopupMenuButton(
                  context: context,
                  icon: Icon(Icons.sort_rounded,
                      color: Theme.of(context).iconTheme.color),
                  itemBuilder: (context) {
                    return ItemBuilder.buildPopupMenuItems(
                      context,
                      MainScreenState.buildSortContextMenuButtons(),
                    );
                  },
                  onSelected: (_) {
                    globalNavigatorState?.pop();
                  },
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ];
      },
      body: _buildMainContent(),
    );
  }

  changeLayoutType([LayoutType? type]) {
    setState(() {
      if (type != null) {
        layoutType = type;
      } else {
        layoutType = layoutType == LayoutType.Tile
            ? LayoutType.Simple
            : LayoutType.values[layoutType.index + 1];
      }
      HiveUtil.setLayoutType(layoutType);
    });
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
      HiveUtil.setOrderType(orderType);
    });
    if (doPerformSort) performSort();
  }

  performSort() {
    switch (orderType) {
      case OrderType.Default:
        tokens.sort((a, b) => a.seq.compareTo(b.seq));
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
  }

  _buildMainContent() {
    Widget gridView = Selector<AppProvider, bool>(
      selector: (context, provider) => provider.dragToReorder,
      builder: (context, dragToReorder, child) => ReorderableGridView.builder(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 30),
        gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: layoutType.maxCrossAxisExtent,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          preferredHeight: layoutType.height,
        ),
        dragToReorder: dragToReorder,
        cacheExtent: 9999,
        itemDragEnable: (index) {
          if (tokens[index].pinnedInt == 1) {
            return false;
          }
          return true;
        },
        onReorder: (int oldIndex, int newIndex) async {
          setState(() {
            final item = tokens.removeAt(oldIndex);
            tokens.insert(newIndex, item);
          });
          for (int i = 0; i < tokens.length; i++) {
            tokens[i].seq = i;
          }
          tokens.sort((a, b) => -a.pinnedInt.compareTo(b.pinnedInt));
          await TokenDao.updateTokens(tokens);
          changeOrderType(type: OrderType.Default, doPerformSort: false);
        },
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ).scale(2),
              ],
            ),
            child: child,
          );
        },
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          return TokenLayout(
            key: ValueKey("${tokens[index].id} ${tokens[index].issuer}"),
            token: tokens[index],
            layoutType: layoutType,
          );
        },
      ),
    );
    // return gridView;
    return EasyRefresh(
      onRefresh: refresh,
      header: LottieCupertinoHeader(
        backgroundColor: Theme.of(context).canvasColor,
        indicator:
            LottieUtil.load(LottieUtil.getLoadingPath(context), scale: 1.5),
        hapticFeedback: true,
        triggerOffset: 10,
      ),
      refreshOnStart: true,
      child: tokens.isEmpty
          ? ListView(
              children: [
                ItemBuilder.buildEmptyPlaceholder(
                    context: context, text: S.current.noToken),
              ],
            )
          : gridView,
    );
  }

  _buildTabBar() {
    return TabBar(
      controller: _tabController,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: tabList,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      dividerHeight: 0,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      physics: const BouncingScrollPhysics(),
      labelStyle:
          Theme.of(context).textTheme.titleMedium?.apply(fontWeightDelta: 2),
      unselectedLabelStyle:
          Theme.of(context).textTheme.titleMedium?.apply(color: Colors.grey),
      indicator: CustomTabIndicator(
        borderColor: Theme.of(context).primaryColor,
      ),
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
          getTokens();
        });
      },
    );
  }

  performSearch(String searchKey) {
    _searchKey = searchKey;
    getTokens();
  }

  _buildDrawer() {
    return MyDrawer(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtil.isLandscape() ? 20 : 10, vertical: 10),
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top),
              Container(
                constraints: const BoxConstraints(maxWidth: 66),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.withOpacity(0.1), width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 64,
                    width: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.addToken,
                topRadius: true,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(context, const AddTokenScreen());
                },
                leading: Icons.add_rounded,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const ImportExportTokenScreen());
                },
                title: S.current.exportImport,
                showLeading: true,
                leading: Icons.import_export_rounded,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(context, const CategoryScreen());
                },
                title: S.current.category,
                showLeading: true,
                leading: Icons.category_outlined,
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.setting,
                topRadius: true,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(context, const SettingScreen());
                },
                leading: Icons.settings_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.about,
                bottomRadius: true,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const AboutSettingScreen());
                },
                leading: Icons.info_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
