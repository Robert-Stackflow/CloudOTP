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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Screens/Setting/select_font_screen.dart';
import 'package:cloudotp/Screens/Setting/select_theme_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../generated/l10n.dart';
import 'base_setting_screen.dart';

class AppearanceSettingScreen extends BaseSettingScreen {
  const AppearanceSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/appearance";

  @override
  State<AppearanceSettingScreen> createState() =>
      _AppearanceSettingScreenState();
}

class _AppearanceSettingScreenState extends State<AppearanceSettingScreen>
    with TickerProviderStateMixin {
  bool _enableLandscapeInTablet = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.enableLandscapeInTabletKey,
      defaultValue: true);
  bool showLayoutButton =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showLayoutButtonKey);
  bool showSortButton =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showSortButtonKey);
  bool showBackupLogButton = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.showBackupLogButtonKey,
      defaultValue: ResponsiveUtil.isLandscape());
  bool showCloudBackupButton = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.showCloudBackupButtonKey,
      defaultValue: true);

  bool enableFrostedGlassEffect = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.enableFrostedGlassEffectKey,
      defaultValue: false);
  bool hideAppbarWhenScrolling =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideAppbarWhenScrollingKey);
  bool hideBottombarWhenScrolling =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideBottombarWhenScrollingKey);
  final GlobalKey _setAutoBackupPasswordKey = GlobalKey();
  bool hideProgressBar =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.hideProgressBarKey);
  bool showEye =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.showEyeKey, defaultValue: false);

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
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: S.current.appearanceSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        _apperanceSettings(),
        _buttonSettings(),
        _tokenLayoutSettings(),
        if (ResponsiveUtil.isMobile()) _mobileSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _apperanceSettings() {
    return SearchableCaptionItem(
      title: S.current.themeSetting,
      children: [
        SearchableBuilderWidget(
          title: S.current.themeMode,
          builder: (_, title, description, searchText, searchConfig) =>
              Selector<AppProvider, ActiveThemeMode>(
            selector: (context, globalProvider) => globalProvider.themeMode,
            builder: (context, themeMode, child) =>
                InlineSelectionItem<SelectionItemModel<ActiveThemeMode>>(
              hint: S.current.chooseThemeMode,
              title: title,
              description: description,
              searchConfig: searchConfig,
              searchText: searchText,
              selections: ChewieProvider.getSupportedThemeMode(),
              selected: SelectionItemModel(
                ChewieProvider.getThemeModeLabel(themeMode),
                themeMode,
              ),
              onChanged: (SelectionItemModel<ActiveThemeMode>? item) {
                appProvider.themeMode = item!.value;
              },
            ),
          ),
        ),
        SearchableBuilderWidget(
          title: S.current.selectTheme,
          builder: (_, title, description, searchText, searchConfig) =>
              Selector<AppProvider, ChewieThemeColorData>(
            selector: (context, appProvider) => appProvider.lightTheme,
            builder: (context, lightTheme, child) =>
                Selector<AppProvider, ChewieThemeColorData>(
              selector: (context, appProvider) => appProvider.darkTheme,
              builder: (context, darkTheme, child) => EntryItem(
                tip: "${lightTheme.i18nName(context)}/${darkTheme.i18nName(context)}",
                title: title,
                searchConfig: searchConfig,
                searchText: searchText,
                description: description,
                onTap: () {
                  RouteUtil.pushDialogRoute(context, const SelectThemeScreen());
                },
              ),
            ),
          ),
        ),
        SearchableBuilderWidget(
          title: S.current.chooseFontFamily,
          builder: (_, title, description, searchText, searchConfig) =>
              Selector<AppProvider, CustomFont>(
            selector: (context, appProvider) => appProvider.currentFont,
            builder: (context, currentFont, child) => EntryItem(
              tip: currentFont.intlFontName,
              title: title,
              searchConfig: searchConfig,
              searchText: searchText,
              description: description,
              onTap: () {
                RouteUtil.pushDialogRoute(context, const SelectFontScreen());
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttonSettings() {
    return SearchableCaptionItem(
      title: S.current.sideBarSettings,
      children: [
        CheckboxItem(
          title: S.current.showBackupLogButton,
          value: showBackupLogButton,
          onTap: () {
            setState(() {
              showBackupLogButton = !showBackupLogButton;
              appProvider.showBackupLogButton = showBackupLogButton;
            });
          },
        ),
        CheckboxItem(
          title: S.current.showCloudBackupButton,
          value: showCloudBackupButton,
          onTap: () {
            setState(() {
              showCloudBackupButton = !showCloudBackupButton;
              appProvider.showCloudBackupButton = showCloudBackupButton;
            });
          },
        ),
        CheckboxItem(
          title: S.current.showLayoutButton,
          value: showLayoutButton,
          onTap: () {
            setState(() {
              showLayoutButton = !showLayoutButton;
              appProvider.showLayoutButton = showLayoutButton;
            });
          },
        ),
        CheckboxItem(
          title: S.current.showSortButton,
          value: showSortButton,
          onTap: () {
            setState(() {
              showSortButton = !showSortButton;
              appProvider.showSortButton = showSortButton;
            });
          },
        ),
      ],
    );
  }

  Widget _tokenLayoutSettings() {
    return SearchableCaptionItem(
      title: S.current.tokenCardSettings,
      children: [
        CheckboxItem(
          value: hideProgressBar,
          title: S.current.hideProgressBar,
          description: S.current.hideProgressBarTip,
          onTap: () {
            setState(() {
              hideProgressBar = !hideProgressBar;
              appProvider.hideProgressBar = hideProgressBar;
            });
          },
        ),
        CheckboxItem(
          value: showEye,
          title: S.current.showEye,
          description: S.current.showEyeTip,
          onTap: () {
            setState(() {
              showEye = !showEye;
              appProvider.showEye = showEye;
            });
          },
        ),
      ],
    );
  }

  Widget _mobileSettings() {
    return SearchableCaptionItem(
      title: S.current.mobileSetting,
      children: [
        if (ResponsiveUtil.isLandscapeTablet())
          CheckboxItem(
            value: _enableLandscapeInTablet,
            title: S.current.useDesktopLayoutWhenLandscape,
            description: S.current.haveToRestartWhenChange,
            onTap: () {
              setState(() {
                _enableLandscapeInTablet = !_enableLandscapeInTablet;
                appProvider.enableLandscapeInTablet = _enableLandscapeInTablet;
              });
            },
          ),
        CheckboxItem(
          value: enableFrostedGlassEffect,
          title: S.current.enableFrostedGlassEffect,
          onTap: () {
            setState(() {
              enableFrostedGlassEffect = !enableFrostedGlassEffect;
              appProvider.enableFrostedGlassEffect = enableFrostedGlassEffect;
            });
          },
        ),
        CheckboxItem(
          value: hideAppbarWhenScrolling,
          title: S.current.hideAppbarWhenScrolling,
          onTap: () {
            setState(() {
              hideAppbarWhenScrolling = !hideAppbarWhenScrolling;
              appProvider.hideAppbarWhenScrolling = hideAppbarWhenScrolling;
            });
          },
        ),
        CheckboxItem(
          value: hideBottombarWhenScrolling,
          title: S.current.hideBottombarWhenScrolling,
          onTap: () {
            setState(() {
              hideBottombarWhenScrolling = !hideBottombarWhenScrolling;
              appProvider.hideBottombarWhenScrolling =
                  hideBottombarWhenScrolling;
            });
          },
        ),
      ],
    );
  }
}
