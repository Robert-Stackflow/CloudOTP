/*
 * Copyright (c) 2024-2025 Robert-Stackflow.
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
import 'package:awesome_cloud/models/box_response.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/box_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Widgets/BottomSheet/Backups/box_backups_bottom_sheet.dart';
import '../../generated/l10n.dart';

class BoxServiceScreen extends StatefulWidget {
  const BoxServiceScreen({
    super.key,
  });

  static const String routeName = "/service/box";

  @override
  State<BoxServiceScreen> createState() => _BoxServiceScreenState();
}

class _BoxServiceScreenState extends State<BoxServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _boxCloudServiceConfig;
  BoxCloudService? _boxCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _boxCloudServiceConfig!;

  CloudService get currentService => _boxCloudService!;

  bool get _configInitialized {
    return _boxCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  loadConfig() async {
    _boxCloudServiceConfig = await CloudServiceConfigDao.getBoxConfig();
    if (_boxCloudServiceConfig != null) {
      _sizeController.text = _boxCloudServiceConfig!.size;
      _accountController.text = _boxCloudServiceConfig!.account ?? "";
      _emailController.text = _boxCloudServiceConfig!.email ?? "";
      _boxCloudService = BoxCloudService(
        _boxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _boxCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Box);
      await CloudServiceConfigDao.insertConfig(_boxCloudServiceConfig!);
      _boxCloudService = BoxCloudService(
        _boxCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_boxCloudService != null) {
      _boxCloudServiceConfig!.configured =
          await _boxCloudService!.hasConfigured();
      _boxCloudServiceConfig!.connected = await _boxCloudService!.isConnected();
      if (_boxCloudServiceConfig!.configured &&
          !_boxCloudServiceConfig!.connected) {
        IToast.showTop(S.current.cloudConnectionError);
      }
      updateConfig(_boxCloudServiceConfig!);
    }
    inited = true;
    if (mounted) setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    if (mounted) {
      setState(() {
        _boxCloudServiceConfig = config;
      });
    }
    _sizeController.text = _boxCloudServiceConfig!.size;
    _accountController.text = _boxCloudServiceConfig!.account ?? "";
    _emailController.text = _boxCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_boxCloudServiceConfig!);
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
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeBox)),
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
    await currentService.checkServer().then((value) async {
      if (!value) {
        IToast.show(
            S.current.cloudOAuthUnavailable(CloudService.serverEndpoint));
      } else {
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
            _boxCloudServiceConfig!.configured = true;
            updateConfig(_boxCloudServiceConfig!);
            if (showSuccessToast) IToast.show(S.current.cloudAuthSuccess);
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
        title: S.current.enable + S.current.cloudTypeBox,
        description: S.current.cloudOAuthSafeTip(
            S.current.cloudTypeBox, CloudService.serverEndpoint),
        value: _boxCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _boxCloudServiceConfig!.enabled = !_boxCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _boxCloudServiceConfig!, _boxCloudServiceConfig!.enabled);
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
            ILogger.error("Failed to connect to box", e, t);
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
                  List<BoxFileInfo>? files =
                      await _boxCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(S.current.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _boxCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) =>
                      b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => BoxBackupsBottomSheet(
                        files: files,
                        cloudService: _boxCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            S.current.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res = await _boxCloudService!.downloadFile(
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
                  ILogger.error("Failed to pull file from box", e, t);
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
                  config: _boxCloudServiceConfig!,
                  cloudService: _boxCloudService!,
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
                  await _boxCloudService!.signOut();
                  setState(() {
                    _boxCloudServiceConfig!.connected = false;
                    _boxCloudServiceConfig!.account = "";
                    _boxCloudServiceConfig!.email = "";
                    _boxCloudServiceConfig!.totalSize = _boxCloudServiceConfig!
                        .remainingSize = _boxCloudServiceConfig!.usedSize = -1;
                    updateConfig(_boxCloudServiceConfig!);
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
