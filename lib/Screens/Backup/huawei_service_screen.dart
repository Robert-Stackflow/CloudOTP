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
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cloud/huaweicloud_response.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/huawei_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Utils/ilogger.dart';
import '../../Widgets/BottomSheet/Backups/huawei_backups_bottom_sheet.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/Dialog/progress_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class HuaweiCloudServiceScreen extends StatefulWidget {
  const HuaweiCloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/huaweiCloud";

  @override
  State<HuaweiCloudServiceScreen> createState() =>
      _HuaweiCloudServiceScreenState();
}

class _HuaweiCloudServiceScreenState extends State<HuaweiCloudServiceScreen>
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
        IToast.showTop(S.current.cloudConnectionError);
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
    return inited
        ? _buildBody()
        : ItemBuilder.buildLoadingDialog(
            context,
            background: Colors.transparent,
            text: S.current.cloudConnecting,
            mainAxisAlignment: MainAxisAlignment.start,
            topPadding: 100,
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
        _huaweiCloudCloudServiceConfig!.configured = true;
        updateConfig(_huaweiCloudCloudServiceConfig!);
        if (showSuccessToast) IToast.show(S.current.cloudAuthSuccess);
      }
    });
    if (showLoading) CustomLoadingDialog.dismissLoading();
  }

  _buildBody() {
    return Column(
      children: [
        if (_configInitialized) _enableInfo(),
        const SizedBox(height: 10),
        if (_configInitialized && currentConfig.connected) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
      ],
    );
  }

  _enableInfo() {
    return ItemBuilder.buildRadioItem(
      context: context,
      title: S.current.enable + S.current.cloudTypeHuaweiCloud,
      topRadius: true,
      bottomRadius: true,
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
    );
  }

  _accountInfo() {
    return ItemBuilder.buildContainerItem(
      context: context,
      topRadius: true,
      bottomRadius: true,
      padding: const EdgeInsets.only(top: 15, bottom: 5, right: 10),
      child: Column(
        children: [
          InputItem(
            controller: _accountController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudDisplayName,
          ),
          InputItem(
            controller: _sizeController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudSize,
          ),
        ],
      ),
    );
  }

  _loginButton() {
    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            text: S.current.cloudSignin,
            background: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              try {
                ping();
              } catch (e, t) {
                ILogger.error(
                    "CloudOTP", "Failed to connect to huawei cloud", e, t);
                IToast.show(S.current.cloudConnectionError);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  _operationButtons() {
    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildFramedButton(
            context,
            text: S.current.cloudPullBackup,
            padding: const EdgeInsets.symmetric(vertical: 12),
            outline: Theme.of(context).primaryColor,
            color: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              CustomLoadingDialog.showLoading(title: S.current.cloudPulling);
              try {
                List<HuaweiCloudFileInfo>? files =
                    await _huaweiCloudCloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudPullFailed);
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
                          msg: S.current.cloudPulling,
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
                  IToast.show(S.current.cloudNoBackupFile);
                }
              } catch (e, t) {
                ILogger.error(
                    "CloudOTP", "Failed to pull from huawei cloud", e, t);
                CustomLoadingDialog.dismissLoading();
                IToast.show(S.current.cloudPullFailed);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            padding: const EdgeInsets.symmetric(vertical: 12),
            background: Theme.of(context).primaryColor,
            text: S.current.cloudPushBackup,
            fontSizeDelta: 2,
            onTap: () async {
              ExportTokenUtil.backupEncryptToCloud(
                config: _huaweiCloudCloudServiceConfig!,
                cloudService: _huaweiCloudCloudService!,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ItemBuilder.buildRoundButton(
            context,
            padding: const EdgeInsets.symmetric(vertical: 12),
            background: Colors.red,
            text: S.current.cloudLogout,
            fontSizeDelta: 2,
            onTap: () async {
              DialogBuilder.showConfirmDialog(context,
                  title: S.current.cloudLogout,
                  message: S.current.cloudLogoutMessage,
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
        const SizedBox(width: 10),
      ],
    );
  }
}
