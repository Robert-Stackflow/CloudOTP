import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Models/category.dart';
import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
import '../../generated/l10n.dart';

class SelectCategoryBottomSheet extends StatefulWidget {
  const SelectCategoryBottomSheet({
    super.key,
    required this.token,
  });

  final OtpToken token;

  @override
  SelectCategoryBottomSheetState createState() =>
      SelectCategoryBottomSheetState();
}

class SelectCategoryBottomSheetState extends State<SelectCategoryBottomSheet> {
  List<Category> categories = [];
  GroupButtonController controller = GroupButtonController();
  List<int> oldCategoryIds = [];

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  getCategories() async {
    oldCategoryIds = await CategoryDao.getCategoryIdsByTokenId(widget.token.id);
    await CategoryDao.listCategories().then((value) async {
      setState(() {
        categories = value;
        List<int> initSelectedIndexes = [];
        for (int i = 0; i < categories.length; i++) {
          if (oldCategoryIds.contains(categories[i].id)) {
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
    return categories.isNotEmpty
        ? ItemBuilder.buildGroupButtons(
            isRadio: false,
            enableDeselect: true,
            buttons: categories.map((e) => e.title).toList(),
            controller: controller,
          )
        : ItemBuilder.buildEmptyPlaceholder(
            context: context, text: S.current.noCategory);
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        textAlign: TextAlign.center,
        S.current.setCategoryForToken(widget.token.issuer),
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
                  List<int> allSelectedCategoryIds =
                      selectedIndexes.map((e) => categories[e].id).toList();
                  List<int> unselectedCategoryIds = oldCategoryIds
                      .where((element) =>
                          !allSelectedCategoryIds.contains(element))
                      .toList();
                  List<int> newSelectedCategoryIds = allSelectedCategoryIds
                      .where((element) => !oldCategoryIds.contains(element))
                      .toList();
                  await CategoryDao.updateCategoriesForToken(
                    widget.token.id,
                    unselectedCategoryIds,
                    newSelectedCategoryIds,
                  );
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
