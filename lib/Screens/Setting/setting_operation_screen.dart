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
import 'package:provider/provider.dart';

import '../../Database/token_dao.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';
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

class _OperationSettingScreenState
    extends BaseDynamicState<OperationSettingScreen>
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
  int autoMinimizeAfterClickToCopyOption = ChewieHiveUtil.getInt(
      CloudOTPHiveUtil.autoMinimizeAfterClickToCopyOptionKey,
      defaultValue: 0);
  bool autoHideCode = ChewieHiveUtil.getBool(CloudOTPHiveUtil.autoHideCodeKey);
  bool defaultHideCode =
      ChewieHiveUtil.getBool(CloudOTPHiveUtil.defaultHideCodeKey);
  bool dragToReorder = ChewieHiveUtil.getBool(CloudOTPHiveUtil.dragToReorderKey,
      defaultValue: !ResponsiveUtil.isMobile());
  bool showTray = ChewieHiveUtil.getBool(ChewieHiveUtil.showTrayKey);

  @override
  void initState() {
    super.initState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.operationSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscape(),
      padding: widget.padding,
      children: [
        _operationSettings(),
        _copyOperationSettings(),
        _otherSettings(),
        const SizedBox(height: 30),
      ],
    );
  }

  _operationSettings() {
    return SearchableCaptionItem(
      title: appLocalizations.tokenOperationSettings,
      children: [
        CheckboxItem(
          value: autoDisplayNextCode,
          title: appLocalizations.autoDisplayNextCode,
          description: appLocalizations.autoDisplayNextCodeTip,
          onTap: () {
            setState(() {
              autoDisplayNextCode = !autoDisplayNextCode;
              appProvider.autoDisplayNextCode = autoDisplayNextCode;
            });
          },
        ),
        CheckboxItem(
          value: autoHideCode,
          title: appLocalizations.autoHideCode,
          description: appLocalizations.autoHideCodeTip,
          onTap: () {
            setState(() {
              autoHideCode = !autoHideCode;
              appProvider.autoHideCode = autoHideCode;
            });
          },
        ),
        CheckboxItem(
          value: defaultHideCode,
          title: appLocalizations.defaultHideCode,
          description: appLocalizations.defaultHideCodeTip,
          onTap: () {
            setState(() {
              defaultHideCode = !defaultHideCode;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.defaultHideCodeKey, defaultHideCode);
            });
          },
        ),
      ],
    );
  }

  _copyOperationSettings() {
    return SearchableCaptionItem(
      title: appLocalizations.tokenCopyOperationSettings,
      children: [
        CheckboxItem(
          value: clipToCopy,
          title: appLocalizations.clickToCopy,
          description: appLocalizations.clickToCopyTip,
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
            title: appLocalizations.autoCopyNextCode,
            description: appLocalizations.autoCopyNextCodeTip,
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
            title: appLocalizations.autoMinimizeAfterClickToCopy,
            description: appLocalizations.autoMinimizeAfterClickToCopyTip,
            onTap: () {
              setState(() {
                autoMinimizeAfterClickToCopy = !autoMinimizeAfterClickToCopy;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.autoMinimizeAfterClickToCopyKey,
                    autoMinimizeAfterClickToCopy);
              });
            },
          ),
        if (ResponsiveUtil.isDesktop() &&
            clipToCopy &&
            autoMinimizeAfterClickToCopy &&
            showTray)
          InlineSelectionItem<SelectionItemModel<int>>(
            title: appLocalizations.autoMinimizeAfterClickToCopyOption,
            selections: [
              SelectionItemModel(
                  appLocalizations.minimizeWindowAfterClickToCopy, 0),
              SelectionItemModel(
                  appLocalizations.minimizeToTrayAfterClickToCopy, 1),
            ],
            hint: appLocalizations.chooseAutoMinimizeAfterClickToCopyOption,
            selected: SelectionItemModel(
                autoMinimizeAfterClickToCopyOption == 0
                    ? appLocalizations.minimizeWindowAfterClickToCopy
                    : appLocalizations.minimizeToTrayAfterClickToCopy,
                autoMinimizeAfterClickToCopyOption),
            onChanged: (item) {
              setState(() {
                autoMinimizeAfterClickToCopyOption = item?.value ?? 0;
                ChewieHiveUtil.put(
                    CloudOTPHiveUtil.autoMinimizeAfterClickToCopyOptionKey,
                    autoMinimizeAfterClickToCopyOption);
              });
            },
          ),
      ],
    );
  }

  _otherSettings() {
    return SearchableCaptionItem(
      title: appLocalizations.otherOperationSettings,
      children: [
        EntryItem(
          title: appLocalizations.resetCopyTimes,
          description: appLocalizations.resetCopyTimesTip,
          onTap: () async {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.resetCopyTimesTitle,
              message: appLocalizations.resetCopyTimesConfirmMessage,
              onTapConfirm: () async {
                await TokenDao.resetTokenCopyTimes();
                homeScreenState?.resetCopyTimes();
                IToast.showTop(appLocalizations.resetSuccess);
              },
              onTapCancel: () {},
            );
          },
        ),
        CheckboxItem(
          value: dragToReorder,
          title: appLocalizations.dragToReorder,
          description: appLocalizations.dragToReorderTip,
          onTap: () {
            setState(() {
              dragToReorder = !dragToReorder;
              appProvider.dragToReorder = dragToReorder;
              ChewieHiveUtil.put(
                  CloudOTPHiveUtil.dragToReorderKey, dragToReorder);
            });
          },
        ),
        CheckboxItem(
          value: autoFocusSearchBar,
          title: appLocalizations.autoFocusSearchBar,
          description: appLocalizations.autoFocusSearchBarTip,
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
