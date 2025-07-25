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
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Models/s3_cloud_file_info.dart';
import '../../TokenUtils/Cloud/s3_cloud_service.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/regex_util.dart';
import '../../Widgets/BottomSheet/Backups/s3_backups_bottom_sheet.dart';
import '../../l10n/l10n.dart';

class S3CloudServiceScreen extends StatefulWidget {
  const S3CloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/webdav";

  @override
  State<S3CloudServiceScreen> createState() => _S3CloudServiceScreenState();
}

class _S3CloudServiceScreenState extends BaseDynamicState<S3CloudServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _bucketController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _accessKeyController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  CloudServiceConfig? _s3CloudServiceConfig;
  S3CloudService? _s3CloudService;

  CloudServiceConfig get currentConfig => _s3CloudServiceConfig!;

  CloudService get currentService => _s3CloudService!;

  bool get _configInitialized {
    return _s3CloudServiceConfig != null;
  }

  bool inited = false;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loadConfig();
    initFields();
  }

  loadConfig() async {
    _s3CloudServiceConfig = await CloudServiceConfigDao.getS3CloudConfig();
    if (_s3CloudServiceConfig != null) {
      _endpointController.text = _s3CloudServiceConfig!.endpoint ?? "";
      _bucketController.text = _s3CloudServiceConfig!.account ?? "";
      _secretKeyController.text = _s3CloudServiceConfig!.secret ?? "";
      _accessKeyController.text = _s3CloudServiceConfig!.token ?? "";
      _regionController.text = _s3CloudServiceConfig!.email ?? "";
      if (await _s3CloudServiceConfig!.isValid()) {
        _s3CloudService = S3CloudService(_s3CloudServiceConfig!);
      }
    } else {
      _s3CloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.S3Cloud);
      await CloudServiceConfigDao.insertConfig(_s3CloudServiceConfig!);
    }
    if (_s3CloudService != null) {
      _s3CloudServiceConfig!.connected = await _s3CloudService!.isConnected();
    }
    inited = true;
    setState(() {});
  }

  initFields() {
    _endpointController.addListener(() {
      _s3CloudServiceConfig!.endpoint = _endpointController.text;
    });
    _bucketController.addListener(() {
      _s3CloudServiceConfig!.account = _bucketController.text;
    });
    _secretKeyController.addListener(() {
      _s3CloudServiceConfig!.secret = _secretKeyController.text;
    });
    _accessKeyController.addListener(() {
      _s3CloudServiceConfig!.token = _accessKeyController.text;
    });
    _regionController.addListener(() {
      _s3CloudServiceConfig!.email = _regionController.text;
    });
  }

  Future<bool> isValid() async {
    return formKey.currentState?.validate() ?? false;
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
    await currentService.authenticate().then((value) {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(appLocalizations.cloudConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(appLocalizations.cloudUnauthorized);
            break;
          default:
            IToast.show(appLocalizations.cloudUnknownError);
            break;
        }
      } else {
        if (showSuccessToast) IToast.show(appLocalizations.cloudAuthSuccess);
      }
    });
    if (showLoading) CustomLoadingDialog.dismissLoading();
  }

  _buildBody() {
    return ListView(
      children: [
        if (_configInitialized) _enableInfo(),
        if (_configInitialized) _accountInfo(),
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
        title: appLocalizations.enable + appLocalizations.cloudTypeS3Cloud,
        value: _s3CloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _s3CloudServiceConfig!.enabled = !_s3CloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _s3CloudServiceConfig!, _s3CloudServiceConfig!.enabled);
          });
        },
      ),
    );
  }

  _accountInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            InputItem(
              controller: _endpointController,
              textInputAction: TextInputAction.next,
              title: appLocalizations.s3Endpoint,
              disabled: currentConfig.connected,
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.s3EndpointCannotBeEmpty;
                }
                if (!RegexUtil.isUrlOrIp(text)) {
                  return appLocalizations.s3EndpointInvalid;
                }
                return null;
              },
              hint: appLocalizations.s3EndpointHint,
            ),
            InputItem(
              controller: _bucketController,
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.s3BucketCannotBeEmpty;
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              disabled: currentConfig.connected,
              title: appLocalizations.s3Bucket,
              hint: appLocalizations.s3BucketHint,
            ),
            InputItem(
              controller: _accessKeyController,
              textInputAction: TextInputAction.next,
              title: appLocalizations.s3AccessKey,
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              disabled: currentConfig.connected,
              hint: appLocalizations.s3AccessKeyHint,
              style: InputItemStyle(
                obscure: currentConfig.connected,
                bottomRadius: true,
              ),
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.s3AccessKeyCannotBeEmpty;
                }
                return null;
              },
            ),
            InputItem(
              controller: _secretKeyController,
              textInputAction: TextInputAction.next,
              title: appLocalizations.s3SecretKey,
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              disabled: currentConfig.connected,
              hint: appLocalizations.s3SecretKeyHint,
              style: InputItemStyle(
                obscure: currentConfig.connected,
                bottomRadius: true,
              ),
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.s3SecretKeyCannotBeEmpty;
                }
                return null;
              },
            ),
            InputItem(
              controller: _regionController,
              textInputAction: TextInputAction.next,
              title: appLocalizations.s3Region,
              disabled: currentConfig.connected,
              hint: appLocalizations.s3RegionHint,
            ),
          ],
        ),
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
          if (await isValid()) {
            try {
              await CloudServiceConfigDao.updateConfig(currentConfig);
              _s3CloudService = S3CloudService(_s3CloudServiceConfig!);
              appProvider.preventLock = true;
              await ping();
            } catch (e, t) {
              ILogger.error("Failed to connect to S3 cloud", e, t);
              IToast.show(appLocalizations.cloudConnectionError);
            } finally {
              appProvider.preventLock = false;
            }
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
                  List<S3CloudFileInfo>? files =
                      await _s3CloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _s3CloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort(
                      (a, b) => b.modifyTimestamp.compareTo(a.modifyTimestamp));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => S3CloudBackupsBottomSheet(
                        files: files,
                        cloudService: _s3CloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            appLocalizations.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res = await _s3CloudService!.downloadFile(
                            selectedFile.path,
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
                  ILogger.error("Failed to pull from S3 cloud", e, t);
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
                  config: _s3CloudServiceConfig!,
                  cloudService: _s3CloudService!,
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
                  setState(() {
                    currentConfig.connected = false;
                    _s3CloudService = null;
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
