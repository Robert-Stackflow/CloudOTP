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
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../Models/s3_cloud_file_info.dart';
import '../../TokenUtils/Cloud/s3_cloud_service.dart';
import '../../Utils/ilogger.dart';
import '../../Widgets/BottomSheet/Backups/s3_backups_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class S3CloudServiceScreen extends StatefulWidget {
  const S3CloudServiceScreen({
    super.key,
  });

  static const String routeName = "/service/webdav";

  @override
  State<S3CloudServiceScreen> createState() => _S3CloudServiceScreenState();
}

class _S3CloudServiceScreenState extends State<S3CloudServiceScreen>
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

  RegExp urlRegex = RegExp(
      r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-@]+))*");

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
    await currentService.authenticate().then((value) {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(S.current.cloudConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(S.current.cloudUnauthorized);
            break;
          default:
            IToast.show(S.current.cloudUnknownError);
            break;
        }
      } else {
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
        if (_configInitialized) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
      ],
    );
  }

  _enableInfo() {
    return ItemBuilder.buildRadioItem(
      context: context,
      title: S.current.enable + S.current.cloudTypeS3Cloud,
      topRadius: true,
      bottomRadius: true,
      value: _s3CloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _s3CloudServiceConfig!.enabled = !_s3CloudServiceConfig!.enabled;
          CloudServiceConfigDao.updateConfigEnabled(
              _s3CloudServiceConfig!, _s3CloudServiceConfig!.enabled);
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
      child: Form(
        key: formKey,
        child: Column(
          children: [
            InputItem(
              controller: _endpointController,
              textInputAction: TextInputAction.next,
              leadingText: S.current.s3Endpoint,
              leadingType: InputItemLeadingType.text,
              topRadius: true,
              disabled: currentConfig.connected,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.s3EndpointCannotBeEmpty;
                }
                if (!urlRegex.hasMatch(text)) {
                  return S.current.s3EndpointInvalid;
                }
                return null;
              },
              hint: S.current.s3EndpointHint,
            ),
            InputItem(
              controller: _bucketController,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.s3BucketCannotBeEmpty;
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              disabled: currentConfig.connected,
              leadingText: S.current.s3Bucket,
              hint: S.current.s3BucketHint,
            ),
            InputItem(
              controller: _accessKeyController,
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              leadingText: S.current.s3AccessKey,
              tailingType: InputItemTailingType.password,
              disabled: currentConfig.connected,
              hint: S.current.s3AccessKeyHint,
              obscureText: currentConfig.connected,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.s3AccessKeyCannotBeEmpty;
                }
                return null;
              },
              bottomRadius: true,
            ),
            InputItem(
              controller: _secretKeyController,
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              leadingText: S.current.s3SecretKey,
              tailingType: InputItemTailingType.password,
              disabled: currentConfig.connected,
              hint: S.current.s3SecretKeyHint,
              obscureText: currentConfig.connected,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.s3SecretKeyCannotBeEmpty;
                }
                return null;
              },
              bottomRadius: true,
            ),
            InputItem(
              controller: _regionController,
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              leadingText: S.current.s3Region,
              disabled: currentConfig.connected,
              hint: S.current.s3RegionHint,
              bottomRadius: true,
            ),
          ],
        ),
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
              if (await isValid()) {
                try {
                  await CloudServiceConfigDao.updateConfig(currentConfig);
                  _s3CloudService = S3CloudService(_s3CloudServiceConfig!);
                  ping();
                } catch (e, t) {
                  ILogger.error("CloudOTP","Failed to connect to S3 cloud", e, t);
                  IToast.show(S.current.cloudConnectionError);
                }
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
                List<S3CloudFileInfo>? files =
                    await _s3CloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudPullFailed);
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
                          msg: S.current.cloudPulling,
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
                  IToast.show(S.current.cloudNoBackupFile);
                }
              } catch (e, t) {
                ILogger.error("CloudOTP","Failed to pull from S3 cloud", e, t);
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
                config: _s3CloudServiceConfig!,
                cloudService: _s3CloudService!,
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
                setState(() {
                  currentConfig.connected = false;
                  _s3CloudService = null;
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
