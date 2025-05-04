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
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../Utils/app_provider.dart';
import '../../generated/l10n.dart';
import '../cloudotp/cloudotp_item_builder.dart';

class SelectTokenBottomSheet extends StatefulWidget {
  const SelectTokenBottomSheet({
    super.key,
    required this.category,
  });

  final TokenCategory category;

  @override
  SelectTokenBottomSheetState createState() => SelectTokenBottomSheetState();
}

class SelectTokenBottomSheetState extends State<SelectTokenBottomSheet> {
  List<OtpToken> tokens = [];
  List<String> oldSelectedUids = [];
  GroupButtonController controller = GroupButtonController();
  Radius radius = ChewieDimens.radius8;

  @override
  void initState() {
    super.initState();
    getTokens();
  }

  getTokens() async {
    tokens = await TokenDao.listTokens();
    oldSelectedUids = await BindingDao.getTokenUids(widget.category.uid);
    setState(() {});
    List<int> initSelectedIndexes = [];
    for (int i = 0; i < tokens.length; i++) {
      if (oldSelectedUids.contains(tokens[i].uid)) {
        initSelectedIndexes.add(i);
      }
    }
    controller.selectIndexes(initSelectedIndexes);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
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
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 320),
                  child: _buildButtons(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.vertical(top: radius)),
      alignment: Alignment.center,
      child: Text(
        textAlign: TextAlign.center,
        S.current.setTokenForCategory(widget.category.title),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildButtons() {
    return tokens.isNotEmpty
        ? SingleChildScrollView(
            child: CloudOTPItemBuilder.buildGroupTokenButtons(
              tokens: tokens,
              controller: controller,
              height: 36,
            ),
          )
        : EmptyPlaceholder(text: S.current.noToken);
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
          Expanded(
            flex: 1,
            child: RoundIconTextButton(
              background: ChewieTheme.primaryColor,
              text: S.current.save,
              onPressed: () async {
                List<int> selectedIndexes = controller.selectedIndexes.toList();
                List<String> tokenUids =
                    selectedIndexes.map((e) => tokens[e].uid).toList();
                List<String> unSelectedUids = oldSelectedUids
                    .where((element) => !tokenUids.contains(element))
                    .toList();
                List<String> newSelectedUids = tokenUids
                    .where((element) => !oldSelectedUids.contains(element))
                    .toList();
                await BindingDao.bingdingsForCategory(
                    widget.category.uid, newSelectedUids);
                await BindingDao.unBingdingsForCategory(
                    widget.category.uid, unSelectedUids);
                await CategoryDao.updateCategory(widget.category);
                homeScreenState?.changeTokensForCategory(widget.category);
                IToast.showTop(S.current.saveSuccess);
                Navigator.of(context).pop();
              },
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
    );
  }
}
