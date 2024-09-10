import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/BottomSheet/Backups/webdav_backups_bottom_sheet.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../../Utils/ilogger.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class WebDavServiceScreen extends StatefulWidget {
  const WebDavServiceScreen({
    super.key,
  });

  static const String routeName = "/service/webdav";

  @override
  State<WebDavServiceScreen> createState() => _WebDavServiceScreenState();
}

class _WebDavServiceScreenState extends State<WebDavServiceScreen>
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
        IToast.showTop(S.current.cloudConnectionError);
      }
    }
    inited = true;
    if (mounted) setState(() {});
  }

  RegExp urlRegex = RegExp(
      r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-@]+))*");

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
      title: S.current.enable + S.current.cloudTypeWebDav,
      topRadius: true,
      bottomRadius: true,
      value: _webDavCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _webDavCloudServiceConfig!.enabled =
              !_webDavCloudServiceConfig!.enabled;
          CloudServiceConfigDao.updateConfigEnabled(
              _webDavCloudServiceConfig!, _webDavCloudServiceConfig!.enabled);
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
              leadingText: S.current.webDavServer,
              leadingType: InputItemLeadingType.text,
              topRadius: true,
              disabled: currentConfig.connected,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.webDavServerCannotBeEmpty;
                }
                if (!urlRegex.hasMatch(text)) {
                  return S.current.webDavServerInvalid;
                }
                return null;
              },
              hint: S.current.webDavServerHint,
            ),
            InputItem(
              controller: _accountController,
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              disabled: currentConfig.connected,
              leadingText: S.current.webDavUsername,
              hint: S.current.webDavUsernameHint,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.webDavUsernameCannotBeEmpty;
                }
                return null;
              },
            ),
            InputItem(
              controller: _secretController,
              textInputAction: TextInputAction.next,
              leadingType: InputItemLeadingType.text,
              leadingText: S.current.webDavPassword,
              tailingType: InputItemTailingType.password,
              disabled: currentConfig.connected,
              obscureText: currentConfig.connected,
              hint: S.current.webDavPasswordHint,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.webDavPasswordCannotBeEmpty;
                }
                return null;
              },
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
                await CloudServiceConfigDao.updateConfig(currentConfig);
                _webDavCloudService =
                    WebDavCloudService(_webDavCloudServiceConfig!);
                try {
                  ping();
                } catch (e, t) {
                  ILogger.error("CloudOTP","Failed to connect to webdav", e, t);
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
                List<WebDavFileInfo>? files =
                    await _webDavCloudService!.listBackups();
                if (files == null) {
                  CustomLoadingDialog.dismissLoading();
                  IToast.show(S.current.cloudPullFailed);
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
                          msg: S.current.cloudPulling,
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
                  IToast.show(S.current.cloudNoBackupFile);
                }
              } catch (e, t) {
                ILogger.error("CloudOTP","Failed to pull from webdav", e, t);
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
                config: _webDavCloudServiceConfig!,
                cloudService: _webDavCloudService!,
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
                  _webDavCloudService = null;
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
