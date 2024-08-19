import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../Models/token_category.dart';
import '../../Models/opt_token.dart';
import '../../Utils/app_provider.dart';
import '../../generated/l10n.dart';

class SelectCategoryBottomSheet extends StatefulWidget {
  const SelectCategoryBottomSheet({
    super.key,
    required this.token,
    this.isEditingToken = false,
    this.onCategoryChanged,
    this.initialCategoryIds,
  });

  final OtpToken token;
  final bool isEditingToken;
  final List<int>? initialCategoryIds;

  final Function(List<int>)? onCategoryChanged;

  @override
  SelectCategoryBottomSheetState createState() =>
      SelectCategoryBottomSheetState();
}

class SelectCategoryBottomSheetState extends State<SelectCategoryBottomSheet> {
  List<TokenCategory> categories = [];
  GroupButtonController controller = GroupButtonController();
  List<int> oldCategoryIds = [];

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  getCategories() async {
    if (widget.isEditingToken) {
      oldCategoryIds = widget.initialCategoryIds ?? [];
    } else {
      oldCategoryIds =
          await CategoryDao.getCategoryIdsByTokenId(widget.token.id);
    }
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
      child: Text(
        textAlign: TextAlign.center,
        widget.token.issuer.isNotEmpty
            ? S.current.setCategoryForTokenDetail(widget.token.issuer)
            : S.current.setCategoryForToken,
        style: Theme.of(context).textTheme.titleLarge,
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
        : ItemBuilder.buildEmptyPlaceholder(
            context: context, text: S.current.noCategory);
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
              text: widget.isEditingToken ? S.current.confirm : S.current.save,
              onTap: () async {
                List<int> selectedIndexes = controller.selectedIndexes.toList();
                List<int> allSelectedCategoryIds =
                    selectedIndexes.map((e) => categories[e].id).toList();
                List<int> unselectedCategoryIds = oldCategoryIds
                    .where(
                        (element) => !allSelectedCategoryIds.contains(element))
                    .toList();
                List<int> newSelectedCategoryIds = allSelectedCategoryIds
                    .where((element) => !oldCategoryIds.contains(element))
                    .toList();
                Navigator.of(context).pop();
                widget.onCategoryChanged?.call(allSelectedCategoryIds);
                if (!widget.isEditingToken) {
                  await CategoryDao.updateCategoriesForToken(
                    widget.token.id,
                    unselectedCategoryIds,
                    newSelectedCategoryIds,
                    // backup: true,
                  );
                  homeScreenState?.changeCategoriesForToken(
                    widget.token,
                    unselectedCategoryIds,
                    newSelectedCategoryIds,
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
