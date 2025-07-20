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

import 'dart:typed_data';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/huawei_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/Backups/huawei_backups_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class HuaweiCloudServiceScreen extends StatefulWidget {
  const HuaweiCloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/huaweiCloud";

  @override
  State<HuaweiCloudServiceScreen> createState() =>
      _HuaweiCloudServiceScreenState();
}

class _HuaweiCloudServiceScreenState
    extends BaseDynamicState<HuaweiCloudServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  CloudServiceConfig? _huaweiCloudCloudServiceConfig;
  HuaweiCloudService? _huaweiCloudCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _huaweiCloudCloudServiceConfig!;

  CloudService get currentService => _huaweiCloudCloudService!;

  bool get _configInitialized {
    return _huaweiCloudCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Utils.showQAuthDialog(context));
  }

  loadConfig() async {
    _huaweiCloudCloudServiceConfig =
        await CloudServiceConfigDao.getHuaweiCloudConfig();
    if (_huaweiCloudCloudServiceConfig != null) {
      _sizeController.text = _huaweiCloudCloudServiceConfig!.size;
      _accountController.text = _huaweiCloudCloudServiceConfig!.account ?? "";
      _huaweiCloudCloudService = HuaweiCloudService(
        _huaweiCloudCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _huaweiCloudCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.HuaweiCloud);
      await CloudServiceConfigDao.insertConfig(_huaweiCloudCloudServiceConfig!);
      _huaweiCloudCloudService = HuaweiCloudService(
        _huaweiCloudCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_huaweiCloudCloudService != null) {
      _huaweiCloudCloudServiceConfig!.configured =
          await _huaweiCloudCloudService!.hasConfigured();
      _huaweiCloudCloudServiceConfig!.connected =
          await _huaweiCloudCloudService!.isConnected();
      if (_huaweiCloudCloudServiceConfig!.configured &&
          !_huaweiCloudCloudServiceConfig!.connected) {
        IToast.showTop(appLocalizations.cloudConnectionError);
      }
      updateConfig(_huaweiCloudCloudServiceConfig!);
    }
    inited = true;
    setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _huaweiCloudCloudServiceConfig = config;
      });
    }
    _sizeController.text = _huaweiCloudCloudServiceConfig!.size;
    _accountController.text = _huaweiCloudCloudServiceConfig!.account ?? "";
    CloudServiceConfigDao.updateConfig(_huaweiCloudCloudServiceConfig!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveUtil.isLinux()
        ? _buildUnsupportBody()
        : inited
            ? _buildBody()
            : ItemBuilder.buildLoadingDialog(
                context: context,
                background: Colors.transparent,
                text: appLocalizations.cloudConnecting,
                mainAxisAlignment: MainAxisAlignment.start,
                topPadding: 100,
              );
  }

  _buildUnsupportBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          Text(appLocalizations
              .cloudTypeNotSupport(appLocalizations.cloudTypeBox)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: appLocalizations.cloudConnecting);
    }
    await currentService.checkServer().then((value) async {
      if (!value) {
        IToast.show(appLocalizations
            .cloudOAuthUnavailable(CloudService.serverEndpoint));
      } else {
        await currentService.authenticate().then((value) async {
          setState(() {
            currentConfig.connected = (value == CloudServiceStatus.success);
          });
          if (!currentConfig.connected) {
            switch (value) {
              case CloudServiceStatus.connectionError:
                IToast.show(appLocalizations.cloudConnectionError);
                break;
              case CloudServiceStatus.unauthorized:
                IToast.show(appLocalizations.cloudOauthFailed);
                break;
              default:
                IToast.show(appLocalizations.cloudUnknownError);
                break;
            }
          } else {
            _huaweiCloudCloudServiceConfig!.configured = true;
            updateConfig(_huaweiCloudCloudServiceConfig!);
            if (showSuccessToast) {
              IToast.show(appLocalizations.cloudAuthSuccess);
            }
          }
        });
      }
    });
    if (showLoading) CustomLoadingDialog.dismissLoading();
  }

  _buildBody() {
    return ListView(
      children: [
        if (_configInitialized) _enableInfo(),
        if (_configInitialized && currentConfig.connected) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
        const SizedBox(height: 30),
      ],
    );
  }

  _enableInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: CheckboxItem(
        title: appLocalizations.enable + appLocalizations.cloudTypeHuaweiCloud,
        description: appLocalizations.cloudOAuthSafeTip(
            CloudService.serverEndpoint, appLocalizations.cloudTypeHuaweiCloud),
        value: _huaweiCloudCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _huaweiCloudCloudServiceConfig!.enabled =
                !_huaweiCloudCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _huaweiCloudCloudServiceConfig!,
                _huaweiCloudCloudServiceConfig!.enabled);
          });
        },
      ),
    );
  }

  _accountInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          InputItem(
            controller: _accountController,
            textInputAction: TextInputAction.next,
            disabled: true,
            title: appLocalizations.cloudDisplayName,
          ),
          InputItem(
            controller: _sizeController,
            textInputAction: TextInputAction.next,
            disabled: true,
            title: appLocalizations.cloudSize,
          ),
        ],
      ),
    );
  }

  _loginButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RoundIconTextButton(
        text: appLocalizations.cloudSignin,
        background: ChewieTheme.primaryColor,
        fontSizeDelta: 2,
        onPressed: () async {
          try {
            appProvider.preventLock = true;
            if(ResponsiveUtil.isDesktop()) windowManager.minimize();
            await ping();
          } catch (e, t) {
            ILogger.error("Failed to connect to huawei cloud", e, t);
            IToast.show(appLocalizations.cloudConnectionError);
          } finally {
            appProvider.preventLock = false;
            if(ResponsiveUtil.isDesktop()) windowManager.restore();
          }
        },
      ),
    );
  }

  _operationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: RoundIconTextButton(
              text: appLocalizations.cloudPullBackup,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: ChewieTheme.primaryColor,
              fontSizeDelta: 2,
              onPressed: () async {
                CustomLoadingDialog.showLoading(
                    title: appLocalizations.cloudPulling);
                try {
                  List<HuaweiCloudFileInfo>? files =
                      await _huaweiCloudCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _huaweiCloudCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) =>
                      b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => HuaweiCloudBackupsBottomSheet(
                        files: files,
                        cloudService: _huaweiCloudCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            appLocalizations.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res =
                              await _huaweiCloudCloudService!.downloadFile(
                            selectedFile.id,
                            onProgress: (c, t) {
                              dialog.updateProgress(progress: c / t);
                            },
                          );
                          ImportTokenUtil.importFromCloud(context, res, dialog);
                        },
                      ),
                    );
                  } else {
                    IToast.show(appLocalizations.cloudNoBackupFile);
                  }
                } catch (e, t) {
                  ILogger.error("Failed to pull from huawei cloud", e, t);
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(appLocalizations.cloudPullFailed);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              background: ChewieTheme.primaryColor,
              text: appLocalizations.cloudPushBackup,
              fontSizeDelta: 2,
              onPressed: () async {
                ExportTokenUtil.backupEncryptToCloud(
                  config: _huaweiCloudCloudServiceConfig!,
                  cloudService: _huaweiCloudCloudService!,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              background: Colors.red,
              text: appLocalizations.cloudLogout,
              fontSizeDelta: 2,
              onPressed: () async {
                DialogBuilder.showConfirmDialog(context,
                    title: appLocalizations.cloudLogout,
                    message: appLocalizations.cloudLogoutMessage,
                    onTapConfirm: () async {
                  await _huaweiCloudCloudService!.signOut();
                  setState(() {
                    _huaweiCloudCloudServiceConfig!.connected = false;
                    _huaweiCloudCloudServiceConfig!.account = "";
                    _huaweiCloudCloudServiceConfig!.totalSize =
                        _huaweiCloudCloudServiceConfig!.remainingSize =
                            _huaweiCloudCloudServiceConfig!.usedSize = -1;
                    updateConfig(_huaweiCloudCloudServiceConfig!);
                  });
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
