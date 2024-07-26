import 'package:cloudotp/Resources/fonts.dart';
import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Utils/enums.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class AppearanceSettingScreen extends StatefulWidget {
  const AppearanceSettingScreen({super.key});

  static const String routeName = "/setting/apperance";

  @override
  State<AppearanceSettingScreen> createState() =>
      _AppearanceSettingScreenState();
}

class _AppearanceSettingScreenState extends State<AppearanceSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet =
      HiveUtil.getBool(HiveUtil.enableLandscapeInTabletKey, defaultValue: true);
  FontEnum _currentFont = FontEnum.getCurrentFont();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.apprearanceSetting,
            context: context,
            transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.themeSetting),
              Selector<AppProvider, ActiveThemeMode>(
                selector: (context, globalProvider) => globalProvider.themeMode,
                builder: (context, themeMode, child) =>
                    ItemBuilder.buildEntryItem(
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
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.selectTheme,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const SelectThemeScreen());
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "选择字体",
                bottomRadius: true,
                tip: _currentFont.fontName,
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
                      title: "选择字体",
                      onCloseTap: () => Navigator.pop(context),
                    ),
                  );
                },
              ),
              if (ResponsiveUtil.isTablet()) const SizedBox(height: 10),
              if (ResponsiveUtil.isTablet())
                ItemBuilder.buildRadioItem(
                  value: _enableLandscapeInTablet,
                  context: context,
                  title: "横屏时启用桌面端布局",
                  description: "更改后需要重启",
                  topRadius: true,
                  bottomRadius: true,
                  onTap: () {
                    setState(() {
                      _enableLandscapeInTablet = !_enableLandscapeInTablet;
                      appProvider.enableLandscapeInTablet =
                          _enableLandscapeInTablet;
                    });
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
