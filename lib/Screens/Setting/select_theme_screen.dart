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
import 'package:cloudotp/Screens/Setting/base_setting_screen.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class SelectThemeScreen extends BaseSettingScreen {
  const SelectThemeScreen({super.key});

  static const String routeName = "/setting/theme";

  @override
  State<SelectThemeScreen> createState() => _SelectThemeScreenState();
}

class _SelectThemeScreenState extends State<SelectThemeScreen>
    with TickerProviderStateMixin {
  int _selectedLightIndex = ChewieHiveUtil.getLightThemeIndex();
  int _selectedDarkIndex = ChewieHiveUtil.getDarkThemeIndex();

  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: S.current.selectTheme,
      showTitleBar: widget.showTitleBar,
      showBack: true,
      padding: widget.padding,
      onTapBack: () {
        if (ResponsiveUtil.isLandscape()) {
          chewieProvider.dialogNavigatorState?.popPage();
        } else {
          Navigator.pop(context);
        }
      },
      children: [
        CaptionItem(
          title: S.current.lightTheme,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    children: _buildLightThemeList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        CaptionItem(
          title: S.current.darkTheme,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    children: _buildDarkThemeList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  List<Widget> _buildLightThemeList() {
    var list = List<Widget>.generate(
      ChewieThemeColorData.defaultLightThemes.length,
      (index) => ThemeItem(
        index: index,
        groupIndex: _selectedLightIndex,
        themeColorData: ChewieThemeColorData.defaultLightThemes[index],
        onChanged: (index) {
          setState(
            () {
              _selectedLightIndex = index ?? 0;
              chewieProvider.setLightTheme(index ?? 0);
            },
          );
        },
      ),
    );
    // list.add(ItemBuilder.buildEmptyThemeItem(context: context, onTap: null));
    return list;
  }

  List<Widget> _buildDarkThemeList() {
    var list = List<Widget>.generate(
      ChewieThemeColorData.defaultDarkThemes.length,
      (index) => ThemeItem(
        index: index,
        groupIndex: _selectedDarkIndex,
        themeColorData: ChewieThemeColorData.defaultDarkThemes[index],
        onChanged: (index) {
          setState(
            () {
              _selectedDarkIndex = index ?? 0;
              chewieProvider.setDarkTheme(index ?? 0);
            },
          );
        },
      ),
    );
    return list;
  }
}
