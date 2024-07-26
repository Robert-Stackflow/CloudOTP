import 'package:cloudotp/Database/category_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Screens/Setting/setting_screen.dart';
import 'package:cloudotp/Screens/Token/add_token_screen.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_drawer.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../Models/category.dart';
import '../Utils/app_provider.dart';
import '../Utils/route_util.dart';
import '../Utils/utils.dart';
import '../Widgets/Custom/custom_tab_indicator.dart';
import '../Widgets/Custom/sliver_appbar_delegate.dart';
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
  Detail,
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String appName = "";
  LayoutType layoutType = HiveUtil.getLayoutType();
  List<OtpToken> tokens = [];
  List<Category> categories = [];
  late TabController _tabController;
  List<Tab> tabList = [];
  int _currentTabIndex = 0;
  Key sliverPersistentHeaderKey = ValueKey(Utils.getRandomString());

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
    await getCategories();
    getTokens();
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
    await CategoryDao.getTokensByCategoryId(currentCategoryId).then((value) {
      setState(() {
        tokens = value;
      });
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
    tabList.add(const Tab(text: "全部"));
    for (var category in categories) {
      tabList.add(Tab(text: category.title));
    }
    _tabController = TabController(length: tabList.length, vsync: this);
    _tabController.index = _currentTabIndex;
    sliverPersistentHeaderKey = ValueKey(Utils.getRandomString());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      key: homeScaffoldKey,
      customAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
      appBar: ResponsiveUtil.isLandscape()
          ? null
          : ItemBuilder.buildAppBar(
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                appName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.apply(fontWeightDelta: 2),
              ),
              leading: Icons.menu_rounded,
              onLeadingTap: () {
                homeScaffoldState?.openDrawer();
              },
              actions: [
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: Icon(Icons.qr_code_scanner_rounded,
                      color: Theme.of(context).iconTheme.color),
                  onTap: () {},
                ),
                const SizedBox(width: 5),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: Icon(Icons.dashboard_outlined,
                      color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    setState(() {
                      layoutType = layoutType == LayoutType.Simple
                          ? LayoutType.Detail
                          : LayoutType.Simple;
                    });
                  },
                ),
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: Icon(Icons.more_vert_rounded,
                      color: Theme.of(context).iconTheme.color),
                  onTap: () {},
                ),
                const SizedBox(width: 5),
              ],
            ),
      body: _buildBody(),
      drawer: _buildDrawer(),
    );
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    if (Utils.isDark(context) != Theme.of(context).brightness) {
      sliverPersistentHeaderKey = ValueKey(Utils.getRandomString());
    }
  }

  _buildBody() {
    late double maxCrossAxisExtent;
    switch (layoutType) {
      case LayoutType.Simple:
        maxCrossAxisExtent = 300;
        break;
      case LayoutType.Detail:
        maxCrossAxisExtent = 800;
        break;
    }
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          key: sliverPersistentHeaderKey,
          pinned: true,
          delegate: SliverHeaderDelegate.fixedHeight(
            height: 54,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _buildTabBar(),
            ),
          ),
        ),
        SliverFillRemaining(
          child: EasyRefresh(
            onRefresh: () async {
              await getTokens();
            },
            refreshOnStart: true,
            child: WaterfallFlow.extent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 10, bottom: 30),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (var token in tokens)
                  TokenLayout(
                    token: token,
                    layoutType: layoutType,
                  ),
              ],
            ),
          ),
        ),
      ],
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
                title: "添加令牌",
                topRadius: true,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(context, const AddTokenScreen());
                },
                leading: Icons.add_rounded,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                bottomRadius: true,
                onTap: () {},
                title: "导入和导出",
                showLeading: true,
                leading: Icons.import_export_rounded,
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "设置",
                topRadius: true,
                bottomRadius: true,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(context, const SettingScreen());
                },
                leading: Icons.settings_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
