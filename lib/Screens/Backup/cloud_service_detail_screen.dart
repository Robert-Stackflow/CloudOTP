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
import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Models/cloud_service_config.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import 'aliyundrive_service_screen.dart';
import 'box_service_screen.dart';
import 'dropbox_service_screen.dart';
import 'googledrive_service_screen.dart';
import 'huawei_service_screen.dart';
import 'onedrive_service_screen.dart';
import 's3_service_screen.dart';
import 'webdav_service_screen.dart';

Widget buildCloudServiceScreen(
  CloudServiceConfig config, {
  VoidCallback? onTitleChanged,
}) {
  switch (config.type) {
    case CloudServiceType.Webdav:
      return WebDavServiceScreen(
        configId: config.id,
        onTitleChanged: onTitleChanged,
      );
    case CloudServiceType.S3Cloud:
      return S3CloudServiceScreen(
        configId: config.id,
        onTitleChanged: onTitleChanged,
      );
    case CloudServiceType.OneDrive:
      return OneDriveServiceScreen(configId: config.id);
    case CloudServiceType.Dropbox:
      return DropboxServiceScreen(configId: config.id);
    case CloudServiceType.GoogleDrive:
      return GoogleDriveServiceScreen(configId: config.id);
    case CloudServiceType.Box:
      return BoxServiceScreen(configId: config.id);
    case CloudServiceType.AliyunDrive:
      return AliyunDriveServiceScreen(configId: config.id);
    case CloudServiceType.HuaweiCloud:
      return HuaweiCloudServiceScreen(configId: config.id);
  }
}

class CloudServiceDetailScreen extends StatefulWidget {
  const CloudServiceDetailScreen({
    super.key,
    required this.configId,
  });

  final int configId;

  static const String routeName = "/service/cloud/detail";

  @override
  State<CloudServiceDetailScreen> createState() =>
      _CloudServiceDetailScreenState();
}

class _CloudServiceDetailScreenState extends State<CloudServiceDetailScreen> {
  CloudServiceConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await CloudServiceConfigDao.getConfigById(widget.configId);
    if (!mounted) return;
    setState(() {
      _config = config;
      _loading = false;
    });
  }

  void _confirmDeleteConfig(CloudServiceConfig config) {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.deleteCloudService,
      message: appLocalizations.deleteCloudServiceMessage(config.displayName),
      onTapConfirm: () async {
        await CloudServiceConfigDao.deleteConfig(config.id);
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return ItemBuilder.buildSettingScreen(
      context: context,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      showTitleBar: true,
      title: config?.displayName ?? appLocalizations.cloudBackupServiceSetting,
      showBack: true,
      onTapBack: () => Navigator.of(context).pop(),
      desktopActions: [
        if (config?.type.allowMultiple ?? false)
          ToolButton(
            context: context,
            icon: LucideIcons.trash2,
            buttonSize: const Size(32, 32),
            onPressed: () => _confirmDeleteConfig(config!),
            tooltipPosition: TooltipPosition.bottom,
            tooltip: appLocalizations.deleteCloudService,
          ),
        ToolButton(
          context: context,
          icon: LucideIcons.shieldCheck,
          buttonSize: const Size(32, 32),
          onPressed: () => Utils.showQAuthDialog(context, true),
          tooltipPosition: TooltipPosition.bottom,
          tooltip: appLocalizations.cloudOAuthDialogTitle,
        ),
      ],
      actions: [
        if (config?.type.allowMultiple ?? false)
          CircleIconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onTap: () => _confirmDeleteConfig(config!),
          ),
        CircleIconButton(
          icon: Icon(
            LucideIcons.shieldCheck,
            color: ChewieTheme.iconColor,
          ),
          onTap: () => Utils.showQAuthDialog(context, true),
        ),
      ],
      overrideBody: _buildBody(config),
    );
  }

  Widget _buildBody(CloudServiceConfig? config) {
    if (_loading) {
      return ItemBuilder.buildLoadingDialog(
        context: context,
        background: Colors.transparent,
        text: appLocalizations.cloudConnecting,
        mainAxisAlignment: MainAxisAlignment.start,
        topPadding: 100,
      );
    }
    if (config == null) {
      return Center(child: Text(appLocalizations.cloudUnknownError));
    }
    return KeyedSubtree(
      key: ValueKey(config.id),
      child: buildCloudServiceScreen(
        config,
        onTitleChanged: _loadConfig,
      ),
    );
  }
}
