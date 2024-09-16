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

import 'package:cloudotp/Widgets/Dialog/dialog_builder.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import '../../Database/token_dao.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
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
  bool clipToCopy = HiveUtil.getBool(HiveUtil.clickToCopyKey);
  bool autoCopyNextCode = HiveUtil.getBool(HiveUtil.autoCopyNextCodeKey);
  bool autoDisplayNextCode = HiveUtil.getBool(HiveUtil.autoDisplayNextCodeKey);
  bool autoFocusSearchBar =
      HiveUtil.getBool(HiveUtil.autoFocusSearchBarKey, defaultValue: false);
  bool autoMinimizeAfterClickToCopy = HiveUtil.getBool(
      HiveUtil.autoMinimizeAfterClickToCopyKey,
      defaultValue: false);
  bool autoHideCode = HiveUtil.getBool(HiveUtil.autoHideCodeKey);
  bool defaultHideCode = HiveUtil.getBool(HiveUtil.defaultHideCodeKey);
  bool dragToReorder = HiveUtil.getBool(HiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());

  @override
  void initState() {
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ResponsiveUtil.isLandscape()
            ? ItemBuilder.buildSimpleAppBar(
                title: S.current.operationSetting,
                context: context,
                transparent: true,
              )
            : ItemBuilder.buildAppBar(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  S.current.operationSetting,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2),
                ),
                actions: [
                  ItemBuilder.buildBlankIconButton(context),
                  const SizedBox(width: 5),
                ],
              ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ..._operationSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _operationSettings() {
    return [
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoDisplayNextCode,
        topRadius: true,
        bottomRadius: true,
        title: S.current.autoDisplayNextCode,
        description: S.current.autoDisplayNextCodeTip,
        onTap: () {
          setState(() {
            autoDisplayNextCode = !autoDisplayNextCode;
            appProvider.autoDisplayNextCode = autoDisplayNextCode;
          });
        },
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: clipToCopy,
        topRadius: true,
        bottomRadius: !clipToCopy,
        title: S.current.clickToCopy,
        description: S.current.clickToCopyTip,
        onTap: () {
          setState(() {
            clipToCopy = !clipToCopy;
            HiveUtil.put(HiveUtil.clickToCopyKey, clipToCopy);
          });
        },
      ),
      Visibility(
        visible: clipToCopy,
        child: ItemBuilder.buildRadioItem(
          context: context,
          disabled: !clipToCopy,
          value: autoCopyNextCode,
          title: S.current.autoCopyNextCode,
          description: S.current.autoCopyNextCodeTip,
          onTap: () {
            setState(() {
              autoCopyNextCode = !autoCopyNextCode;
              HiveUtil.put(HiveUtil.autoCopyNextCodeKey, autoCopyNextCode);
            });
          },
        ),
      ),
      Visibility(
        visible: clipToCopy,
        child: ItemBuilder.buildRadioItem(
          context: context,
          disabled: !clipToCopy,
          bottomRadius: true,
          value: autoMinimizeAfterClickToCopy,
          title: S.current.autoMinimizeAfterClickToCopy,
          description: S.current.autoMinimizeAfterClickToCopyTip,
          onTap: () {
            setState(() {
              autoMinimizeAfterClickToCopy = !autoMinimizeAfterClickToCopy;
              HiveUtil.put(HiveUtil.autoMinimizeAfterClickToCopyKey,
                  autoMinimizeAfterClickToCopy);
            });
          },
        ),
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoHideCode,
        topRadius: true,
        title: S.current.autoHideCode,
        description: S.current.autoHideCodeTip,
        onTap: () {
          setState(() {
            autoHideCode = !autoHideCode;
            appProvider.autoHideCode = autoHideCode;
          });
        },
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: defaultHideCode,
        title: S.current.defaultHideCode,
        bottomRadius: true,
        description: S.current.defaultHideCodeTip,
        onTap: () {
          setState(() {
            defaultHideCode = !defaultHideCode;
            HiveUtil.put(HiveUtil.defaultHideCodeKey, defaultHideCode);
          });
        },
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: dragToReorder,
        title: S.current.dragToReorder,
        topRadius: true,
        description: S.current.dragToReorderTip,
        onTap: () {
          setState(() {
            dragToReorder = !dragToReorder;
            appProvider.dragToReorder = dragToReorder;
            HiveUtil.put(HiveUtil.dragToReorderKey, dragToReorder);
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        bottomRadius: true,
        title: S.current.resetCopyTimes,
        description: S.current.resetCopyTimesTip,
        onTap: () async {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.resetCopyTimesTitle,
            message: S.current.resetCopyTimesConfirmMessage,
            onTapConfirm: () async {
              await TokenDao.resetTokenCopyTimes();
              homeScreenState?.resetCopyTimes();
              IToast.showTop(S.current.resetSuccess);
            },
            onTapCancel: () {},
          );
        },
      ),
      const SizedBox(height: 10),
      ItemBuilder.buildRadioItem(
        context: context,
        value: autoFocusSearchBar,
        title: S.current.autoFocusSearchBar,
        description: S.current.autoFocusSearchBarTip,
        topRadius: true,
        bottomRadius: true,
        onTap: () {
          setState(() {
            autoFocusSearchBar = !autoFocusSearchBar;
            HiveUtil.put(HiveUtil.autoFocusSearchBarKey, autoFocusSearchBar);
          });
        },
      ),
    ];
  }
}
