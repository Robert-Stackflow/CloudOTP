import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Screens/Setting/about_setting_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_appearance_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_general_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_operation_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_safe_screen.dart';
import 'package:cloudotp/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../Utils/app_provider.dart';

class SettingNavigationItem {
  final String title;
  final IconData icon;

  const SettingNavigationItem({required this.title, required this.icon});
}

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

class _SettingNavigationScreenState extends State<SettingNavigationScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();
  final SearchConfig _searchConfig = SearchConfig();
  Timer? _debounceTimer;

  List<SettingNavigationItem> _navigationItems = [];

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
    _navigationItems = [
      SettingNavigationItem(
          title: S.current.generalSetting, icon: LucideIcons.settings2),
      SettingNavigationItem(
          title: S.current.appearanceSetting,
          icon: LucideIcons.paintbrushVertical),
      SettingNavigationItem(
          title: S.current.operationSetting, icon: LucideIcons.pointer),
      SettingNavigationItem(
          title: S.current.backupSetting, icon: LucideIcons.cloudUpload),
      SettingNavigationItem(
          title: S.current.safeSetting, icon: LucideIcons.shieldCheck),
      SettingNavigationItem(title: S.current.about, icon: LucideIcons.info),
    ];
    return Consumer<AppProvider>(
      builder: (context, provider, child) =>
          Scaffold(
            appBar: ResponsiveAppBar(
              showBack: false,
              titleLeftMargin: 15,
              title: S.current.setting,
            ),
            body: Row(
              children: [
                Container(
                  width: 144,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ChewieTheme.canvasColor,
                    border: ChewieTheme.rightDivider,
                  ),
                  child: ListView.builder(
                    itemCount: _navigationItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: SettingNavigationItemWidget(
                          title: item.title,
                          icon: item.icon,
                          selected: index == _selectedIndex,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
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
          ),
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

class SettingNavigationItemWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const SettingNavigationItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? ChewieTheme.primaryColor : Colors.transparent;
    final textColor = selected ? ChewieTheme.primaryButtonColor : null;

    return PressableAnimation(
      onTap: onTap,
      child: InkAnimation(
        color: bgColor,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Icon(icon, color: textColor),
              // const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: ChewieTheme.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
