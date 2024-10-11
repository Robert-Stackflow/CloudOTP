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

import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/file_util.dart';
import 'package:cloudotp/Utils/hive_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../Resources/fonts.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class SelectFontScreen extends StatefulWidget {
  const SelectFontScreen({super.key});

  static const String routeName = "/setting/font";

  @override
  State<SelectFontScreen> createState() => _SelectFontScreenState();
}

class _SelectFontScreenState extends State<SelectFontScreen>
    with TickerProviderStateMixin {
  CustomFont _currentFont = CustomFont.getCurrentFont();
  List<CustomFont> customFonts = HiveUtil.getCustomFonts();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.chooseFontFamily,
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
                  S.current.chooseFontFamily,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
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
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.defaultFontFamily),
              ItemBuilder.buildContainerItem(
                context: context,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: _buildDefaultFontList(),
                  ),
                ),
                bottomRadius: true,
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.customFontFamily),
              ItemBuilder.buildContainerItem(
                context: context,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: _buildCustomFontList(),
                  ),
                ),
                bottomRadius: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultFontList() {
    var list = List<Widget>.generate(
      CustomFont.defaultFonts.length,
      (index) => ItemBuilder.buildFontItem(
        currentFont: _currentFont,
        font: CustomFont.defaultFonts[index],
        context: context,
        onChanged: (_) {
          _currentFont = CustomFont.defaultFonts[index];
          appProvider.currentFont = _currentFont;
          CustomFont.loadFont(context, _currentFont, autoRestartApp: false);
        },
      ),
    );
    return list;
  }

  List<Widget> _buildCustomFontList() {
    var list = List<Widget>.generate(
      customFonts.length,
      (index) => ItemBuilder.buildFontItem(
        currentFont: _currentFont,
        showDelete: true,
        font: customFonts[index],
        context: context,
        onChanged: (_) {
          _currentFont = customFonts[index];
          appProvider.currentFont = _currentFont;
          CustomFont.loadFont(context, customFonts[index],
              autoRestartApp: false);
        },
        onDelete: (_) {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.deleteFont(customFonts[index].intlFontName),
            message:
                S.current.deleteFontMessage(customFonts[index].intlFontName),
            onTapConfirm: () async {
              if (customFonts[index] == _currentFont) {
                _currentFont = CustomFont.Default;
                appProvider.currentFont = _currentFont;
                CustomFont.loadFont(context, _currentFont,
                    autoRestartApp: false);
              }
              await CustomFont.deleteFont(customFonts[index]);
              customFonts.removeAt(index);
              HiveUtil.setCustomFonts(customFonts);
            },
          );
        },
      ),
    );
    list.add(
      ItemBuilder.buildEmptyFontItem(
        context: context,
        onTap: () async {
          FilePickerResult? result = await FileUtil.pickFiles(
            dialogTitle: S.current.loadFontFamily,
            allowedExtensions: ['ttf', 'otf'],
            lockParentWindow: true,
            type: FileType.custom,
          );
          if (result != null) {
            CustomFont? customFont =
                await CustomFont.copyFont(filePath: result.files.single.path!);
            if (customFont != null) {
              customFonts.add(customFont);
              HiveUtil.setCustomFonts(customFonts);
              _currentFont = customFont;
              appProvider.currentFont = _currentFont;
              CustomFont.loadFont(context, _currentFont, autoRestartApp: false);
              setState(() {});
            } else {
              IToast.showTop(S.current.fontFamlyLoadFailed);
            }
          }
        },
      ),
    );
    return list;
  }
}
