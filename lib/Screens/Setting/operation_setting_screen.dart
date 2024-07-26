import 'package:flutter/material.dart';
import 'package:cloudotp/Widgets/Custom/no_shadow_scroll_behavior.dart';

import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class OperationSettingScreen extends StatefulWidget {
  const OperationSettingScreen({super.key});

  static const String routeName = "/setting/operation";

  @override
  State<OperationSettingScreen> createState() => _OperationSettingScreenState();
}

class _OperationSettingScreenState extends State<OperationSettingScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.operationSetting, context: context),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ScrollConfiguration(
            behavior: NoShadowScrollBehavior(),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              children: [
                const SizedBox(height: 10),
                ItemBuilder.buildEntryItem(
                  context: context,
                  topRadius: true,
                  title: "默认导航页面",
                  tip: "首页",
                  onTap: () {},
                ),
                ItemBuilder.buildRadioItem(
                  value: true,
                  context: context,
                  bottomRadius: true,
                  title: "记录导航页面",
                  description: "自动选择最后退出APP时的导航页面",
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                ItemBuilder.buildCaptionItem(
                    context: context, title: "详情页快捷操作"),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "双击页面",
                  tip: "喜欢",
                  description: "喜欢，收藏，推荐，保存当前图片，保存所有图片",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "触顶滑动",
                  tip: "刷新页面",
                  description: "刷新页面，上一篇文章",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "音量键",
                  tip: "切换上下张图片",
                  description: "切换上下张图片，上下篇文章",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "大图双击",
                  tip: "保存图片",
                  description: "保存图片，查看原图，复制链接",
                  bottomRadius: true,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                ItemBuilder.buildCaptionItem(context: context, title: "自动操作"),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "下载图片时",
                  tip: "标记为星标",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "喜欢文章时",
                  tip: "分享文章",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "推荐文章时",
                  tip: "分享文章",
                  onTap: () {},
                ),
                ItemBuilder.buildEntryItem(
                  context: context,
                  title: "收藏文章时",
                  tip: "分享文章",
                  bottomRadius: true,
                  onTap: () {},
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
