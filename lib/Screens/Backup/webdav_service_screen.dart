import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/TokenUtils/export_token_util.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/BottomSheet/webdav_backups_bottom_sheet.dart';
import 'package:cloudotp/Widgets/Dialog/progress_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/webdav_cloud_service.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
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
  late final InputStateController _endpointStateController;
  late final InputStateController _secretStateController;
  late final InputStateController _accountStateController;
  CloudServiceConfig? _webDavCloudServiceConfig;
  WebDavCloudService? _webDavCloudService;

  CloudServiceConfig get currentConfig => _webDavCloudServiceConfig!;

  CloudService get currentService => _webDavCloudService!;

  bool get _configInitialized {
    return _webDavCloudServiceConfig != null;
  }

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
      if (_webDavCloudServiceConfig!.isValid) {
        _webDavCloudService = WebDavCloudService(_webDavCloudServiceConfig!);
      }
    } else {
      _webDavCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.Webdav);
      await CloudServiceConfigDao.insertConfig(_webDavCloudServiceConfig!);
    }
    setState(() {});
  }

  initFields() {
    RegExp urlRegex = RegExp(
        r"^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://)?(www.|[a-zA-Z0-9].)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,6}(\:[0-9]{1,5})*(/($|[a-zA-Z0-9\.\,\;\?\'\\\+&amp;%\$#\=~_\-@]+))*");
    _endpointController.addListener(() {
      _webDavCloudServiceConfig!.endpoint = _endpointController.text;
    });
    _accountController.addListener(() {
      _webDavCloudServiceConfig!.account = _accountController.text;
    });
    _secretController.addListener(() {
      _webDavCloudServiceConfig!.secret = _secretController.text;
    });
    _endpointStateController = InputStateController(
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavServerCannotBeEmpty);
        }
        if (!urlRegex.hasMatch(text)) {
          return Future.value(S.current.webDavServerInvalid);
        }
        return Future.value(null);
      },
    );
    _secretStateController = InputStateController(
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavPasswordCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
    _accountStateController = InputStateController(
      validate: (text) {
        if (text.isEmpty) {
          return Future.value(S.current.webDavUsernameCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
  }

  Future<bool> isValid() async {
    bool issuerValid = await _endpointStateController.isValid();
    bool secretValid = await _secretStateController.isValid();
    bool accountValid = await _accountStateController.isValid();
    return issuerValid && secretValid && accountValid;
  }

  resetState() {
    _endpointStateController.reset();
    _secretStateController.reset();
    _accountStateController.reset();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildBody();
  }

  ping({
    bool showLoading = true,
    bool showSuccessToast = true,
  }) async {
    if (showLoading) {
      CustomLoadingDialog.showLoading(title: S.current.webDavConnecting);
    }
    await currentService.authenticate().then((value) {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
      });
      if (!currentConfig.connected) {
        switch (value) {
          case CloudServiceStatus.connectionError:
            IToast.show(S.current.webDavConnectionError);
            break;
          case CloudServiceStatus.unauthorized:
            IToast.show(S.current.webDavUnauthorized);
            break;
          default:
            IToast.show(S.current.webDavUnknownError);
            break;
        }
      } else {
        if (showSuccessToast) IToast.show(S.current.webDavAuthSuccess);
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
      title: S.current.enable,
      topRadius: true,
      bottomRadius: true,
      value: _webDavCloudServiceConfig?.enabled ?? false,
      onTap: () {
        setState(() {
          _webDavCloudServiceConfig!.enabled =
              !_webDavCloudServiceConfig!.enabled;
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
            controller: _endpointController,
            textInputAction: TextInputAction.next,
            leadingText: S.current.webDavServer,
            leadingType: InputItemLeadingType.text,
            topRadius: true,
            disabled: currentConfig.connected,
            stateController: _endpointStateController,
            hint: S.current.webDavServerHint,
            // inputFormatters: [
            //   RegexInputFormatter.onlyUrl,
            // ],
          ),
          InputItem(
            controller: _accountController,
            stateController: _accountStateController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: currentConfig.connected,
            leadingText: S.current.webDavUsername,
            hint: S.current.webDavUsernameHint,
          ),
          InputItem(
            controller: _secretController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            leadingText: S.current.webDavPassword,
            tailingType: InputItemTailingType.password,
            disabled: currentConfig.connected,
            hint: S.current.webDavPasswordHint,
            inputFormatters: [
              RegexInputFormatter.onlyNumberAndLetter,
            ],
            stateController: _secretStateController,
            bottomRadius: true,
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
            text: S.current.webDavSignin,
            background: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              if (await isValid()) {
                await CloudServiceConfigDao.updateConfig(currentConfig);
                _webDavCloudService =
                    WebDavCloudService(_webDavCloudServiceConfig!);
                ping();
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
            text: S.current.webDavPullBackup,
            padding: const EdgeInsets.symmetric(vertical: 12),
            outline: Theme.of(context).primaryColor,
            color: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              CustomLoadingDialog.showLoading(
                title: S.current.webDavPulling,
                dismissible: true,
              );
              try {
                List<WebDavFile> files = await _webDavCloudService!.listFiles();
                CustomLoadingDialog.dismissLoading();
                CloudServiceConfigDao.updateLastPullTime(
                    _webDavCloudServiceConfig!);
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
                          msg: S.current.webDavPulling,
                          showProgress: true,
                        );
                        Uint8List res = await _webDavCloudService!.downloadFile(
                          selectedFile.name!,
                          onProgress: (c, t) {
                            dialog.updateProgress(progress: c / t);
                          },
                        );

                        dialog.updateMessage(
                          msg: S.current.importing,
                          showProgress: false,
                        );

                        bool success = await ImportTokenUtil.importBackupFile(
                          res,
                          showLoading: false,
                        );
                        dialog.dismiss();
                        if (!success) {
                          InputStateController stateController =
                              InputStateController(
                            validate: (value) {
                              if (value.isEmpty) {
                                return Future.value(
                                    S.current.autoBackupPasswordCannotBeEmpty);
                              }
                              return Future.value(null);
                            },
                          );
                          BottomSheetBuilder.showBottomSheet(
                            context,
                            responsive: true,
                            (context) => InputBottomSheet(
                              stateController: stateController,
                              title: S.current.inputImportPasswordTitle,
                              message: S.current.inputImportPasswordTip,
                              hint: S.current.inputImportPasswordHint,
                              inputFormatters: [
                                RegexInputFormatter.onlyNumberAndLetter,
                              ],
                              tailingType: InputItemTailingType.password,
                              preventPop: true,
                              onValidConfirm: (password) async {
                                dialog.show(
                                  msg: S.current.importing,
                                  showProgress: false,
                                );
                                bool success =
                                    await ImportTokenUtil.importBackupFile(
                                  password: password,
                                  res,
                                  showLoading: false,
                                );
                                dialog.dismiss();
                                if (success) {
                                  IToast.show(S.current.importSuccess);
                                  stateController.pop?.call();
                                } else {
                                  stateController.setError(
                                      S.current.invalidPasswordOrDataCorrupted);
                                }
                              },
                            ),
                          );
                        }
                      },
                    ),
                  );
                } else {
                  IToast.show(S.current.webDavNoBackupFile);
                }
              } catch (e) {
                CustomLoadingDialog.dismissLoading();
                IToast.show(S.current.webDavPullFailed);
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
            text: S.current.webDavPushBackup,
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
            text: S.current.webDavLogout,
            fontSizeDelta: 2,
            onTap: () async {
              setState(() {
                currentConfig.connected = false;
                _webDavCloudService = null;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
