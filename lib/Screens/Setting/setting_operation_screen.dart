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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Database/token_dao.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../generated/l10n.dart';
import 'base_setting_screen.dart';

class OperationSettingScreen extends BaseSettingScreen {
  const OperationSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/operation";

  @override
  State<OperationSettingScreen> createState() => _OperationSettingScreenState();
}

class _OperationSettingScreenState extends State<OperationSettingScreen>
    with TickerProviderStateMixin {
  bool clipToCopy = ChewieHiveUtil.getBool(CloudOTPHiveUtil.clickToCopyKey);
  bool autoCopyNextCode =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoCopyNextCodeKey);
  bool autoDisplayNextCode =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoDisplayNextCodeKey);
  bool autoFocusSearchBar = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.autoFocusSearchBarKey,
      defaultValue: false);
  bool autoMinimizeAfterClickToCopy = ChewieHiveUtil.getBool(
      CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey,
      defaultValue: false);
  bool autoHideCode = ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoHideCodeKey);
  bool defaultHideCode =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.defaultHideCodeKey);
  bool dragToReorder = ChewieHiveUtil.getBool(CloudOTPHiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());

  @override
  void initState() {
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: S.current.operationSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        _operationSettings(),
        _otherSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  _operationSettings() {
    return SearchableCaptionItem(
      title: "令牌操作",
      children: [
        CheckboxItem(
          value: autoDisplayNextCode,
          title: S.current.autoDisplayNextCode,
          description: S.current.autoDisplayNextCodeTip,
          onTap: () {
            setState(() {
              autoDisplayNextCode = !autoDisplayNextCode;
              appProvider.autoDisplayNextCode = autoDisplayNextCode;
            });
          },
        ),
        CheckboxItem(
          value: clipToCopy,
          title: S.current.clickToCopy,
          description: S.current.clickToCopyTip,
          onTap: () {
            setState(() {
              clipToCopy = !clipToCopy;
              ChewieHiveUtil.put(CloudOTPHiveUtil.clickToCopyKey, clipToCopy);
            });
          },
        ),
        if (clipToCopy)
          CheckboxItem(
            disabled: !clipToCopy,
            value: autoCopyNextCode,
            title: S.current.autoCopyNextCode,
            description: S.current.autoCopyNextCodeTip,
            onTap: () {
              setState(() {
                autoCopyNextCode = !autoCopyNextCode;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.autoCopyNextCodeKey, autoCopyNextCode);
              });
            },
          ),
        if (clipToCopy)
          CheckboxItem(
            disabled: !clipToCopy,
            value: autoMinimizeAfterClickToCopy,
            title: S.current.autoMinimizeAfterClickToCopy,
            description: S.current.autoMinimizeAfterClickToCopyTip,
            onTap: () {
              setState(() {
                autoMinimizeAfterClickToCopy = !autoMinimizeAfterClickToCopy;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey,
                    autoMinimizeAfterClickToCopy);
              });
            },
          ),
        CheckboxItem(
          value: autoHideCode,
          title: S.current.autoHideCode,
          description: S.current.autoHideCodeTip,
          onTap: () {
            setState(() {
              autoHideCode = !autoHideCode;
              appProvider.autoHideCode = autoHideCode;
            });
          },
        ),
        CheckboxItem(
          value: defaultHideCode,
          title: S.current.defaultHideCode,
          description: S.current.defaultHideCodeTip,
          onTap: () {
            setState(() {
              defaultHideCode = !defaultHideCode;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.defaultHideCodeKey, defaultHideCode);
            });
          },
        ),
        CheckboxItem(
          value: dragToReorder,
          title: S.current.dragToReorder,
          description: S.current.dragToReorderTip,
          onTap: () {
            setState(() {
              dragToReorder = !dragToReorder;
              appProvider.dragToReorder = dragToReorder;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.dragToReorderKey, dragToReorder);
            });
          },
        ),

      ],
    );
  }

  _otherSettings() {
    return SearchableCaptionItem(
      title: "其他",
      children: [
        EntryItem(
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
        CheckboxItem(
          value: autoFocusSearchBar,
          title: S.current.autoFocusSearchBar,
          description: S.current.autoFocusSearchBarTip,
          onTap: () {
            setState(() {
              autoFocusSearchBar = !autoFocusSearchBar;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.autoFocusSearchBarKey, autoFocusSearchBar);
            });
          },
        ),
      ],
    );
  }
}
