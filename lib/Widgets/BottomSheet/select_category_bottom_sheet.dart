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
import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../Utils/app_provider.dart';
import '../../generated/l10n.dart';

class SelectCategoryBottomSheet extends StatefulWidget {
  const SelectCategoryBottomSheet({
    super.key,
    required this.token,
    this.isEditingToken = false,
    this.onCategoryChanged,
    this.initialCategorUids,
  });

  final OtpToken token;
  final bool isEditingToken;
  final List<String>? initialCategorUids;

  final Function(List<String>)? onCategoryChanged;

  @override
  SelectCategoryBottomSheetState createState() =>
      SelectCategoryBottomSheetState();
}

class SelectCategoryBottomSheetState extends State<SelectCategoryBottomSheet> {
  List<TokenCategory> categories = [];
  GroupButtonController controller = GroupButtonController();
  List<String> oldCategoryUids = [];

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  getCategories() async {
    if (widget.isEditingToken) {
      oldCategoryUids = widget.initialCategorUids ?? [];
    } else {
      oldCategoryUids = await BindingDao.getCategoryUids(widget.token.uid);
    }
    setState(() {});
    await CategoryDao.listCategories().then((value) async {
      setState(() {
        categories = value;
        List<int> initSelectedIndexes = [];
        for (int i = 0; i < categories.length; i++) {
          if (oldCategoryUids.contains(categories[i].uid)) {
            initSelectedIndexes.add(i);
          }
        }
        controller.selectIndexes(initSelectedIndexes);
      });
    });
  }

  Radius radius = ChewieDimens.defaultRadius;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
                top: radius,
                bottom:
                    ResponsiveUtil.isWideLandscape() ? radius : Radius.zero),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.border,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildButtons(),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      decoration:
          BoxDecoration(borderRadius: BorderRadius.vertical(top: radius)),
      child: Text(
        textAlign: TextAlign.center,
        widget.token.issuer.isNotEmpty
            ? S.current.setCategoryForTokenDetail(widget.token.issuer)
            : S.current.setCategoryForToken,
        style: ChewieTheme.titleLarge,
      ),
    );
  }

  _buildButtons() {
    return categories.isNotEmpty
        ? ItemBuilder.buildGroupButtons(
            isRadio: false,
            enableDeselect: true,
            constraintWidth: false,
            buttons: categories.map((e) => e.title).toList(),
            controller: controller,
            radius: 8,
          )
        : EmptyPlaceholder(
            text: S.current.noCategory,
            // showButton: true,
            // buttonText: S.current.addCategory,
            onTap: () {
              HomeScreenState.addCategory(
                context,
                onAdded: (category) {
                  setState(() {
                    categories.add(category);
                  });
                },
              );
            },
          );
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(flex: 2, child: SizedBox(height: 50)),
          if (categories.isNotEmpty)
            Expanded(
              flex: 1,
              child: RoundIconTextButton(
                background: ChewieTheme.primaryColor,
                text:
                    widget.isEditingToken ? S.current.confirm : S.current.save,
                onPressed: () async {
                  List<int> selectedIndexes =
                      controller.selectedIndexes.toList();
                  List<String> allSelectedCategoryUids =
                      selectedIndexes.map((e) => categories[e].uid).toList();
                  List<String> unselectedCategoryUids = oldCategoryUids
                      .where((element) =>
                          !allSelectedCategoryUids.contains(element))
                      .toList();
                  List<String> newSelectedCategoryUids = allSelectedCategoryUids
                      .where((element) => !oldCategoryUids.contains(element))
                      .toList();
                  Navigator.of(context).pop();
                  widget.onCategoryChanged?.call(allSelectedCategoryUids);
                  if (!widget.isEditingToken) {
                    await BindingDao.bingdingsForToken(
                        widget.token.uid, newSelectedCategoryUids);
                    await BindingDao.unBingdingsForToken(
                        widget.token.uid, unselectedCategoryUids);
                    homeScreenState?.changeCategoriesForToken(
                      widget.token,
                      unselectedCategoryUids,
                      newSelectedCategoryUids,
                    );
                    IToast.showTop(S.current.saveSuccess);
                  }
                },
                fontSizeDelta: 2,
              ),
            ),
        ],
      ),
    );
  }
}
