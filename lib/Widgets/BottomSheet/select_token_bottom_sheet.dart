import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Database/token_dao.dart';
import '../../Models/category.dart';
import '../../Models/opt_token.dart';
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
  GroupButtonController controller = GroupButtonController();

  @override
  void initState() {
    super.initState();
    getTokens();
  }

  getTokens() async {
    await TokenDao.listTokens().then((value) {
      setState(() {
        tokens = value;
        List<int> initSelectedIndexes = [];
        for (int i = 0; i < tokens.length; i++) {
          if (widget.category.tokenIds.contains(tokens[i].id)) {
            initSelectedIndexes.add(i);
          }
        }
        controller.selectIndexes(initSelectedIndexes);
      });
    });
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
              _buildButtons(),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  _buildButtons() {
    return tokens.isNotEmpty
        ? ItemBuilder.buildGroupTokenButtons(
            tokens: tokens,
            controller: controller,
          )
        : ItemBuilder.buildEmptyPlaceholder(
            context: context, text: S.current.noToken);
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

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox(height: 50)),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                text: S.current.save,
                onTap: () async {
                  List<int> selectedIndexes =
                      controller.selectedIndexes.toList();
                  List<int> tokenIds =
                      selectedIndexes.map((e) => tokens[e].id).toList();
                  widget.category.tokenIds = tokenIds;
                  await CategoryDao.updateCategory(widget.category);
                  homeScreenState?.refresh();
                  IToast.showTop(S.current.saveSuccess);
                  Navigator.of(context).pop();
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
