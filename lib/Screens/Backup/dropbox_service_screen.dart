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
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:flutter/material.dart';
import 'package:awesome_cloud/awesome_cloud.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/dropbox_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Widgets/BottomSheet/Backups/dropbox_backups_bottom_sheet.dart';
import '../../generated/l10n.dart';

class DropboxServiceScreen extends StatefulWidget {
  const DropboxServiceScreen({
    super.key,
  });

  static const String routeName = "/service/dropbox";

  @override
  State<DropboxServiceScreen> createState() => _DropboxServiceScreenState();
}

class _DropboxServiceScreenState extends State<DropboxServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _dropboxCloudServiceConfig;
  DropboxCloudService? _dropboxCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _dropboxCloudServiceConfig!;

  CloudService get currentService => _dropboxCloudService!;

  bool get _configInitialized {
    return _dropboxCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  loadConfig() async {
    _dropboxCloudServiceConfig = await CloudServiceConfigDao.getDropboxConfig();
    if (_dropboxCloudServiceConfig != null) {
      _sizeController.text = _dropboxCloudServiceConfig!.size;
      _accountController.text = _dropboxCloudServiceConfig!.account ?? "";
      _emailController.text = _dropboxCloudServiceConfig!.email ?? "";
      _dropboxCloudService = DropboxCloudService(
        _dropboxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _dropboxCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Dropbox);
      await CloudServiceConfigDao.insertConfig(_dropboxCloudServiceConfig!);
      _dropboxCloudService = DropboxCloudService(
        _dropboxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_dropboxCloudService != null) {
      _dropboxCloudServiceConfig!.configured =
          await _dropboxCloudService!.hasConfigured();
      _dropboxCloudServiceConfig!.connected =
          await _dropboxCloudService!.isConnected();
      if (_dropboxCloudServiceConfig!.configured &&
          !_dropboxCloudServiceConfig!.connected) {
        IToast.showTop(S.current.cloudConnectionError);
      }
      updateConfig(_dropboxCloudServiceConfig!);
    }
    inited = true;
    if (mounted) setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _dropboxCloudServiceConfig = config;
      });
    }
    _sizeController.text = _dropboxCloudServiceConfig!.size;
    _accountController.text = _dropboxCloudServiceConfig!.account ?? "";
    _emailController.text = _dropboxCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_dropboxCloudServiceConfig!);
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
                text: S.current.cloudConnecting,
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
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeDropbox)),
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
      CustomLoadingDialog.showLoading(title: S.current.cloudConnecting);
    }
    await currentService.authenticate().then((value) async {
      setState(() {
        currentConfig.connected = (value == CloudServiceStatus.success);
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(S.current.cloudConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(S.current.cloudOauthFailed);
            break;
          default:
            IToast.show(S.current.cloudUnknownError);
            break;
        }
      } else {
        _dropboxCloudServiceConfig!.configured = true;
        updateConfig(_dropboxCloudServiceConfig!);
        if (showSuccessToast) IToast.show(S.current.cloudAuthSuccess);
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
        title: S.current.enable + S.current.cloudTypeDropbox,
        value: _dropboxCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _dropboxCloudServiceConfig!.enabled =
                !_dropboxCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _dropboxCloudServiceConfig!,
                _dropboxCloudServiceConfig!.enabled);
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
            title: S.current.cloudDisplayName,
          ),
          InputItem(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            disabled: true,
            title: S.current.cloudEmail,
          ),
          InputItem(
            controller: _sizeController,
            textInputAction: TextInputAction.next,
            disabled: true,
            title: S.current.cloudSize,
          ),
        ],
      ),
    );
  }

  _loginButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RoundIconTextButton(
        text: S.current.cloudSignin,
        background: ChewieTheme.primaryColor,
        fontSizeDelta: 2,
        onPressed: () async {
          try {
            ping();
          } catch (e, t) {
            ILogger.error("Failed to connect to dropbox", e, t);
            IToast.show(S.current.cloudConnectionError);
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
              text: S.current.cloudPullBackup,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: ChewieTheme.primaryColor,
              fontSizeDelta: 2,
              onPressed: () async {
                CustomLoadingDialog.showLoading(title: S.current.cloudPulling);
                try {
                  List<DropboxFileInfo>? files =
                      await _dropboxCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(S.current.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _dropboxCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) =>
                      b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => DropboxBackupsBottomSheet(
                        files: files,
                        cloudService: _dropboxCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            S.current.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res =
                              await _dropboxCloudService!.downloadFile(
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
                    IToast.show(S.current.cloudNoBackupFile);
                  }
                } catch (e, t) {
                  ILogger.error("Failed to pull file from dropbox", e, t);
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudPullFailed);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              background: ChewieTheme.primaryColor,
              text: S.current.cloudPushBackup,
              fontSizeDelta: 2,
              onPressed: () async {
                ExportTokenUtil.backupEncryptToCloud(
                  config: _dropboxCloudServiceConfig!,
                  cloudService: _dropboxCloudService!,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RoundIconTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              background: Colors.red,
              text: S.current.cloudLogout,
              fontSizeDelta: 2,
              onPressed: () async {
                DialogBuilder.showConfirmDialog(context,
                    title: S.current.cloudLogout,
                    message: S.current.cloudLogoutMessage,
                    onTapConfirm: () async {
                  CustomLoadingDialog.showLoading(
                      title: S.current.cloudLoggingOut);
                  await _dropboxCloudService!.signOut();
                  setState(() {
                    _dropboxCloudServiceConfig!.connected = false;
                    _dropboxCloudServiceConfig!.account = "";
                    _dropboxCloudServiceConfig!.email = "";
                    _dropboxCloudServiceConfig!.totalSize =
                        _dropboxCloudServiceConfig!.remainingSize =
                            _dropboxCloudServiceConfig!.usedSize = -1;
                    updateConfig(_dropboxCloudServiceConfig!);
                  });
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudLogoutSuccess);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
