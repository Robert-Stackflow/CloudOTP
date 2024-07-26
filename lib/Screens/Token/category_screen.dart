import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';

import '../../Database/category_dao.dart';
import '../../Models/category.dart';

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
          ItemBuilder.buildBlankIconButton(context),
          const SizedBox(width: 5),
        ],
      ),
      body: _buildBody(),
    );
  }

  _buildBody() {
    return EasyRefresh(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtil.isLandscape() ? 20 : 16, vertical: 10),
        children: [
          ItemBuilder.buildCaptionItem(context: context, title: "分类列表"),
          ...categories.map((e) => _buildCategoryItem(e)),
        ],
      ),
    );
  }

  _buildCategoryItem(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: ItemBuilder.buildCaptionItem(
              context: context,
              title: category.title,
            ),
          ),
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icons.edit_rounded,
            onTap: () {

            },
          ),
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icons.delete_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("删除分类"),
                    content: Text("确定要删除分类${category.title}吗？"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("取消"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await CategoryDao.deleteCategory(category);
                          getCategories();
                          Navigator.pop(context);
                        },
                        child: Text("确定"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
