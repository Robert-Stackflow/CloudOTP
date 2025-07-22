import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_appearance_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_operation_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_safe_screen.dart';
import 'package:cloudotp/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../Utils/app_provider.dart';
import '../../Widgets/cloudotp/navigation_bar.dart';

class SettingNavigationScreen extends StatefulWidget {
  final int initPageIndex;

  const SettingNavigationScreen({
    super.key,
    this.initPageIndex = 0,
  });

  @override
  State<SettingNavigationScreen> createState() =>
      _SettingNavigationScreenState();
}

class _SettingNavigationScreenState
    extends BaseDynamicState<SettingNavigationScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();
  final SearchConfig _searchConfig = SearchConfig();
  Timer? _debounceTimer;

  final List<SettingNavigationItem> _navigationItems = [
    SettingNavigationItem(
        title: () => appLocalizations.generalSetting,
        icon: LucideIcons.settings2),
    SettingNavigationItem(
        title: () => appLocalizations.appearanceSetting,
        icon: LucideIcons.paintbrushVertical),
    SettingNavigationItem(
        title: () => appLocalizations.operationSetting,
        icon: LucideIcons.pointer),
    SettingNavigationItem(
        title: () => appLocalizations.backupSetting,
        icon: LucideIcons.cloudUpload),
    SettingNavigationItem(
        title: () => appLocalizations.safeSetting,
        icon: LucideIcons.shieldCheck),
    SettingNavigationItem(
        title: () => appLocalizations.about, icon: LucideIcons.info),
  ];

  final List<Widget?> _pageCache = List.filled(8, null);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _selectedIndex = widget.initPageIndex;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      search(_searchController.text);
    });
  }

  search(String query) {
    setState(() {
      _searchText = query;
    });
  }

  Widget _buildCurrentPage(int index) {
    // if (_pageCache[index] != null) return _pageCache[index]!;

    late Widget page;
    switch (index) {
      case 0:
        page = GeneralSettingScreen(
          key: generalSettingScreenKey,
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      case 1:
        page = AppearanceSettingScreen(
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      case 2:
        page = OperationSettingScreen(
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      case 3:
        page = BackupSettingScreen(
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      case 4:
        page = SafeSettingScreen(
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      case 5:
        page = AboutSettingScreen(
          showTitleBar: false,
          searchText: _searchText,
          searchConfig: _searchConfig,
        );
        break;
      default:
        page = const SizedBox.shrink();
    }

    _pageCache[index] = _KeepAliveWrapper(child: page);
    return _pageCache[index]!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: ResponsiveAppBar(
            showBack: false,
            titleLeftMargin: 15,
            title: appLocalizations.setting,
          ),
          body: Row(
            children: [
              MyNavigationBar(
                items: _navigationItems,
                selectedIndex: _selectedIndex,
                onSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _buildSearchRow(),
                    Expanded(child: _buildCurrentPage(_selectedIndex)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  _buildSearchRow() {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 11, bottom: 10),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Row(
        children: [
          Expanded(
            child: MySearchBar(
              controller: _searchController,
              hintText: "搜索设置项（空格分隔多个关键词、支持拼音匹配、模糊匹配）",
              onSubmitted: (text) {
                search(text);
              },
              showSearchButton: false,
            ),
          ),
          const SizedBox(width: 8),
          RoundIconTextButton(
            background: ChewieTheme.canvasColor,
            border: ChewieTheme.borderWithWidth(1),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tooltip: "高级选项",
            color: ChewieTheme.titleMedium.color,
            icon: Icon(
              LucideIcons.listFilter,
              color: ChewieTheme.iconColor,
              size: 20,
            ),
            onPressed: () {
              BottomSheetBuilder.showContextMenu(
                  context, _buildFilterMoreButtons());
            },
          ),
        ],
      ),
    );
  }

  _buildFilterMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem.checkbox(
          "拼音匹配",
          checked: _searchConfig.enablePinyin,
          onPressed: () {
            setState(() {
              _searchConfig.enablePinyin = !_searchConfig.enablePinyin;
            });
          },
        ),
        FlutterContextMenuItem.checkbox(
          "模糊匹配",
          checked: _searchConfig.enableShortPinyin,
          onPressed: () {
            setState(() {
              _searchConfig.enableShortPinyin =
                  !_searchConfig.enableShortPinyin;
            });
          },
        )
      ],
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends BaseDynamicState<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
