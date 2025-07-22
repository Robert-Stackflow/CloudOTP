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
import 'package:window_manager/window_manager.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/box_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/Backups/box_backups_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class BoxServiceScreen extends StatefulWidget {
  const BoxServiceScreen({
    super.key,
  });

  static const String routeName = "/service/box";

  @override
  State<BoxServiceScreen> createState() => _BoxServiceScreenState();
}

class _BoxServiceScreenState extends BaseDynamicState<BoxServiceScreen>
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Utils.showQAuthDialog(context));
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
        IToast.showTop(appLocalizations.cloudConnectionError);
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
            _boxCloudServiceConfig!.configured = true;
            updateConfig(_boxCloudServiceConfig!);
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
        title: appLocalizations.enable + appLocalizations.cloudTypeBox,
        description: appLocalizations.cloudOAuthSafeTip(
            CloudService.serverEndpoint, appLocalizations.cloudTypeBox),
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
            if (ResponsiveUtil.isDesktop()) windowManager.minimize();
            await ping();
          } catch (e, t) {
            ILogger.error("Failed to connect to box", e, t);
            IToast.show(appLocalizations.cloudConnectionError);
          } finally {
            appProvider.preventLock = false;
            if (ResponsiveUtil.isDesktop()) windowManager.restore();
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
                  List<BoxFileInfo>? files =
                      await _boxCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
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
                            appLocalizations.cloudPulling,
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
                    IToast.show(appLocalizations.cloudNoBackupFile);
                  }
                } catch (e, t) {
                  ILogger.error("Failed to pull file from box", e, t);
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
              text: appLocalizations.cloudLogout,
              fontSizeDelta: 2,
              onPressed: () async {
                DialogBuilder.showConfirmDialog(context,
                    title: appLocalizations.cloudLogout,
                    message: appLocalizations.cloudLogoutMessage,
                    onTapConfirm: () async {
                  CustomLoadingDialog.showLoading(
                      title: appLocalizations.cloudLoggingOut);
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
