import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_token_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/input_item.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';

import '../../Database/category_dao.dart';
import '../../Models/category.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../generated/l10n.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
  });

  static const String routeName = "/token/category";

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  List<TokenCategory> categories = [];

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  getCategories() async {
    await CategoryDao.listCategories().then((value) {
      setState(() {
        categories = value;
      });
    });
  }

  refresh() async {
    await getCategories();
    homeScreenState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        forceShowClose: true,
        leading: ResponsiveUtil.isLandscape()
            ? Icons.close_rounded
            : Icons.arrow_back_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.category,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        center: true,
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.add_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => InputBottomSheet(
                  title: S.current.addCategory,
                  hint: S.current.inputCategory,
                  stateController: InputStateController(
                    validate: (text) async {
                      if (text.isEmpty) {
                        return S.current.categoryNameCannotBeEmpty;
                      }
                      if (await CategoryDao.isCategoryExist(text)) {
                        return S.current.categoryNameDuplicate;
                      }
                      return null;
                    },
                  ),
                  maxLength: 32,
                  onValidConfirm: (text) async {
                    await CategoryDao.insertCategory(
                        TokenCategory.title(title: text));
                    refresh();
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _buildBody(),
    );
  }

  _buildBody() {
    return EasyRefresh(
      onRefresh: refresh,
      child: categories.isEmpty
          ? ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtil.isLandscape() ? 20 : 16,
                  vertical: 10),
              children: [
                ItemBuilder.buildEmptyPlaceholder(
                    context: context, text: S.current.noCategory),
              ],
            )
          : ReorderableListView.builder(
              itemBuilder: (context, index) {
                return _buildCategoryItem(categories[index]);
              },
              buildDefaultDragHandles: false,
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                TokenCategory oldCategory = categories[oldIndex];
                categories.removeAt(oldIndex);
                categories.insert(newIndex, oldCategory);
                for (int i = 0; i < categories.length; i++) {
                  categories[i].seq = i;
                }
                CategoryDao.updateCategories(categories);
                refresh();
              },
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(rootContext).shadowColor,
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ).scale(2),
                    ],
                  ),
                  child: child,
                );
              },
            ),
    );
  }

  _buildCategoryItem(TokenCategory category) {
    return Container(
      key: ValueKey("${category.id}${category.title}"),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: categories.indexOf(category),
            child: ItemBuilder.buildIconButton(
              context: context,
              icon: const Icon(Icons.dehaze_rounded, size: 20),
              onTap: () {},
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              category.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ItemBuilder.buildIconButton(
            context: context,
            icon: const Icon(Icons.edit_rounded, size: 20),
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => InputBottomSheet(
                  title: S.current.editCategoryName,
                  hint: S.current.inputCategory,
                  maxLength: 32,
                  text: category.title,
                  stateController: InputStateController(
                    validate: (text) async {
                      if (text.isEmpty) {
                        return S.current.categoryNameCannotBeEmpty;
                      }
                      if (text != category.title &&
                          await CategoryDao.isCategoryExist(text)) {
                        return S.current.categoryNameDuplicate;
                      }
                      return null;
                    },
                  ),
                  onValidConfirm: (text) async {
                    category.title = text;
                    await CategoryDao.updateCategory(category);
                    refresh();
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          ItemBuilder.buildIconButton(
            context: context,
            icon: const Icon(Icons.checklist_rounded, size: 20),
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                responsive: true,
                (context) => SelectTokenBottomSheet(category: category),
              );
            },
          ),
          const SizedBox(width: 5),
          ItemBuilder.buildIconButton(
            context: context,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.red),
            onTap: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: S.current.deleteCategory,
                message: S.current.deleteCategoryHint(category.title),
                confirmButtonText: S.current.confirm,
                cancelButtonText: S.current.cancel,
                onTapConfirm: () async {
                  await CategoryDao.deleteCategory(category);
                  IToast.showTop(
                      S.current.deleteCategorySuccess(category.title));
                  refresh();
                },
                onTapCancel: () {},
                customDialogType: CustomDialogType.normal,
              );
            },
          ),
        ],
      ),
    );
  }
}
