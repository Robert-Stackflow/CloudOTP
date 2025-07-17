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
import 'package:cloudotp/Widgets/BottomSheet/Backups/webdav_backups_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/webdav_cloud_service.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Utils/regex_util.dart';
import '../../l10n/l10n.dart';

class WebDavServiceScreen extends StatefulWidget {
  const WebDavServiceScreen({
    super.key,
  });

  static const String routeName = "/service/webdav";

  @override
  State<WebDavServiceScreen> createState() => _WebDavServiceScreenState();
}

class _WebDavServiceScreenState extends BaseDynamicState<WebDavServiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  CloudServiceConfig? _webDavCloudServiceConfig;
  WebDavCloudService? _webDavCloudService;

  CloudServiceConfig get currentConfig => _webDavCloudServiceConfig!;

  CloudService get currentService => _webDavCloudService!;

  bool get _configInitialized {
    return _webDavCloudServiceConfig != null;
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool inited = false;

  @override
  void initState() {
    super.initState();
    loadConfig();
    initFields();
  }

  loadConfig() async {
    _webDavCloudServiceConfig = await CloudServiceConfigDao.getWebdavConfig();
    if (_webDavCloudServiceConfig != null) {
      _endpointController.text = _webDavCloudServiceConfig!.endpoint ?? "";
      _accountController.text = _webDavCloudServiceConfig!.account ?? "";
      _secretController.text = _webDavCloudServiceConfig!.secret ?? "";
      if (await _webDavCloudServiceConfig!.isValid()) {
        _webDavCloudService = WebDavCloudService(_webDavCloudServiceConfig!);
      }
    } else {
      _webDavCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Webdav);
      await CloudServiceConfigDao.insertConfig(_webDavCloudServiceConfig!);
    }
    if (_webDavCloudService != null) {
      _webDavCloudServiceConfig!.connected =
          await _webDavCloudService!.isConnected();
      if (!_webDavCloudServiceConfig!.connected) {
        IToast.showTop(appLocalizations.cloudConnectionError);
      }
    }
    inited = true;
    if (mounted) setState(() {});
  }

  initFields() {
    _endpointController.addListener(() {
      _webDavCloudServiceConfig!.endpoint = _endpointController.text;
    });
    _accountController.addListener(() {
      _webDavCloudServiceConfig!.account = _accountController.text;
    });
    _secretController.addListener(() {
      _webDavCloudServiceConfig!.secret = _secretController.text;
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
    return Column(
      children: [
        if (_configInitialized) _enableInfo(),
        if (_configInitialized) _accountInfo(),
        const SizedBox(height: 30),
        if (_configInitialized && !currentConfig.connected) _loginButton(),
        if (_configInitialized && currentConfig.connected) _operationButtons(),
      ],
    );
  }

  _enableInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: CheckboxItem(
        title: appLocalizations.enable + appLocalizations.cloudTypeWebDav,
        value: _webDavCloudServiceConfig?.enabled ?? false,
        onTap: () {
          setState(() {
            _webDavCloudServiceConfig!.enabled =
                !_webDavCloudServiceConfig!.enabled;
            CloudServiceConfigDao.updateConfigEnabled(
                _webDavCloudServiceConfig!, _webDavCloudServiceConfig!.enabled);
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
              title: appLocalizations.webDavServer,
              disabled: currentConfig.connected,
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.webDavServerCannotBeEmpty;
                }
                if (!RegexUtil.isUrlOrIp(text)) {
                  return appLocalizations.webDavServerInvalid;
                }
                return null;
              },
              hint: appLocalizations.webDavServerHint,
            ),
            InputItem(
              controller: _accountController,
              textInputAction: TextInputAction.next,
              disabled: currentConfig.connected,
              title: appLocalizations.webDavUsername,
              hint: appLocalizations.webDavUsernameHint,
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.webDavUsernameCannotBeEmpty;
                }
                return null;
              },
            ),
            InputItem(
              controller: _secretController,
              textInputAction: TextInputAction.next,
              title: appLocalizations.webDavPassword,
              style: InputItemStyle(
                obscure: currentConfig.connected,
                bottomRadius: true,
              ),
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              disabled: currentConfig.connected,
              hint: appLocalizations.webDavPasswordHint,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetterAndSymbol,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return appLocalizations.webDavPasswordCannotBeEmpty;
                }
                return null;
              },
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
        width: double.infinity,
        background: ChewieTheme.primaryColor,
        fontSizeDelta: 2,
        onPressed: () async {
          if (await isValid()) {
            await CloudServiceConfigDao.updateConfig(currentConfig);
            _webDavCloudService =
                WebDavCloudService(_webDavCloudServiceConfig!);
            try {
              ping();
            } catch (e, t) {
              ILogger.error("Failed to connect to webdav", e, t);
              IToast.show(appLocalizations.cloudConnectionError);
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
                CustomLoadingDialog.showLoading(title: appLocalizations.cloudPulling);
                try {
                  List<WebDavFileInfo>? files =
                      await _webDavCloudService!.listBackups();
                  if (files == null) {
                    CustomLoadingDialog.dismissLoading();
                    IToast.show(appLocalizations.cloudPullFailed);
                    return;
                  }
                  CloudServiceConfigDao.updateLastPullTime(
                      _webDavCloudServiceConfig!);
                  CustomLoadingDialog.dismissLoading();
                  files.sort((a, b) => b.mTime!.compareTo(a.mTime!));
                  if (files.isNotEmpty) {
                    BottomSheetBuilder.showBottomSheet(
                      context,
                      responsive: true,
                      (dialogContext) => WebDavBackupsBottomSheet(
                        files: files,
                        cloudService: _webDavCloudService!,
                        onSelected: (selectedFile) async {
                          var dialog = showProgressDialog(
                            appLocalizations.cloudPulling,
                            showProgress: true,
                          );
                          Uint8List? res =
                              await _webDavCloudService!.downloadFile(
                            selectedFile.name!,
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
                  ILogger.error("Failed to pull from webdav", e, t);
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
                  config: _webDavCloudServiceConfig!,
                  cloudService: _webDavCloudService!,
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
                    _webDavCloudService = null;
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
