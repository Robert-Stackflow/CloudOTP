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
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/aliyundrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/box_service_screen.dart';
import 'package:cloudotp/Screens/Backup/dropbox_service_screen.dart';
import 'package:cloudotp/Screens/Backup/googledrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/huawei_service_screen.dart';
import 'package:cloudotp/Screens/Backup/onedrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/s3_service_screen.dart';
import 'package:cloudotp/Screens/Backup/webdav_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../Setting/base_setting_screen.dart';

class CloudServiceScreen extends BaseSettingScreen {
  const CloudServiceScreen({
    super.key,
    this.showBack = true,
  });

  final bool showBack;

  static const String routeName = "/service/cloud";

  @override
  State<CloudServiceScreen> createState() => _CloudServiceScreenState();
}

class _CloudServiceScreenState extends BaseDynamicState<CloudServiceScreen>
    with TickerProviderStateMixin {
  final GroupButtonController _typeController = GroupButtonController();
  CloudServiceType _currentType = CloudServiceType.Webdav;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 8,
      vsync: this,
    );
    _typeController.selectIndex(_currentType.index);
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder.buildSettingScreen(
      context: context,
      padding: widget.padding,
      showTitleBar: widget.showTitleBar,
      title: appLocalizations.cloudBackupServiceSetting,
      showBack: widget.showBack,
      titleLeftMargin: widget.showBack ? 5 : 15,
      onTapBack: () {
        DialogNavigatorHelper.responsivePopPage();
      },
      overrideBody: _buildBody(),
      desktopActions: [
        ToolButton(
          context: context,
          icon: LucideIcons.shieldCheck,
          buttonSize: const Size(32, 32),
          onPressed: _showServerInfo,
          tooltipPosition: TooltipPosition.bottom,
          tooltip: appLocalizations.cloudOAuthDialogTitle,
        ),
      ],
      actions: [
        CircleIconButton(
          icon: Icon(
            LucideIcons.shieldCheck,
            color: ChewieTheme.iconColor,
          ),
          onTap: _showServerInfo,
        ),
      ],
    );
  }

  _showServerInfo() {
    Utils.showQAuthDialog(context, true);
  }

  _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        _typeInfo(),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: tabController,
            children: const [
              OneDriveServiceScreen(),
              DropboxServiceScreen(),
              WebDavServiceScreen(),
              S3CloudServiceScreen(),
              GoogleDriveServiceScreen(),
              BoxServiceScreen(),
              AliyunDriveServiceScreen(),
              HuaweiCloudServiceScreen(),
            ],
          ),
        ),
      ],
    );
  }

  _typeInfo() {
    return ItemBuilder.buildGroupTile(
      context: context,
      controller: _typeController,
      constraintWidth: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      buttons: CloudServiceType.toEnableStrings(),
      onSelected: (value, index, isSelected) {
        setState(() {
          _currentType = index.toCloudServiceType;
        });
        tabController.animateTo(index);
      },
      title: '',
    );
  }
}
