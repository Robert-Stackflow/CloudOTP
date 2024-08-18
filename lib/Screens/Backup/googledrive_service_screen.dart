import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';
import 'package:cloudotp/TokenUtils/Cloud/cloud_service.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_googledrive/googledrive_response.dart';

import '../../Database/cloud_service_config_dao.dart';
import '../../TokenUtils/Cloud/googledrive_cloud_service.dart';
import '../../TokenUtils/export_token_util.dart';
import '../../TokenUtils/import_token_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/googledrive_backups_bottom_sheet.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/progress_dialog.dart';
import '../../Widgets/Item/input_item.dart';
import '../../generated/l10n.dart';

class GoogleDriveServiceScreen extends StatefulWidget {
  const GoogleDriveServiceScreen({
    super.key,
  });

  static const String routeName = "/service/googledrive";

  @override
  State<GoogleDriveServiceScreen> createState() =>
      _GoogleDriveServiceScreenState();
}

class _GoogleDriveServiceScreenState extends State<GoogleDriveServiceScreen>
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
  }

  loadConfig() async {
    _googledriveCloudServiceConfig =
        await CloudServiceConfigDao.getGoogleDriveConfig();
    if (_googledriveCloudServiceConfig != null) {
      _sizeController.text = _googledriveCloudServiceConfig!.size;
      _accountController.text = _googledriveCloudServiceConfig!.account ?? "";
      _emailController.text = _googledriveCloudServiceConfig!.email ?? "";
      _googledriveCloudService = GoogleDriveCloudService(
        context,
        _googledriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    } else {
      _googledriveCloudServiceConfig =
          CloudServiceConfig.init(type: CloudServiceType.GoogleDrive);
      await CloudServiceConfigDao.insertConfig(_googledriveCloudServiceConfig!);
      _googledriveCloudService = GoogleDriveCloudService(
        context,
        _googledriveCloudServiceConfig!,
        onConfigChanged: updateConfig,
      );
    }
    if (_googledriveCloudService != null) {
      _googledriveCloudServiceConfig!.configured =
          _googledriveCloudServiceConfig!.connected =
              await _googledriveCloudService!.isConnected();
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
    return ResponsiveUtil.isDesktop()
        ? _buildUnsupportBody()
        : inited
            ? _buildBody()
            : ItemBuilder.buildLoadingDialog(
                context,
                background: Colors.transparent,
                text: S.current.cloudConnecting,
              );
  }

  _buildUnsupportBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Text(S.current.cloudTypeNotSupport(S.current.cloudTypeGoogleDrive)),
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
    await currentService.authenticate().then((value) async {
      setState(() {
        currentConfig.connected = value == CloudServiceStatus.success;
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
        _googledriveCloudServiceConfig!.configured = true;
        updateConfig(_googledriveCloudServiceConfig!);
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
      title: S.current.enable + S.current.cloudTypeGoogleDrive,
      topRadius: true,
      bottomRadius: true,
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
            controller: _emailController,
            textInputAction: TextInputAction.next,
            leadingType: InputItemLeadingType.text,
            disabled: true,
            leadingText: S.current.cloudEmail,
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
            text: S.current.webDavSignin,
            background: Theme.of(context).primaryColor,
            fontSizeDelta: 2,
            onTap: () async {
              try {
                ping();
              } catch (e) {
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
                List<GoogleDriveFileInfo> files =
                    await _googledriveCloudService!.listBackups();
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
                          msg: S.current.webDavPulling,
                          showProgress: true,
                        );
                        Uint8List res =
                            await _googledriveCloudService!.downloadFile(
                          selectedFile.id,
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
                          BottomSheetBuilder.showBottomSheet(
                            context,
                            responsive: true,
                            (context) => InputBottomSheet(
                              validator: (value) {
                                if (value.isEmpty) {
                                  return S
                                      .current.autoBackupPasswordCannotBeEmpty;
                                }
                                return null;
                              },
                              validateAsyncController:
                                  InputValidateAsyncController(
                                listen: false,
                                validator: (text) async {
                                  dialog.show(
                                    msg: S.current.importing,
                                    showProgress: false,
                                  );
                                  bool success =
                                      await ImportTokenUtil.importBackupFile(
                                    password: text,
                                    res,
                                    showLoading: false,
                                  );
                                  dialog.dismiss();
                                  if (success) {
                                    return null;
                                  } else {
                                    return S
                                        .current.invalidPasswordOrDataCorrupted;
                                  }
                                },
                                controller: TextEditingController(),
                              ),
                              title: S.current.inputImportPasswordTitle,
                              message: S.current.inputImportPasswordTip,
                              hint: S.current.inputImportPasswordHint,
                              inputFormatters: [
                                RegexInputFormatter.onlyNumberAndLetter,
                              ],
                              tailingType: InputItemTailingType.password,
                              onValidConfirm: (password) async {},
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
                config: _googledriveCloudServiceConfig!,
                cloudService: _googledriveCloudService!,
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
            },
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
