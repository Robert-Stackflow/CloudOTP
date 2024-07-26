import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_token_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';

import '../../Database/category_dao.dart';
import '../../Models/category.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';

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
  List<Category> categories = [];

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
        leading: Icons.close_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          "分类列表",
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
                preferMinWidth: 300,
                (context) => InputBottomSheet(
                  title: "新建分类",
                  text: "",
                  buttonText: "确认",
                  onConfirm: (text) async {
                    if (await CategoryDao.isCategoryExist(text)) {
                      IToast.showTop("分类名称与已有分类重复");
                      return;
                    }
                    await CategoryDao.insertCategory(
                        Category.title(title: text));
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
                    context: context, text: "暂无分类"),
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
                Category oldCategory = categories[oldIndex];
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

  _buildCategoryItem(Category category) {
    return Container(
      key: ValueKey(category.title),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
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
                preferMinWidth: 300,
                (context) => InputBottomSheet(
                  title: "修改分类名称",
                  text: category.title,
                  buttonText: "保存",
                  onConfirm: (text) async {
                    if (await CategoryDao.isCategoryExist(text)) {
                      IToast.showTop("分类名称与已有分类重复");
                      return;
                    }
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
                preferMinWidth: 300,
                (context) => SelectTokenBottomSheet(
                  category: category,
                ),
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
                title: "删除分类",
                message: "确认删除分类「${category.title}」？删除分类后，分类内的令牌不会被删除",
                confirmButtonText: "确认",
                cancelButtonText: "取消",
                onTapConfirm: () async {
                  await CategoryDao.deleteCategory(category);
                  IToast.showTop("删除成功");
                  refresh();
                },
                onTapCancel: () {},
                customDialogType: CustomDialogType.normal,
              );
            },
          ),
          const SizedBox(width: 5),
          ReorderableDragStartListener(
            index: categories.indexOf(category),
            child: ItemBuilder.buildIconButton(
              context: context,
              icon: const Icon(Icons.dehaze_rounded, size: 20),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
