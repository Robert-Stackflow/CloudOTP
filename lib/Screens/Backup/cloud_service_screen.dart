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
import 'package:cloudotp/Database/config_dao.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/Screens/Backup/aliyundrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/box_service_screen.dart';
import 'package:cloudotp/Screens/Backup/dropbox_service_screen.dart';
import 'package:cloudotp/Screens/Backup/googledrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/huawei_service_screen.dart';
import 'package:cloudotp/Screens/Backup/onedrive_service_screen.dart';
import 'package:cloudotp/Screens/Backup/s3_service_screen.dart';
import 'package:cloudotp/Screens/Backup/webdav_service_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_navigation_screen.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/cloud_service_config_dao.dart';
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
  final GroupButtonController _categoryController = GroupButtonController();
  final GroupButtonController _configController = GroupButtonController();
  CloudServiceCategory _currentCategory = CloudServiceCategory.oauth;
  List<CloudServiceConfig> _configs = [];
  int _selectedConfigIndex = 0;
  String _autoBackupPassword = "";
  bool _loading = true;

  bool get canBackup => _autoBackupPassword.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _categoryController.selectIndex(_currentCategory.index);
    ConfigDao.getConfig().then((config) {
      _autoBackupPassword = config.backupPassword;
      _loadConfigs();
    });
  }

  Future<void> _loadConfigs() async {
    final configs = await CloudServiceConfigDao.getConfigs();
    final existingTypes = configs.map((c) => c.type).toSet();
    for (final type in CloudServiceType.values) {
      if (!type.allowMultiple && !existingTypes.contains(type)) {
        final config = CloudServiceConfig.init(type: type);
        await CloudServiceConfigDao.insertConfig(config);
        configs.add(config);
      }
    }
    for (final config in configs) {
      if (config.type.allowMultiple && config.title.isEmpty) {
        config.title = appLocalizations.cloudDefaultConfigTitle;
        await CloudServiceConfigDao.updateConfig(config);
      }
    }
    if (mounted) {
      setState(() {
        _configs = configs;
        _loading = false;
        _clampSelectedIndex();
      });
    }
  }

  List<CloudServiceConfig> get _filteredConfigs {
    return _configs
        .where((c) => c.type.category == _currentCategory)
        .toList();
  }

  CloudServiceConfig? get _selectedConfig {
    final filtered = _filteredConfigs;
    if (filtered.isEmpty || _selectedConfigIndex >= filtered.length) return null;
    return filtered[_selectedConfigIndex];
  }

  void _clampSelectedIndex() {
    final filtered = _filteredConfigs;
    if (_selectedConfigIndex >= filtered.length) {
      _selectedConfigIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }
    _configController.selectIndex(_selectedConfigIndex);
  }

  Widget _buildServiceScreen(CloudServiceConfig config) {
    switch (config.type) {
      case CloudServiceType.Webdav:
        return WebDavServiceScreen(
          configId: config.id,
          onTitleChanged: () => _refreshTitle(config.id),
        );
      case CloudServiceType.S3Cloud:
        return S3CloudServiceScreen(
          configId: config.id,
          onTitleChanged: () => _refreshTitle(config.id),
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

  void _refreshTitle(int configId) async {
    final updated = await CloudServiceConfigDao.getConfigById(configId);
    if (updated != null && mounted) {
      final index = _configs.indexWhere((c) => c.id == configId);
      if (index >= 0) {
        setState(() {
          _configs[index] = updated;
        });
      }
    }
  }

  Future<void> _addCloudService() async {
    final types = _currentCategory.types;
    if (types.length == 1) {
      await _createConfig(types.first);
      return;
    }
    final existingTypes = _configs.map((c) => c.type).toSet();
    final items = types.map((type) {
      final alreadyExists = existingTypes.contains(type);
      final disabled = !type.allowMultiple && alreadyExists;
      return _AddServiceItem(type: type, disabled: disabled);
    }).toList();

    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (dialogContext) => _AddServiceBottomSheet(
        items: items,
        onSelected: (type) async {
          Navigator.of(dialogContext).pop();
          await _createConfig(type);
        },
      ),
    );
  }

  Future<void> _createConfig(CloudServiceType type) async {
    final config = CloudServiceConfig.init(type: type);
    config.title = appLocalizations.cloudDefaultConfigTitle;
    await CloudServiceConfigDao.insertConfig(config);
    await _loadConfigs();
    final filtered = _filteredConfigs;
    final newIndex = filtered.indexWhere((c) => c.id == config.id);
    if (newIndex >= 0) {
      setState(() {
        _selectedConfigIndex = newIndex;
        _configController.selectIndex(newIndex);
      });
    }
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
    if (!canBackup) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ChewieTheme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.keyRound,
                  size: 26,
                  color: ChewieTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations.haveNotSetBackupPassword,
                style: ChewieTheme.bodyMedium.copyWith(
                  color: ChewieTheme.bodyMedium.color?.withAlpha(150),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              RoundIconTextButton(
                height: 38,
                text: appLocalizations.goToSetBackupPassword,
                background: ChewieTheme.primaryColor,
                onPressed: () {
                  if (ResponsiveUtil.isLandscapeLayout()) {
                    RouteUtil.pushDialogRoute(
                        context,
                        const SettingNavigationScreen(initPageIndex: 3));
                  } else {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      const BackupSettingScreen(
                          jumpToAutoBackupPassword: true),
                      onThen: (_) {
                        ConfigDao.getConfig().then((config) {
                          setState(() {
                            _autoBackupPassword = config.backupPassword;
                          });
                        });
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return ItemBuilder.buildLoadingDialog(
        context: context,
        background: Colors.transparent,
        text: appLocalizations.cloudConnecting,
        mainAxisAlignment: MainAxisAlignment.start,
        topPadding: 100,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        _categorySelector(),
        const SizedBox(height: 10),
        _configSelector(),
        const SizedBox(height: 10),
        Expanded(child: _configContent()),
      ],
    );
  }

  _categorySelector() {
    return ItemBuilder.buildGroupTile(
      context: context,
      controller: _categoryController,
      constraintWidth: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      buttons: CloudServiceCategory.values.map((c) => c.label).toList(),
      onSelected: (value, index, isSelected) {
        setState(() {
          _currentCategory = CloudServiceCategory.values[index];
          _selectedConfigIndex = 0;
          _clampSelectedIndex();
        });
      },
      title: '',
    );
  }

  _configSelector() {
    final filtered = _filteredConfigs;
    final labels = filtered.map((c) => c.type.allowMultiple ? c.title : c.type.label).toList();
    final showAdd = _currentCategory.allowMultiple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (labels.isNotEmpty)
                ItemBuilder.buildGroupButtons(
                  buttons: labels,
                  controller: _configController,
                  constraintWidth: false,
                  radius: 8,
                  onSelected: (value, index, isSelected) {
                    setState(() {
                      _selectedConfigIndex = index;
                    });
                  },
                  trailingBuilder: _currentCategory.allowMultiple
                      ? (index, selected) => GestureDetector(
                            onTap: () => _confirmDeleteConfig(filtered[index]),
                            child: Icon(
                              LucideIcons.x,
                              size: 12,
                              color: selected ? Colors.white70 : ChewieTheme.iconColor,
                            ),
                          )
                      : null,
                ),
              if (showAdd) ...[
                if (labels.isNotEmpty) const SizedBox(width: 6),
                InkWell(
                  onTap: _addCloudService,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ChewieTheme.borderColor,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(LucideIcons.plus, size: 16, color: ChewieTheme.iconColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteConfig(CloudServiceConfig config) async {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.deleteCloudService,
      message: appLocalizations.deleteCloudServiceMessage(config.displayName),
      onTapConfirm: () async {
        await CloudServiceConfigDao.deleteConfig(config.id);
        await _loadConfigs();
      },
    );
  }

  _configContent() {
    final config = _selectedConfig;
    if (config == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ChewieTheme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.cloudOff,
                  size: 26,
                  color: ChewieTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations.noCloudServiceConfigured,
                style: ChewieTheme.bodyMedium.copyWith(
                  color: ChewieTheme.bodyMedium.color?.withAlpha(150),
                ),
                textAlign: TextAlign.center,
              ),
              if (_currentCategory.allowMultiple) ...[
                const SizedBox(height: 16),
                RoundIconTextButton(
                  height: 38,
                  text: appLocalizations.addCloudService,
                  background: ChewieTheme.primaryColor,
                  onPressed: _addCloudService,
                ),
              ],
            ],
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: ValueKey(config.id),
      child: _buildServiceScreen(config),
    );
  }
}

class _AddServiceItem {
  final CloudServiceType type;
  final bool disabled;

  _AddServiceItem({required this.type, required this.disabled});
}

class _AddServiceBottomSheet extends StatelessWidget {
  final List<_AddServiceItem> items;
  final Function(CloudServiceType) onSelected;

  const _AddServiceBottomSheet({
    required this.items,
    required this.onSelected,
  });

  Color get _accent => ChewieTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: ChewieDimens.defaultRadius,
              bottom: ResponsiveUtil.isWideDevice()
                  ? ChewieDimens.defaultRadius
                  : Radius.zero,
            ),
            color: ChewieTheme.scaffoldBackgroundColor,
            border: ChewieTheme.responsiveBorder,
            boxShadow: ChewieTheme.defaultBoxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildGrid(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _accent.withAlpha(30),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(LucideIcons.cloudCog, color: _accent, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            appLocalizations.addCloudService,
            style:
                ChewieTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = i + 1 < items.length ? items[i + 1] : null;
      rows.add(Row(
        children: [
          Expanded(child: _buildCard(first)),
          const SizedBox(width: 10),
          Expanded(
            child: second != null
                ? _buildCard(second)
                : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildCard(_AddServiceItem item) {
    return GestureDetector(
      onTap: item.disabled ? null : () => onSelected(item.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: item.disabled
              ? ChewieTheme.canvasColor.withAlpha(120)
              : ChewieTheme.canvasColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChewieTheme.borderColor,
            width: 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.type.label,
                style: ChewieTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: item.disabled
                      ? ChewieTheme.titleLarge.color?.withAlpha(100)
                      : ChewieTheme.titleLarge.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.disabled)
              Icon(LucideIcons.check, size: 14,
                  color: _accent.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}
