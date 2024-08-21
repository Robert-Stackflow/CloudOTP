import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Resources/fonts.dart';
import '../../Resources/theme_color_data.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class AppearanceSettingScreen extends StatefulWidget {
  const AppearanceSettingScreen({super.key});

  static const String routeName = "/setting/appearance";

  @override
  State<AppearanceSettingScreen> createState() =>
      _AppearanceSettingScreenState();
}

class _AppearanceSettingScreenState extends State<AppearanceSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey, defaultValue: true);
  FontEnum _currentFont = FontEnum.getCurrentFont();
  bool showLayoutButton = HiveUtil.getBool(HiveUtil.showLayoutButtonKey);
  bool showSortButton = HiveUtil.getBool(HiveUtil.showSortButtonKey);
  bool showBackupLogButton = HiveUtil.getBool(HiveUtil.showBackupLogButtonKey,
      defaultValue: ResponsiveUtil.isLandscape());
  bool showCloudBackupButton = HiveUtil.getBool(
      HiveUtil.showCloudBackupButtonKey,
      defaultValue: ResponsiveUtil.isLandscape());

  bool hideAppbarWhenScrolling =
      HiveUtil.getBool(HiveUtil.hideAppbarWhenScrollingKey);
  bool hideBottombarWhenScrolling =
      HiveUtil.getBool(HiveUtil.hideBottombarWhenScrollingKey);
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  scrollToSetAutoBackupPassword() {
    if (_setAutoBackupPasswordKey.currentContext != null) {
      Scrollable.ensureVisible(
        _setAutoBackupPasswordKey.currentContext!,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.generalSetting,
                context: context,
                transparent: true,
              )
            : ItemBuilder.buildAppBar(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  S.current.generalSetting,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
                center: true,
                actions: [
                  ItemBuilder.buildBlankIconButton(context),
                  const SizedBox(width: 5),
                ],
              ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ..._apperanceSettings(),
              ..._buttonSettings(),
              if (ResponsiveUtil.isMobile()) ..._mobileSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _apperanceSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.themeSetting),
      Selector<AppProvider, ActiveThemeMode>(
        selector: (context, appProvider) => appProvider.themeMode,
        builder: (context, themeMode, child) => ItemBuilder.buildEntryItem(
          context: context,
          title: S.current.themeMode,
          tip: AppProvider.getThemeModeLabel(themeMode),
          onTap: () {
            BottomSheetBuilder.showListBottomSheet(
              context,
              (context) => TileList.fromOptions(
                AppProvider.getSupportedThemeMode(),
                (item2) {
                  appProvider.themeMode = item2;
                  Navigator.pop(context);
                },
                selected: themeMode,
                context: context,
                title: S.current.chooseThemeMode,
                onCloseTap: () => Navigator.pop(context),
              ),
            );
          },
        ),
      ),
      Selector<AppProvider, ThemeColorData>(
        selector: (context, appProvider) => appProvider.lightTheme,
        builder: (context, lightTheme, child) =>
            Selector<AppProvider, ThemeColorData>(
          selector: (context, appProvider) => appProvider.darkTheme,
          builder: (context, darkTheme, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: S.current.selectTheme,
            tip: "${lightTheme.intlName}/${darkTheme.intlName}",
            onTap: () {
              RouteUtil.pushCupertinoRoute(context, const SelectThemeScreen());
            },
          ),
        ),
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.fontFamily,
        tip: _currentFont.intlFontName,
        bottomRadius: true,
        onTap: () {
          BottomSheetBuilder.showListBottomSheet(
            context,
            (sheetContext) => TileList.fromOptions(
              FontEnum.getFontList(),
              (item2) async {
                FontEnum t = item2 as FontEnum;
                _currentFont = t;
                Navigator.pop(sheetContext);
                setState(() {});
                FontEnum.loadFont(context, t, autoRestartApp: true);
              },
              selected: _currentFont,
              context: context,
              title: S.current.chooseFontFamily,
              onCloseTap: () => Navigator.pop(context),
            ),
          );
        },
      ),
    ];
  }

  _buttonSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showBackupLogButton,
        topRadius: true,
        value: showBackupLogButton,
        onTap: () {
          setState(() {
            showBackupLogButton = !showBackupLogButton;
            appProvider.showBackupLogButton = showBackupLogButton;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showCloudBackupButton,
        value: showCloudBackupButton,
        onTap: () {
          setState(() {
            showCloudBackupButton = !showCloudBackupButton;
            appProvider.showCloudBackupButton = showCloudBackupButton;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showLayoutButton,
        value: showLayoutButton,
        onTap: () {
          setState(() {
            showLayoutButton = !showLayoutButton;
            appProvider.showLayoutButton = showLayoutButton;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        title: S.current.showSortButton,
        bottomRadius: true,
        value: showSortButton,
        onTap: () {
          setState(() {
            showSortButton = !showSortButton;
            appProvider.showSortButton = showSortButton;
          });
        },
      ),
    ];
  }

  _mobileSettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.mobileSetting),
      if (ResponsiveUtil.isTablet())
        ItemBuilder.buildRadioItem(
          value: _enableLandscapeInTablet,
          context: context,
          title: S.current.useDesktopLayoutWhenLandscape,
          description: S.current.haveToRestartWhenChange,
          onTap: () {
            setState(() {
              _enableLandscapeInTablet = !_enableLandscapeInTablet;
              appProvider.enableLandscapeInTablet = _enableLandscapeInTablet;
            });
          },
        ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: hideAppbarWhenScrolling,
        title: S.current.hideAppbarWhenScrolling,
        onTap: () {
          setState(() {
            hideAppbarWhenScrolling = !hideAppbarWhenScrolling;
            appProvider.hideAppbarWhenScrolling = hideAppbarWhenScrolling;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: hideBottombarWhenScrolling,
        bottomRadius: true,
        title: S.current.hideBottombarWhenScrolling,
        onTap: () {
          setState(() {
            hideBottombarWhenScrolling = !hideBottombarWhenScrolling;
            appProvider.hideBottombarWhenScrolling = hideBottombarWhenScrolling;
          });
        },
      ),
    ];
  }
}
