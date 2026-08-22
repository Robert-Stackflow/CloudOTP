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

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/webdav_backups_bottom_sheet.dart';
import 'package:flutter/material.dart';

import 'cloud_service_ui_helper.dart';
import 'package:awesome_cloud/awesome_cloud.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/regex_util.dart';
import '../../l10n/l10n.dart';

class WebDavServiceScreen extends StatefulWidget {
  const WebDavServiceScreen({
    super.key,
    required this.configId,
    this.onTitleChanged,
  });

  final int configId;
  final VoidCallback? onTitleChanged;

  static const String routeName = "/service/webdav";

  @override
  State<WebDavServiceScreen> createState() => _WebDavServiceScreenState();
}

class _WebDavServiceScreenState extends BaseDynamicState<WebDavServiceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
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
    _webDavCloudServiceConfig =
        await CloudServiceConfigDao.getConfigById(widget.configId);
    if (_webDavCloudServiceConfig != null) {
      _titleController.text = _webDavCloudServiceConfig!.title;
      _endpointController.text = _webDavCloudServiceConfig!.endpoint ?? "";
      _accountController.text = _webDavCloudServiceConfig!.account ?? "";
      _secretController.text = _webDavCloudServiceConfig!.secret ?? "";
      if (await _webDavCloudServiceConfig!.isValid()) {
        _webDavCloudService = WebDavCloudService(_webDavCloudServiceConfig!);
      }
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
    _titleController.addListener(() {
      _webDavCloudServiceConfig!.title = _titleController.text;
    });
    _titleFocusNode.addListener(_onTitleFocusChanged);
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

  void _onTitleFocusChanged() {
    if (!_titleFocusNode.hasFocus && _configInitialized) {
      CloudServiceConfigDao.updateConfigTitle(_webDavCloudServiceConfig!);
      widget.onTitleChanged?.call();
    }
  }

  Future<bool> _confirmInsecureHttp() async {
    if (!currentConfig.usesInsecureWebDavHttp ||
        currentConfig.allowsInsecureWebDavHttp) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(appLocalizations.webDavServer),
            content: Text(appLocalizations.webDavHttpWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(chewieLocalizations.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(chewieLocalizations.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<bool> isValid() async {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
    await CloudServiceUiHelper.runWithLoading(
      showLoading: showLoading,
      action: () async => currentService.authenticate().then((value) {
        setState(() {
          currentConfig.connected = value.isSuccess;
        });
        if (!currentConfig.connected) {
          String toast;
          switch (value.type) {
            case CloudServiceStatusType.connectionError:
              toast = appLocalizations.cloudConnectionError;
              break;
            case CloudServiceStatusType.unauthorized:
              toast = appLocalizations.cloudUnauthorized;
              break;
            default:
              toast = appLocalizations.cloudUnknownError;
              break;
          }
          IToast.show(
              value.message != null ? "$toast: ${value.message}" : toast);
        } else {
          if (showSuccessToast) IToast.show(appLocalizations.cloudAuthSuccess);
        }
      }),
    );
  }

  _buildBody() {
    return ListView(
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
        ink: false,
        title: appLocalizations.enable + currentConfig.displayName,
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
              controller: _titleController,
              focusNode: _titleFocusNode,
              textInputAction: TextInputAction.next,
              title: appLocalizations.cloudConfigTitle,
              hint: appLocalizations.cloudConfigTitleHint,
            ),
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
          if (!await isValid() || !mounted) return;
          if (!await _confirmInsecureHttp() || !mounted) return;
          currentConfig.allowsInsecureWebDavHttp =
              currentConfig.usesInsecureWebDavHttp;
          await CloudServiceConfigDao.updateConfig(currentConfig);
          _webDavCloudService = WebDavCloudService(_webDavCloudServiceConfig!);
          try {
            appProvider.preventLock = true;
            await ping();
          } catch (e, t) {
            ILogger.error("Failed to connect to webdav", e, t);
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
                final files = await CloudServiceUiHelper.loadBackups<
                    List<WebDavFileInfo>>(
                  action: _webDavCloudService!.listBackups,
                  logName: "WebDAV",
                );
                if (!mounted || files == null) return;
                await CloudServiceConfigDao.updateLastPullTime(
                    _webDavCloudServiceConfig!);
                if (!mounted) return;
                files.sort((a, b) => b.mTime!.compareTo(a.mTime!));
                if (files.isNotEmpty) {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    responsive: true,
                    (dialogContext) => WebDavBackupsBottomSheet(
                      files: files,
                      cloudService: _webDavCloudService!,
                      onSelected: (selectedFile) async {
                        await CloudServiceUiHelper.downloadAndImport(
                          context: context,
                          logName: "WebDAV",
                          action: (onProgress) =>
                              _webDavCloudService!.downloadFile(
                            selectedFile.name!,
                            onProgress: onProgress,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  IToast.show(appLocalizations.cloudNoBackupFile);
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
                await ExportTokenUtil.backupEncryptToCloud(
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
