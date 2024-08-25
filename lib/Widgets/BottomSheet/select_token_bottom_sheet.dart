import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Database/token_dao.dart';
import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/itoast.dart';
import '../../generated/l10n.dart';

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
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
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
            child: ItemBuilder.buildGroupTokenButtons(
              tokens: tokens,
              controller: controller,
            ),
          )
        : ItemBuilder.buildEmptyPlaceholder(
            context: context, text: S.current.noToken);
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
            child: ItemBuilder.buildRoundButton(
              context,
              background: Theme.of(context).primaryColor,
              text: S.current.save,
              onTap: () async {
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
