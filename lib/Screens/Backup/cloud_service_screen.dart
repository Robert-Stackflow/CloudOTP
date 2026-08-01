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
import 'package:cloudotp/Screens/Setting/setting_backup_screen.dart';
import 'package:cloudotp/Screens/Setting/setting_navigation_screen.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../Setting/base_setting_screen.dart';
import 'cloud_service_detail_screen.dart';

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
  List<CloudServiceConfig> _configs = [];
  int? _selectedConfigId;
  String _autoBackupPassword = "";
  bool _loading = true;

  bool get canBackup => _autoBackupPassword.isNotEmpty;

  @override
  void initState() {
    super.initState();
    ConfigDao.getConfig().then((config) {
      _autoBackupPassword = config.backupPassword;
      _loadConfigs();
    });
  }

  Future<void> _loadConfigs() async {
    final configs = await CloudServiceConfigDao.getConfigs();
    if (mounted) {
      setState(() {
        _configs = configs;
        _loading = false;
      });
    }
  }

  CloudServiceConfig? get _selectedConfig {
    for (final config in _configs) {
      if (config.id == _selectedConfigId) return config;
    }
    return null;
  }

  Widget _buildServiceScreen(CloudServiceConfig config) {
    return buildCloudServiceScreen(
      config,
      onTitleChanged: () => _refreshTitle(config.id),
    );
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
    final items = CloudServiceType.values.map((type) {
      final disabled = !type.allowMultiple &&
          _configs
              .any((config) => config.type == type && config.hasConfiguration);
      return _AddServiceItem(type: type, disabled: disabled);
    }).toList();

    BottomSheetBuilder.showBottomSheet(
      context,
      responsive: true,
      (dialogContext) => _AddServiceBottomSheet(
        items: items,
        onSelected: (type) async {
          Navigator.of(dialogContext).pop();
          await _createOrOpenConfig(type);
        },
      ),
    );
  }

  Future<void> _createOrOpenConfig(CloudServiceType type) async {
    if (!type.allowMultiple) {
      for (final existing in _configs) {
        if (existing.type == type) {
          _openConfig(existing);
          return;
        }
      }
    }
    final config = CloudServiceConfig.init(type: type);
    config.title = appLocalizations.cloudDefaultConfigTitle;
    await CloudServiceConfigDao.insertConfig(config);
    await _loadConfigs();
    if (mounted) _openConfig(config);
  }

  void _openConfig(CloudServiceConfig config) {
    if (ResponsiveUtil.isLandscapeLayout()) {
      setState(() => _selectedConfigId = config.id);
      return;
    }
    RouteUtil.pushCupertinoRoute(
      context,
      CloudServiceDetailScreen(configId: config.id),
      onThen: (_) {
        if (!mounted) return;
        _selectedConfigId = null;
        _loadConfigs();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedConfig = canBackup ? _selectedConfig : null;
    final canDeleteSelected = selectedConfig?.type.allowMultiple ?? false;
    return ItemBuilder.buildSettingScreen(
      context: context,
      padding: widget.padding,
      showTitleBar: widget.showTitleBar,
      title: selectedConfig?.displayName ??
          appLocalizations.cloudBackupServiceSetting,
      showBack: widget.showBack,
      titleLeftMargin: widget.showBack ? 5 : 15,
      onTapBack: () {
        if (_selectedConfigId != null) {
          setState(() => _selectedConfigId = null);
          _loadConfigs();
        } else {
          DialogNavigatorHelper.responsivePopPage();
        }
      },
      overrideBody: _buildBody(),
      desktopActions: [
        if (canDeleteSelected)
          ToolButton(
            context: context,
            icon: LucideIcons.trash2,
            buttonSize: const Size(32, 32),
            onPressed: () => _confirmDeleteConfig(selectedConfig!),
            tooltipPosition: TooltipPosition.bottom,
            tooltip: appLocalizations.deleteCloudService,
          ),
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
        if (canDeleteSelected)
          CircleIconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onTap: () => _confirmDeleteConfig(selectedConfig!),
          ),
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
    if (_loading) {
      return ItemBuilder.buildLoadingDialog(
        context: context,
        background: Colors.transparent,
        text: appLocalizations.cloudConnecting,
        mainAxisAlignment: MainAxisAlignment.start,
        topPadding: 100,
      );
    }
    if (!canBackup) return _buildBackupPasswordPlaceholder();
    final selectedConfig = _selectedConfig;
    if (selectedConfig != null) {
      return _buildConfigDetails(selectedConfig);
    }
    return _buildOverview();
  }

  List<CloudServiceConfig> get _visibleConfigs => _configs
      .where((config) => config.type.allowMultiple || config.hasConfiguration)
      .toList();

  Widget _buildOverview() {
    final configs = _visibleConfigs;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          appLocalizations.cloudOverviewDescription,
          style: ChewieTheme.bodyMedium.copyWith(
            color: ChewieTheme.bodyMedium.color?.withAlpha(170),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          appLocalizations.cloudConfiguredServices,
          style: ChewieTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (configs.isEmpty) _buildEmptyOverview(),
        if (configs.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: configs
                    .map(
                      (config) => SizedBox(
                        width: cardWidth,
                        child: _buildServiceCard(config),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        const SizedBox(height: 18),
        RoundIconTextButton(
          height: 42,
          width: double.infinity,
          icon: const Icon(LucideIcons.plus, size: 17, color: Colors.white),
          text: appLocalizations.addCloudService,
          background: ChewieTheme.primaryColor,
          onPressed: _addCloudService,
        ),
      ],
    );
  }

  Widget _buildEmptyOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChewieTheme.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.cloudOff,
            size: 30,
            color: ChewieTheme.primaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            appLocalizations.noCloudServiceConfigured,
            style: ChewieTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupPasswordPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: TipBanner(
            message: appLocalizations.notSetBackupPasswordTip,
            customIcon: LucideIcons.keyRound,
            padding: const EdgeInsets.all(16),
            actionSpacing: 14,
            action: RoundIconTextButton(
              height: 36,
              minHeight: 36,
              radius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              background: ChewieTheme.primaryColor,
              icon: const Icon(
                LucideIcons.keyRound,
                size: 16,
                color: Colors.white,
              ),
              text: appLocalizations.setAutoBackupPassword,
              onPressed: _openBackupPasswordSettings,
            ),
          ),
        ),
      ),
    );
  }

  void _openBackupPasswordSettings() {
    void refreshPassword(dynamic _) {
      ConfigDao.getConfig().then((config) {
        if (!mounted) return;
        setState(() => _autoBackupPassword = config.backupPassword);
      });
    }

    if (ResponsiveUtil.isLandscapeLayout()) {
      RouteUtil.pushDialogRoute(
        context,
        const SettingNavigationScreen(initPageIndex: 3),
        onThen: refreshPassword,
      );
    } else {
      RouteUtil.pushCupertinoRoute(
        context,
        const BackupSettingScreen(jumpToAutoBackupPassword: true),
        onThen: refreshPassword,
      );
    }
  }

  Widget _buildServiceCard(CloudServiceConfig config) {
    final needsSetup = !config.hasConfiguration;
    final statusText = needsSetup
        ? appLocalizations.cloudStatusNeedsSetup
        : config.enabled
            ? appLocalizations.cloudStatusReady
            : appLocalizations.cloudStatusDisabled;
    final statusColor = needsSetup
        ? Colors.orange
        : config.enabled
            ? Colors.green
            : Colors.grey;
    return Material(
      color: ChewieTheme.canvasColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openConfig(config),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChewieTheme.borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ChewieTheme.primaryColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(config.type),
                  size: 21,
                  color: ChewieTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChewieTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: ChewieTheme.iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(CloudServiceType type) {
    switch (type) {
      case CloudServiceType.Webdav:
        return LucideIcons.server;
      case CloudServiceType.S3Cloud:
        return LucideIcons.database;
      case CloudServiceType.OneDrive:
      case CloudServiceType.GoogleDrive:
      case CloudServiceType.Dropbox:
      case CloudServiceType.HuaweiCloud:
      case CloudServiceType.Box:
      case CloudServiceType.AliyunDrive:
        return LucideIcons.cloud;
    }
  }

  Future<void> _confirmDeleteConfig(CloudServiceConfig config) async {
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.deleteCloudService,
      message: appLocalizations.deleteCloudServiceMessage(config.displayName),
      onTapConfirm: () async {
        await CloudServiceConfigDao.deleteConfig(config.id);
        _selectedConfigId = null;
        await _loadConfigs();
      },
    );
  }

  Widget _buildConfigDetails(CloudServiceConfig config) {
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
            child:
                second != null ? _buildCard(second) : const SizedBox.shrink(),
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
              Icon(LucideIcons.check, size: 14, color: _accent.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}
