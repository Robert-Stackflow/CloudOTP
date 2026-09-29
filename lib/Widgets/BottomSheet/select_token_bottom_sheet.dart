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
import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/category_dao.dart';
import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';
import '../cloudotp/cloudotp_item_builder.dart';

class SelectTokenBottomSheet extends StatefulWidget {
  const SelectTokenBottomSheet({
    super.key,
    required this.category,
    this.onChanged,
  });

  final TokenCategory category;
  final VoidCallback? onChanged;

  @override
  SelectTokenBottomSheetState createState() => SelectTokenBottomSheetState();
}

class SelectTokenBottomSheetState
    extends BaseDynamicState<SelectTokenBottomSheet> {
  List<OtpToken> tokens = [];
  List<String> oldSelectedUids = [];
  GroupButtonController controller = GroupButtonController();
  Radius radius = ChewieDimens.defaultRadius;

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
                  bottom: ResponsiveUtil.isWideDevice() ? radius : Radius.zero),
              color: ChewieTheme.scaffoldBackgroundColor,
              border: ChewieTheme.responsiveBorder,
              boxShadow: ChewieTheme.defaultBoxShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: ResponsiveUtil.isWideDevice()
                        ? MediaQuery.of(context).size.height * 0.4
                        : MediaQuery.of(context).size.height - 320,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _buildButtons(),
                  ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ChewieTheme.primaryColor.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(LucideIcons.keyRound,
                color: ChewieTheme.primaryColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appLocalizations.setTokenForCategory(widget.category.title),
              style:
                  ChewieTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        : EmptyPlaceholder(text: appLocalizations.noToken);
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: RoundIconTextButton(
                text: appLocalizations.cancel,
                onPressed: () => Navigator.of(context).pop(),
                fontSizeDelta: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 45,
              child: RoundIconTextButton(
                background: ChewieTheme.primaryColor,
                color: Colors.white,
                text: appLocalizations.save,
                onPressed: () async {
                  List<int> selectedIndexes =
                      controller.selectedIndexes.toList();
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
                  widget.onChanged?.call();
                  IToast.showTop(appLocalizations.saveSuccess);
                  if (mounted) Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
