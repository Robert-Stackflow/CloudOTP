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
import 'package:cloudotp/Screens/Backup/dropbox_service_screen.dart';
import 'package:cloudotp/Screens/Backup/onedrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/s3_service_screen.dart';
import 'package:cloudotp/Screens/Backup/webdav_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../generated/l10n.dart';

class CloudServiceScreen extends StatefulWidget {
  const CloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/cloud";

  @override
  State<CloudServiceScreen> createState() => _CloudServiceScreenState();
}

class _CloudServiceScreenState extends State<CloudServiceScreen>
    with TickerProviderStateMixin {
  final GroupButtonController _typeController = GroupButtonController();
  CloudServiceType _currentType = CloudServiceType.Webdav;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 4,
      vsync: this,
    );
    _typeController.selectIndex(_currentType.index);
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        showBack: !ResponsiveUtil.isLandscape(),
        titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 5,
        onTapBack: () {
          Navigator.pop(context);
        },
        title: S.current.cloudBackupServiceSetting,
        actions: const [
          BlankIconButton(),
        ],
      ),
      body: _buildBody(),
    );
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
