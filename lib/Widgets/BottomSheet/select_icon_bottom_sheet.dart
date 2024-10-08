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

import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../TokenUtils/token_image_util.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/asset_util.dart';
import '../../Utils/itoast.dart';
import '../../generated/l10n.dart';
import '../WaterfallFlow/scroll_view.dart';
import '../WaterfallFlow/sliver_waterfall_flow.dart';

class SelectIconBottomSheet extends StatefulWidget {
  const SelectIconBottomSheet({
    super.key,
    required this.token,
    required this.onSelected,
    this.doUpdate = false,
  });

  final OtpToken token;
  final bool doUpdate;
  final Function(String) onSelected;

  @override
  SelectIconBottomSheetState createState() => SelectIconBottomSheetState();
}

class SelectIconBottomSheetState extends State<SelectIconBottomSheet> {
  GroupButtonController controller = GroupButtonController();
  TextEditingController searchController = TextEditingController();
  List<String> icons = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        searchController.text = widget.token.issuer;
        icons = TokenImageUtil.matchBrandLogos(searchController.text);
      });
      searchController.addListener(() {
        setState(() {
          icons = TokenImageUtil.matchBrandLogos(searchController.text);
        });
      });
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget mainBody = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.vertical(
            top: const Radius.circular(20),
            bottom: ResponsiveUtil.isWideLandscape()
                ? const Radius.circular(20)
                : Radius.zero),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(),
          ItemBuilder.buildDesktopSearchBar(
            controller: searchController,
            context: context,
            borderRadius: 8,
            bottomMargin: 18,
            focusNode: _focusNode,
            hintFontSizeDelta: 1,
            background: Colors.grey.withAlpha(40),
            hintText: S.current.searchIconName,
            onSubmitted: (str) {
              setState(() {
                icons = TokenImageUtil.matchBrandLogos(str);
              });
            },
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _buildButtons(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      child:
          ResponsiveUtil.isWideLandscape() ? Center(child: mainBody) : mainBody,
    );
  }

  _buildButtons() {
    return WaterfallFlow.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 10),
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) => ItemBuilder.buildRoundButton(
        context,
        radius: 8,
        align: true,
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: AssetUtil.loadBrand(icons[index], width: 20, height: 20),
        ),
        text: icons[index].split(".")[0],
        onTap: () async {
          widget.token.imagePath = icons[index];
          widget.onSelected.call(widget.token.imagePath);
          if (widget.doUpdate) {
            await TokenDao.updateToken(widget.token);
            IToast.showTop(S.current.saveSuccess);
            homeScreenState?.updateToken(widget.token);
          }
          Navigator.of(context).pop();
        },
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        textStyle:
            Theme.of(context).textTheme.titleSmall?.apply(fontSizeDelta: 1),
      ),
      itemCount: icons.length,
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      alignment: Alignment.center,
      child: Text(
        textAlign: TextAlign.center,
        widget.token.issuer.isNotEmpty
            ? S.current.setIconForTokenDetail(widget.token.issuer)
            : S.current.setIconForToken,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
