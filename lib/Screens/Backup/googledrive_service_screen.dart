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

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/googledrive_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/Backups/googledrive_backups_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class GoogleDriveServiceScreen extends StatefulWidget {
  const GoogleDriveServiceScreen({
    super.key,
  });

  static const String routeName = "/service/googledrive";

  @override
  State<GoogleDriveServiceScreen> createState() =>
      _GoogleDriveServiceScreenState();
}

class _GoogleDriveServiceScreenState
    extends BaseDynamicState<GoogleDriveServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  CloudServiceConfig? _googledriveCloudServiceConfig;
  GoogleDriveCloudService? _googledriveCloudService;
  bool inited = false;

  CloudServiceConfig get currentConfig => _googledriveCloudServiceConfig!;

  CloudService get currentService => _googledriveCloudService!;

  bool get _configInitialized {
    return _googledriveCloudServiceConfig != null;
  }

  @override
  void initState() {
    super.initState();
    loadConfig();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Utils.showQAuthDialog(context));
  }

  loadConfig() async {
    _googledriveCloudServiceConfig =
        await CloudServiceConfigDao.getGoogleDriveConfig();
    if (_googledriveCloudServiceConfig != null) {
      _sizeController.text = _googledriveCloudServiceConfig!.size;
      _accountController.text = _googledriveCloudServiceConfig!.account ?? "";
      _emailController.text = _googledriveCloudServiceConfig!.email ?? "";
      _googledriveCloudService = GoogleDriveCloudService(
        _googledriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _googledriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.GoogleDrive);
      await CloudServiceConfigDao.insertConfig(_googledriveCloudServiceConfig!);
      _googledriveCloudService = GoogleDriveCloudService(
        _googledriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_googledriveCloudService != null) {
      _googledriveCloudServiceConfig!.configured =
          await _googledriveCloudService!.hasConfigured();
      _googledriveCloudServiceConfig!.connected =
          await _googledriveCloudService!.isConnected();
      if (_googledriveCloudServiceConfig!.configured &&
          !_googledriveCloudServiceConfig!.connected) {
        IToast.showTop(appLocalizations.cloudConnectionError);
      }
      updateConfig(_googledriveCloudServiceConfig!);
    }
    inited = true;
    setState(() {});
  }

  updateConfig(CloudServiceConfig config) {
    setState(() {
      _googledriveCloudServiceConfig = config;
    });
    _sizeController.text = _googledriveCloudServiceConfig!.size;
    _accountController.text = _googledriveCloudServiceConfig!.account ?? "";
    _emailController.text = _googledriveCloudServiceConfig!.email ?? "";
    CloudServiceConfigDao.updateConfig(_googledriveCloudServiceConfig!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return inited
        ? _buildBody()
        : ItemBuilder.buildLoadingDialog(
            context: context,
            background: Colors.transparent,
            text: appLocalizations.cloudConnecting,
            mainAxisAlignment: MainAxisAlignment.start,
            topPadding: 100,
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
            _googledriveCloudServiceConfig!.configured = true;
            updateConfig(_googledriveCloudServiceConfig!);
            if (showSuccessToast)
              IToast.show(appLocalizations.cloudAuthSuccess);
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
        title: appLocalizations.enable + appLocalizations.cloudTypeGoogleDrive,
        description: appLocalizations.cloudOAuthSafeTip(
            appLocalizations.cloudTypeGoogleDrive, CloudService.serverEndpoint),
        value: _googledriveCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _googledriveCloudServiceConfig!.enabled =
                !_googledriveCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _googledriveCloudServiceConfig!,
                _googledriveCloudServiceConfig!.enabled);
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
            ILogger.error("Failed to connect to google drive", e, t);
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
              text: appLocalizations.cloudPullBackup,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: ChewieTheme.primaryColor,
              fontSizeDelta: 2,
              onPressed: () async {
                CustomLoadingDialog.showLoading(
                    title: appLocalizations.cloudPulling);
                try {
                  List<GoogleDriveFileInfo>? files =
                      await _googledriveCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _googledriveCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) =>
                      b.lastModifiedDateTime.compareTo(a.lastModifiedDateTime));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => GoogleDriveBackupsBottomSheet(
                        files: files,
                        cloudService: _googledriveCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            appLocalizations.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res =
                              await _googledriveCloudService!.downloadFile(
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
                  ILogger.error("Failed to pull from google drive", e, t);
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
                  config: _googledriveCloudServiceConfig!,
                  cloudService: _googledriveCloudService!,
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
                  await _googledriveCloudService!.signOut();
                  setState(() {
                    _googledriveCloudServiceConfig!.connected = false;
                    _googledriveCloudServiceConfig!.account = "";
                    _googledriveCloudServiceConfig!.email = "";
                    _googledriveCloudServiceConfig!.totalSize =
                        _googledriveCloudServiceConfig!.remainingSize =
                            _googledriveCloudServiceConfig!.usedSize = -1;
                    updateConfig(_googledriveCloudServiceConfig!);
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
