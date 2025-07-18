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

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/onedrive_backups_bottom_sheet.dart';
import 'package:flutter/material.dart';

import 'package:awesome_cloud/awesome_cloud.dart';
import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/onedrive_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Utils/app_provider.dart';
import '../../l10n/l10n.dart';

class OneDriveServiceScreen extends StatefulWidget {
  const OneDriveServiceScreen({
    super.key,
  });

  static const String routeName = "/service/onedrive";

  @override
  State<OneDriveServiceScreen> createState() => _OneDriveServiceScreenState();
}

class _OneDriveServiceScreenState
    extends BaseDynamicState<OneDriveServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _oneDriveCloudServiceConfig;
  OneDriveCloudService? _oneDriveCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _oneDriveCloudServiceConfig!;

  CloudService get currentService => _oneDriveCloudService!;

  bool get _configInitialized {
    return _oneDriveCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    try {
      loadConfig();
    } catch (e) {
      inited = true;
      IToast.show(appLocalizations.cloudConnectionError);
    }
  }

  loadConfig() async {
    _oneDriveCloudServiceConfig =
        await CloudServiceConfigDao.getOneDriveConfig();
    if (_oneDriveCloudServiceConfig != null) {
      _sizeController.text = _oneDriveCloudServiceConfig!.size;
      _accountController.text = _oneDriveCloudServiceConfig!.account ?? "";
      _emailController.text = _oneDriveCloudServiceConfig!.email ?? "";
      _oneDriveCloudService = OneDriveCloudService(
        _oneDriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _oneDriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.OneDrive);
      await CloudServiceConfigDao.insertConfig(_oneDriveCloudServiceConfig!);
      _oneDriveCloudService = OneDriveCloudService(
        _oneDriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_oneDriveCloudService != null) {
      _oneDriveCloudServiceConfig!.configured =
          await _oneDriveCloudService!.hasConfigured();
      _oneDriveCloudServiceConfig!.connected =
          await _oneDriveCloudService!.isConnected();
      if (_oneDriveCloudServiceConfig!.configured &&
          !_oneDriveCloudServiceConfig!.connected) {
        IToast.showTop(appLocalizations.cloudConnectionError);
      }
      updateConfig(_oneDriveCloudServiceConfig!);
    }
    inited = true;
    if (mounted) setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _oneDriveCloudServiceConfig = config;
      });
    }
    _sizeController.text = _oneDriveCloudServiceConfig!.size;
    _accountController.text = _oneDriveCloudServiceConfig!.account ?? "";
    _emailController.text = _oneDriveCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_oneDriveCloudServiceConfig!);
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
              .cloudTypeNotSupport(appLocalizations.cloudTypeOneDrive)),
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
    await currentService.authenticate().then((value) async {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
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
        _oneDriveCloudServiceConfig!.configured = true;
        updateConfig(_oneDriveCloudServiceConfig!);
        if (showSuccessToast) IToast.show(appLocalizations.cloudAuthSuccess);
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
        title: appLocalizations.enable + appLocalizations.cloudTypeOneDrive,
        description: appLocalizations.cloudTypeOneDriveTip,
        value: _oneDriveCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _oneDriveCloudServiceConfig!.enabled =
                !_oneDriveCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _oneDriveCloudServiceConfig!,
                _oneDriveCloudServiceConfig!.enabled);
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
            controller: _emailController,
            textInputAction: TextInputAction.next,
            disabled: true,
            title: appLocalizations.cloudEmail,
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
            await ping();
          } catch (e, t) {
            ILogger.error("Failed to connect to onedrive", e, t);
            IToast.show(appLocalizations.cloudConnectionError);
          } finally {
            appProvider.preventLock = false;
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              text: appLocalizations.cloudPullBackup,
              color: ChewieTheme.primaryColor,
              fontSizeDelta: 2,
              onPressed: () async {
                CustomLoadingDialog.showLoading(
                    title: appLocalizations.cloudPulling);
                try {
                  List<OneDriveFileInfo>? files =
                      await _oneDriveCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _oneDriveCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) =>
                      b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => OneDriveBackupsBottomSheet(
                        files: files,
                        cloudService: _oneDriveCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            appLocalizations.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res =
                              await _oneDriveCloudService!.downloadFile(
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
                  ILogger.error("Failed to pull from onedrive", e, t);
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(appLocalizations.cloudPullFailed);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              background: ChewieTheme.primaryColor,
              text: appLocalizations.cloudPushBackup,
              fontSizeDelta: 2,
              onPressed: () async {
                ExportTokenUtil.backupEncryptToCloud(
                  config: _oneDriveCloudServiceConfig!,
                  cloudService: _oneDriveCloudService!,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              background: Colors.red,
              text: appLocalizations.cloudLogout,
              fontSizeDelta: 2,
              onPressed: () async {
                DialogBuilder.showConfirmDialog(context,
                    title: appLocalizations.cloudLogout,
                    message: appLocalizations.cloudLogoutMessage,
                    onTapConfirm: () async {
                  CustomLoadingDialog.showLoading(
                      title: appLocalizations.cloudLoggingOut);
                  await _oneDriveCloudService!.signOut();
                  setState(() {
                    _oneDriveCloudServiceConfig!.connected = false;
                    _oneDriveCloudServiceConfig!.account = "";
                    _oneDriveCloudServiceConfig!.email = "";
                    _oneDriveCloudServiceConfig!.totalSize =
                        _oneDriveCloudServiceConfig!.remainingSize =
                            _oneDriveCloudServiceConfig!.usedSize = -1;
                    updateConfig(_oneDriveCloudServiceConfig!);
                  });
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(appLocalizations.cloudLogoutSuccess);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
